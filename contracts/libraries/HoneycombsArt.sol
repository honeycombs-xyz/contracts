//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../interfaces/IHoneycombs.sol";
import "./Colors.sol";
import "./Utilities.sol";

/**
@title  HoneycombsArt
@notice Renders the Honeycombs visuals.
*/
library HoneycombsArt {

    /// @dev The path for a 72x72 px hexagon with a pointy top
    string public constant HEXAGON_POINTY_TOP_PATH = 'M72.6769 22.2472L42.5 4.82457C40.953 3.93141 39.047 3.93141 37.5 4.82457L7.32309 22.2472C5.77608 23.1404 4.82309 24.791 4.82309 26.5774V61.4226C4.82309 63.209 5.77608 64.8596 7.32309 65.7528L37.5 83.1754C39.047 84.0686 40.953 84.0686 42.5 83.1754L72.6769 65.7528C74.2239 64.8596 75.1769 63.209 75.1769 61.4226V26.5774C75.1769 24.791 74.2239 23.1404 72.6769 22.2472Z';
    string public constant HEXAGON_FLAT_TOP_PATH = 'M22.2472 7.32309L4.82457 37.5C3.93141 39.047 3.93141 40.953 4.82457 42.5L22.2472 72.6769C23.1404 74.2239 24.791 75.1769 26.5774 75.1769H61.4226C63.209 75.1769 64.8596 74.2239 65.7528 72.6769L83.1754 42.5C84.0686 40.953 84.0686 39.047 83.1754 37.5L65.7528 7.32309C64.8596 5.77608 63.209 4.82309 61.4226 4.82309H26.5774C24.791 4.82309 23.1404 5.77608 22.2472 7.32309Z';

    /// @dev The semiperfect divisors of the 80 honeycombs.
    function DIVISORS() public pure returns (uint8[8] memory) {
        return [ 80, 40, 20, 10, 5, 4, 1, 0 ];
    }

    /// @dev The different color band sizes that we use for the art.
    function COLOR_BANDS() public pure returns (uint8[7] memory) {
        return [ 80, 60, 40, 20, 10, 5, 1 ];
    }

    /// @dev The gradient increment steps.
    function GRADIENTS() public pure returns (uint8[7] memory) {
        return [ 0, 1, 2, 5, 8, 9, 10 ];
    }

    /// @dev Load a honeycomb from storage and fill its current state settings.
    /// @param tokenId The id of the honeycomb to fetch.
    /// @param honeycombs The DB containing all honeycombs.
    function getHoneycomb(
        uint256 tokenId, IHoneycombs.Honeycombs storage honeycombs
    ) public view returns (IHoneycombs.Honeycomb memory honeycomb) {
        IHoneycombs.StoredHoneycomb memory stored = honeycombs.all[tokenId];

        return getHoneycomb(tokenId, stored.divisorIndex, honeycombs);
    }

    /// @dev Load a honeycomb from storage and fill its current state settings.
    /// @param tokenId The id of the honeycomb to fetch.
    /// @param divisorIndex The divisorindex to get.
    /// @param honeycombs The DB containing all honeycombs.
    function getHoneycomb(
        uint256 tokenId, uint8 divisorIndex, IHoneycombs.Honeycombs storage honeycombs
    ) public view returns (IHoneycombs.Honeycomb memory honeycomb) {
        IHoneycombs.StoredHoneycomb memory stored = honeycombs.all[tokenId];
        stored.divisorIndex = divisorIndex; // Override in case we're fetching specific state.
        honeycomb.stored = stored;

        // Set up the source of randomness + seed for this Honeycomb.
        uint128 randomness = honeycombs.epochs[stored.epoch].randomness;
        honeycomb.seed = (uint256(keccak256(abi.encodePacked(randomness, stored.seed))) % type(uint128).max);

        // Helpers
        honeycomb.isRoot = divisorIndex == 0;
        honeycomb.isRevealed = randomness > 0;
        honeycomb.hasManyHoneycombs = divisorIndex < 6;
        honeycomb.composite = !honeycomb.isRoot && divisorIndex < 7 ? stored.composites[divisorIndex - 1] : 0;

        // Token properties
        honeycomb.colorBand = colorBandIndex(honeycomb, divisorIndex);
        honeycomb.gradient = gradientIndex(honeycomb, divisorIndex);
        honeycomb.honeycombsCount = DIVISORS()[divisorIndex];
        honeycomb.speed = uint8(2**(honeycomb.seed % 3));
        honeycomb.direction = uint8(honeycomb.seed % 2);
    }

    /// @dev Query the gradient of a given honeycomb at a certain honeycomb count.
    /// @param honeycomb The honeycomb we want to get the gradient for.
    /// @param divisorIndex The honeycomb divisor in question.
    function gradientIndex(IHoneycombs.Honeycomb memory honeycomb, uint8 divisorIndex) public pure returns (uint8) {
        uint256 n = Utilities.random(honeycomb.seed, 'gradient', 100);

        return divisorIndex == 0
            ? n < 20 ? uint8(1 + (n % 6)) : 0
            : divisorIndex < 6
                ? honeycomb.stored.gradients[divisorIndex - 1]
                : 0;
    }

    /// @dev Query the color band of a given honeycomb at a certain honeycomb count.
    /// @param honeycomb The honeycomb we want to get the color band for.
    /// @param divisorIndex The honeycomb divisor in question.
    function colorBandIndex(IHoneycombs.Honeycomb memory honeycomb, uint8 divisorIndex) public pure returns (uint8) {
        uint256 n = Utilities.random(honeycomb.seed, 'band', 120);

        return divisorIndex == 0
            ?   ( n > 80 ? 0
                : n > 40 ? 1
                : n > 20 ? 2
                : n > 10 ? 3
                : n >  4 ? 4
                : n >  1 ? 5
                : 6 )
            : divisorIndex < 6
                ? honeycomb.stored.colorBands[divisorIndex - 1]
                : 6;
    }

    /// @dev Generate indexes for the color slots of honeycomb parents (up to the EightyColors.COLORS themselves).
    /// @param divisorIndex The current divisorIndex to query.
    /// @param honeycomb The current honeycomb to investigate.
    /// @param honeycombs The DB containing all honeycombs.
    function colorIndexes(
        uint8 divisorIndex, IHoneycombs.Honeycomb memory honeycomb, IHoneycombs.Honeycombs storage honeycombs
    )
        public view returns (uint256[] memory)
    {
        uint8[8] memory divisors = DIVISORS();
        uint256 honeycombsCount = divisors[divisorIndex];
        uint256 seed = honeycomb.seed;
        uint8 colorBand = COLOR_BANDS()[colorBandIndex(honeycomb, divisorIndex)];
        uint8 gradient = GRADIENTS()[gradientIndex(honeycomb, divisorIndex)];

        // If we're a composited honeycomb, we choose colors only based on
        // the slots available in our parents. Otherwise,
        // we choose based on our available spectrum.
        uint256 possibleColorChoices = divisorIndex > 0
            ? divisors[divisorIndex - 1] * 2
            : 80;

        // We initialize our index and select the first color
        uint256[] memory indexes = new uint256[](honeycombsCount);
        indexes[0] = Utilities.random(seed, possibleColorChoices);

        // If we have more than one honeycomb, continue selecting colors
        if (honeycomb.hasManyHoneycombs) {
            if (gradient > 0) {
                // If we're a gradient honeycomb, we select based on the color band looping around
                // the 80 possible colors
                for (uint256 i = 1; i < honeycombsCount;) {
                    indexes[i] = (indexes[0] + (i * gradient * colorBand / honeycombsCount) % colorBand) % 80;
                    unchecked { ++i; }
                }
            } else if (divisorIndex == 0) {
                // If we select initial non gradient colors, we just take random ones
                // available in our color band
                for (uint256 i = 1; i < honeycombsCount;) {
                    indexes[i] = (indexes[0] + Utilities.random(seed + i, colorBand)) % 80;
                    unchecked { ++i; }
                }
            } else {
                // If we have parent honeycombs, we select our colors from their set
                for (uint256 i = 1; i < honeycombsCount;) {
                    indexes[i] = Utilities.random(seed + i, possibleColorChoices);
                    unchecked { ++i; }
                }
            }
        }

        // We resolve our color indexes through our parent tree until we reach the root honeycombs
        if (divisorIndex > 0) {
            uint8 previousDivisor = divisorIndex - 1;

            // We already have our current honeycomb, but need the our parent state color indices
            uint256[] memory parentIndexes = colorIndexes(previousDivisor, honeycomb, honeycombs);

            // We also need to fetch the colors of the honeycomb that was composited into us
            IHoneycombs.Honeycomb memory composited = getHoneycomb(honeycomb.composite, honeycombs);
            uint256[] memory compositedIndexes = colorIndexes(previousDivisor, composited, honeycombs);

            // Replace random indices with parent / root color indices
            uint8 count = divisors[previousDivisor];

            // We always select the first color from our parent
            uint256 initialBranchIndex = indexes[0] % count;
            indexes[0] = indexes[0] < count
                ? parentIndexes[initialBranchIndex]
                : compositedIndexes[initialBranchIndex];

            // If we don't have a gradient, we continue resolving from our parent for the remaining honeycombs
            if (gradient == 0) {
                for (uint256 i; i < honeycombsCount;) {
                    uint256 branchIndex = indexes[i] % count;
                    indexes[i] = indexes[i] < count
                        ? parentIndexes[branchIndex]
                        : compositedIndexes[branchIndex];

                    unchecked { ++i; }
                }
            // If we have a gradient we base the remaining colors off our initial selection
            } else {
                for (uint256 i = 1; i < honeycombsCount;) {
                    indexes[i] = (indexes[0] + (i * gradient * colorBand / honeycombsCount) % colorBand) % 80;

                    unchecked { ++i; }
                }
            }
        }

        return indexes;
    }

    /// @dev Fetch all colors of a given Honeycomb.
    /// @param honeycomb The honeycomb to get colors for.
    /// @param honeycombs The DB containing all honeycombs.
    function colors(
        IHoneycombs.Honeycomb memory honeycomb, IHoneycombs.Honeycombs storage honeycombs
    ) public view returns (string[] memory, uint256[] memory) {
        // A fully composited honeycomb has no color.
        if (honeycomb.stored.divisorIndex == 7) {
            string[] memory zeroColors = new string[](1);
            uint256[] memory zeroIndexes = new uint256[](1);
            zeroColors[0] = '000';
            zeroIndexes[0] = 999;
            return (zeroColors, zeroIndexes);
        }

        // An unrevealed honeycomb is all gray.
        if (! honeycomb.isRevealed) {
            string[] memory preRevealColors = new string[](1);
            uint256[] memory preRevealIndexes = new uint256[](1);
            preRevealColors[0] = '424242';
            preRevealIndexes[0] = 0;
            return (preRevealColors, preRevealIndexes);
        }

        // Fetch the indices on the original color mapping.
        uint256[] memory indexes = colorIndexes(honeycomb.stored.divisorIndex, honeycomb, honeycombs);

        // Map over to get the colors.
        string[] memory honeycombColors = new string[](indexes.length);
        string[80] memory allColors = EightyColors.COLORS();

        // Always set the first color.
        honeycombColors[0] = allColors[indexes[0]];

        // Resolve each additional honeycomb color via their index in EightyColors.COLORS.
        for (uint256 i = 1; i < indexes.length; i++) {
            honeycombColors[i] = allColors[indexes[i]];
        }

        return (honeycombColors, indexes);
    }

    /// @dev Get the number of honeycombs we should display per row.
    /// @param honeycombs The number of honeycombs in the piece.
    function perRow(uint8 honeycombs) public pure returns (uint8) {
        return honeycombs == 80
            ? 8
            : honeycombs >= 20
                ? 4
                : honeycombs == 10 || honeycombs == 4
                    ? 2
                    : 1;
    }

    /// @dev Get the X-offset for positioning honeycombs horizontally.
    /// @param honeycombs The number of honeycombs in the piece.
    function rowX(uint8 honeycombs) public pure returns (uint16) {
        return honeycombs <= 1
            ? 286
            : honeycombs == 5
                ? 304
                : honeycombs == 10 || honeycombs == 4
                    ? 268
                    : 196;
    }

    /// @dev Get the Y-offset for positioning honeycombs vertically.
    /// @param honeycombs The number of honeycombs in the piece.
    function rowY(uint8 honeycombs) public pure returns (uint16) {
        return honeycombs > 4
            ? 160
            : honeycombs == 4
                ? 268
                : honeycombs > 1
                    ? 304
                    : 286;
    }

    /// @dev Get the animation SVG snipped for an individual honeycomb of a piece.
    /// @param data The data object containing rendering settings.
    /// @param offset The index position of the honeycomb in question.
    /// @param allColors All available colors.
    function fillAnimation(
        HoneycombRenderData memory data,
        uint256 offset,
        string[80] memory allColors
    ) public pure returns (bytes memory)
    {
        // We only pick 20 colors from our gradient to reduce execution time.
        uint8 count = 20;

        bytes memory values;

        // Reverse loop through our color gradient.
        if (data.honeycomb.direction == 0) {
            for (uint256 i = offset + 80; i > offset;) {
                values = abi.encodePacked(values, '#', allColors[i % 80], ';');
                unchecked { i-=4; }
            }
        // Forward loop through our color gradient.
        } else {
            for (uint256 i = offset; i < offset + 80;) {
                values = abi.encodePacked(values, '#', allColors[i % 80], ';');
                unchecked { i+=4; }
            }
        }

        // Add initial color as last one for smooth animations.
        values = abi.encodePacked(values, '#', allColors[offset]);

        // Render the SVG snipped for the animation
        return abi.encodePacked(
            '<animate ',
                'attributeName="fill" values="',values,'" ',
                'dur="',Utilities.uint2str(count * 2 / data.honeycomb.speed),'s" begin="animation.begin" ',
                'repeatCount="indefinite" ',
            '/>'
        );
    }

    /// @dev Generate the SVG code for all honeycombs in a given token.
    /// @param data The data object containing rendering settings.
    function generateHoneycombs(HoneycombRenderData memory data) public pure returns (bytes memory) {
        bytes memory honeycombsBytes;
        string[80] memory allColors = EightyColors.COLORS();

        uint8 honeycombsCount = data.count;
        for (uint8 i; i < honeycombsCount; i++) {
            // Compute row settings.
            data.indexInRow = i % data.perRow;
            data.isNewRow = data.indexInRow == 0 && i > 0;

            // Compute offsets.
            if (data.isNewRow) data.rowY += data.spaceY;
            if (data.isNewRow && data.indent) {
                if (i == 0) {
                    data.rowX += data.spaceX / 2;
                }

                if (i % (data.perRow * 2) == 0) {
                    data.rowX -= data.spaceX / 2;
                } else {
                    data.rowX += data.spaceX / 2;
                }
            }
            string memory translateX = Utilities.uint2str(data.rowX + data.indexInRow * data.spaceX);
            string memory translateY = Utilities.uint2str(data.rowY);
            string memory color = data.honeycomb.isRevealed ? data.colors[i] : data.colors[0];

            // Render the current honeycomb.
            honeycombsBytes = abi.encodePacked(honeycombsBytes, abi.encodePacked(
                '<g transform="translate(', translateX, ', ', translateY, ') scale(', data.scale, ')">',
                    '<use href="#honeycomb" fill="#', color, '">',
                        (data.honeycomb.isRevealed && !data.isBlack)
                            ? fillAnimation(data, data.colorIndexes[i], allColors)
                            : bytes(''),
                    '</use>'
                '</g>'
            ));
        }

        return honeycombsBytes;
    }

    /// @dev Collect relevant rendering data for easy access across functions.
    /// @param honeycomb Our current honeycomb loaded from storage.
    /// @param honeycombs The DB containing all honeycombs.
    function collectRenderData(
        IHoneycombs.Honeycomb memory honeycomb, IHoneycombs.Honeycombs storage honeycombs
    ) public view returns (HoneycombRenderData memory data) {
        // Carry through base settings.
        data.honeycomb = honeycomb;
        data.isBlack = honeycomb.stored.divisorIndex == 7;
        data.count = data.isBlack ? 1 : DIVISORS()[honeycomb.stored.divisorIndex];

        // Compute colors and indexes.
        (string[] memory colors_, uint256[] memory colorIndexes_) = colors(honeycomb, honeycombs);
        data.gridColor = data.isBlack ? '#F2F2F2' : '#191919';
        data.canvasColor = data.isBlack ? '#FFF' : '#111';
        data.colorIndexes = colorIndexes_;
        data.colors = colors_;

        // Compute positioning data.
        data.scale = data.count > 20 ? '1' : data.count > 1 ? '2' : '3';
        data.spaceX = data.count == 80 ? 36 : 72;
        data.spaceY = data.count > 20 ? 36 : 72;
        data.perRow = perRow(data.count);
        data.indent = data.count == 40;
        data.rowX = rowX(data.count);
        data.rowY = rowY(data.count);
    }

    /// @dev Generate the SVG code for rows in the 8x10 Honeycombs grid.
    function generateGridRow() public pure returns (bytes memory) {
        bytes memory row;
        for (uint256 i; i < 8; i++) {
            row = abi.encodePacked(
                row,
                '<use href="#square" x="', Utilities.uint2str(196 + i*36), '" y="160"/>'
            );
        }
        return row;
    }

    /// @dev Generate the SVG code for the entire 8x10 Honeycombs grid.
    function generateGrid() public pure returns (bytes memory) {
        bytes memory grid;
        for (uint256 i; i < 10; i++) {
            grid = abi.encodePacked(
                grid,
                '<use href="#row" y="', Utilities.uint2str(i*36), '"/>'
            );
        }

        return abi.encodePacked('<g id="grid" x="196" y="160">', grid, '</g>');
    }

    /// @dev Generate the complete SVG code for a given Honeycomb.
    /// @param honeycomb The honeycomb to render.
    /// @param honeycombs The DB containing all honeycombs.
    function generateSVG(
        IHoneycombs.Honeycomb memory honeycomb, IHoneycombs.Honeycombs storage honeycombs
    ) public view returns (bytes memory) {
        HoneycombRenderData memory data = collectRenderData(honeycomb, honeycombs);

        return abi.encodePacked(
            '<svg ',
                'viewBox="0 0 680 680" ',
                'fill="none" xmlns="http://www.w3.org/2000/svg" ',
                'style="width:100%;background:black;"',
            '>',
                '<defs>'
                    '<path id="honeycomb" fill-rule="evenodd" d="', HEXAGON_POINTY_TOP_PATH, '"></path>',
                '<rect id="square" width="36" height="36" stroke="', data.gridColor, '                    '<path id="honeycomb" fill-rule="evenodd" d="', HEXAGON_POINTY_TOP_PATH, '"></path>',"></rect>',
                    '<g id="row">', generateGridRow(), '</g>'
                '</defs>',
                '<rect width="680" height="680" fill="black"/>',
                '<rect x="188" y="152" width="304" height="376" fill="', data.canvasColor, '"/>',
                generateGrid(),
                generateHoneycombs(data),
                '<rect width="680" height="680" fill="transparent">',
                    '<animate ',
                        'attributeName="width" ',
                        'from="680" ',
                        'to="0" ',
                        'dur="0.2s" ',
                        'begin="click" ',
                        'fill="freeze" ',
                        'id="animation"',
                    '/>',
                '</rect>',
            '</svg>'
        );
    }
}

/// @dev Bag holding all data relevant for rendering.
struct HoneycombRenderData {
    IHoneycombs.Honeycomb honeycomb;
    uint256[] colorIndexes;
    string[] colors;
    string canvasColor;
    string gridColor;
    string duration;
    string scale;
    uint32 seed;
    uint16 rowX;
    uint16 rowY;
    uint8 count;
    uint8 spaceX;
    uint8 spaceY;
    uint8 perRow;
    uint8 indexInRow;
    uint8 isIndented;
    bool isNewRow;
    bool isBlack;
    bool indent;
}
