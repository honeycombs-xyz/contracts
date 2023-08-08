//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../interfaces/IHoneycombs.sol";
import "./Colors.sol";
import "./Utilities.sol";

/**
    TODO List:
    - [] Verify base stroke width should be 8 as constant or based on hexagon size
    - [] Verify max hexagons per row and column should be 9 as constant or formulas
    - [] Comment the rendering data struct object
    - [] Move positioning into the grid functions
    - [] Unit test that randomness creates different outcomes for each block and different tokenIds
    - [] Unit test random for hexagon array of length rows actually works in getHexagonGrid()
 */

/**
@title  HoneycombsArt
@notice Renders the Honeycombs visuals.
*/
library HoneycombsArt {
    enum HEXAGON_TYPE { FLAT, POINTY } // prettier-ignore
    enum SHAPE { TRIANGLE, DIAMOND, HEXAGON, RANDOM } // prettier-ignore

    /// @dev The width and height of the canvas.
    uint16 public constant CANVAS_WIDTH = 810;
    uint16 public constant CANVAS_HEIGHT = 810;

    /// @dev The width and height of the hexagon.
    uint16 public constant HEXAGON_WIDTH = 72;
    uint16 public constant HEXAGON_HEIGHT = 72;

    /// @dev The base stroke width of the hexagon.
    uint8 public constant HEXAGON_STROKE_WIDTH = 8;

    /// @dev The maximum number of hexagons in a row and column.
    uint16 public constant MAX_HEXAGONS_PER_ROW = ((CANVAS_WIDTH - 90) / HEXAGON_WIDTH) - 1;
    uint16 public constant MAX_HEXAGONS_PER_COLUMN = ((CANVAS_WIDTH - 90) / HEXAGON_WIDTH) - 1;

    /// @dev The range of stroke widths for the hexagon.
    uint8 public constant MIN_HEXAGON_STROKE_WIDTH = 3;
    uint8 public constant MAX_HEXAGON_STROKE_WIDTH = 15;

    /// @dev The paths for a 72x72 px hexagon.
    function getHexagonPath(HEXAGON_TYPE pathType) public pure returns (string memory) {
        if (pathType == HEXAGON_TYPE.FLAT) {
            return "M22.2472 7.32309L4.82457 37.5C3.93141 39.047 3.93141 40.953 4.82457 42.5L22.2472 72.6769C23.1404 74.2239 24.791 75.1769 26.5774 75.1769H61.4226C63.209 75.1769 64.8596 74.2239 65.7528 72.6769L83.1754 42.5C84.0686 40.953 84.0686 39.047 83.1754 37.5L65.7528 7.32309C64.8596 5.77608 63.209 4.82309 61.4226 4.82309H26.5774C24.791 4.82309 23.1404 5.77608 22.2472 7.32309Z"; // prettier-ignore
        } else if (pathType == HEXAGON_TYPE.POINTY) {
            return "M72.6769 22.2472L42.5 4.82457C40.953 3.93141 39.047 3.93141 37.5 4.82457L7.32309 22.2472C5.77608 23.1404 4.82309 24.791 4.82309 26.5774V61.4226C4.82309 63.209 5.77608 64.8596 7.32309 65.7528L37.5 83.1754C39.047 84.0686 40.953 84.0686 42.5 83.1754L72.6769 65.7528C74.2239 64.8596 75.1769 63.209 75.1769 61.4226V26.5774C75.1769 24.791 74.2239 23.1404 72.6769 22.2472Z"; // prettier-ignore
        }
    }

    /// @dev The different shapes of the honeycomb.
    function getShape(uint8 index) public pure returns (string[4] memory) {
        return SHAPE(index);
    }

    /// @dev Load a honeycomb from storage and fill its current state settings.
    /// @param tokenId The id of the honeycomb to fetch.
    /// @param honeycombs The DB containing all honeycombs.
    function getHoneycomb(
        uint256 tokenId,
        IHoneycombs.Honeycombs storage honeycombs
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
        honeycomb.speed = uint8(2 ** (honeycomb.seed % 3));
        honeycomb.direction = uint8(honeycomb.seed % 2);
    }

    /// @dev Query the gradient of a given honeycomb at a certain honeycomb count.
    /// @param honeycomb The honeycomb we want to get the gradient for.
    /// @param divisorIndex The honeycomb divisor in question.
    function gradientIndex(IHoneycombs.Honeycomb memory honeycomb, uint8 divisorIndex) public pure returns (uint8) {
        uint256 n = Utilities.random(honeycomb.seed, "gradient", 100);

        return
            divisorIndex == 0 ? n < 20 ? uint8(1 + (n % 6)) : 0 : divisorIndex < 6
                ? honeycomb.stored.gradients[divisorIndex - 1]
                : 0;
    }

    /// @dev Query the color band of a given honeycomb at a certain honeycomb count.
    /// @param honeycomb The honeycomb we want to get the color band for.
    /// @param divisorIndex The honeycomb divisor in question.
    function colorBandIndex(IHoneycombs.Honeycomb memory honeycomb, uint8 divisorIndex) public pure returns (uint8) {
        uint256 n = Utilities.random(honeycomb.seed, "band", 120);

        return
            divisorIndex == 0
                ? (n > 80 ? 0 : n > 40 ? 1 : n > 20 ? 2 : n > 10 ? 3 : n > 4 ? 4 : n > 1 ? 5 : 6)
                : divisorIndex < 6
                ? honeycomb.stored.colorBands[divisorIndex - 1]
                : 6;
    }

    /// @dev Generate indexes for the color slots of honeycomb parents (up to the Colors.COLORS themselves).
    /// @param divisorIndex The current divisorIndex to query.
    /// @param honeycomb The current honeycomb to investigate.
    /// @param honeycombs The DB containing all honeycombs.
    function colorIndexes(
        uint8 divisorIndex,
        IHoneycombs.Honeycomb memory honeycomb,
        IHoneycombs.Honeycombs storage honeycombs
    ) public view returns (uint256[] memory) {
        uint8[8] memory divisors = DIVISORS();
        uint256 honeycombsCount = divisors[divisorIndex];
        uint256 seed = honeycomb.seed;
        uint8 colorBand = COLOR_BANDS()[colorBandIndex(honeycomb, divisorIndex)];
        uint8 gradient = GRADIENTS()[gradientIndex(honeycomb, divisorIndex)];

        // If we're a composited honeycomb, we choose colors only based on
        // the slots available in our parents. Otherwise,
        // we choose based on our available spectrum.
        uint256 possibleColorChoices = divisorIndex > 0 ? divisors[divisorIndex - 1] * 2 : 80;

        // We initialize our index and select the first color
        uint256[] memory indexes = new uint256[](honeycombsCount);
        indexes[0] = Utilities.random(seed, possibleColorChoices);

        // If we have more than one honeycomb, continue selecting colors
        if (honeycomb.hasManyHoneycombs) {
            if (gradient > 0) {
                // If we're a gradient honeycomb, we select based on the color band looping around
                // the 80 possible colors
                for (uint256 i = 1; i < honeycombsCount; ) {
                    indexes[i] = (indexes[0] + (((i * gradient * colorBand) / honeycombsCount) % colorBand)) % 80;
                    unchecked {
                        ++i;
                    }
                }
            } else if (divisorIndex == 0) {
                // If we select initial non gradient colors, we just take random ones
                // available in our color band
                for (uint256 i = 1; i < honeycombsCount; ) {
                    indexes[i] = (indexes[0] + Utilities.random(seed + i, colorBand)) % 80;
                    unchecked {
                        ++i;
                    }
                }
            } else {
                // If we have parent honeycombs, we select our colors from their set
                for (uint256 i = 1; i < honeycombsCount; ) {
                    indexes[i] = Utilities.random(seed + i, possibleColorChoices);
                    unchecked {
                        ++i;
                    }
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
            indexes[0] = indexes[0] < count ? parentIndexes[initialBranchIndex] : compositedIndexes[initialBranchIndex];

            // If we don't have a gradient, we continue resolving from our parent for the remaining honeycombs
            if (gradient == 0) {
                for (uint256 i; i < honeycombsCount; ) {
                    uint256 branchIndex = indexes[i] % count;
                    indexes[i] = indexes[i] < count ? parentIndexes[branchIndex] : compositedIndexes[branchIndex];

                    unchecked {
                        ++i;
                    }
                }
                // If we have a gradient we base the remaining colors off our initial selection
            } else {
                for (uint256 i = 1; i < honeycombsCount; ) {
                    indexes[i] = (indexes[0] + (((i * gradient * colorBand) / honeycombsCount) % colorBand)) % 80;

                    unchecked {
                        ++i;
                    }
                }
            }
        }

        return indexes;
    }

    /// @dev Fetch all colors of a given Honeycomb.
    /// @param honeycomb The honeycomb to get colors for.
    /// @param honeycombs The DB containing all honeycombs.
    function colors(
        IHoneycombs.Honeycomb memory honeycomb,
        IHoneycombs.Honeycombs storage honeycombs
    ) public view returns (string[] memory, uint256[] memory) {
        // A fully composited honeycomb has no color.
        if (honeycomb.stored.divisorIndex == 7) {
            string[] memory zeroColors = new string[](1);
            uint256[] memory zeroIndexes = new uint256[](1);
            zeroColors[0] = "000";
            zeroIndexes[0] = 999;
            return (zeroColors, zeroIndexes);
        }

        // An unrevealed honeycomb is all gray.
        if (!honeycomb.isRevealed) {
            string[] memory preRevealColors = new string[](1);
            uint256[] memory preRevealIndexes = new uint256[](1);
            preRevealColors[0] = "424242";
            preRevealIndexes[0] = 0;
            return (preRevealColors, preRevealIndexes);
        }

        // Fetch the indices on the original color mapping.
        uint256[] memory indexes = colorIndexes(honeycomb.stored.divisorIndex, honeycomb, honeycombs);

        // Map over to get the colors.
        string[] memory honeycombColors = new string[](indexes.length);
        string[80] memory allColors = Colors.COLORS();

        // Always set the first color.
        honeycombColors[0] = allColors[indexes[0]];

        // Resolve each additional honeycomb color via their index in Colors.COLORS.
        for (uint256 i = 1; i < indexes.length; i++) {
            honeycombColors[i] = allColors[indexes[i]];
        }

        return (honeycombColors, indexes);
    }

    /// @dev Get the animation SVG snipped for an individual honeycomb of a piece.
    /// @param data The data object containing rendering settings.
    /// @param offset The index position of the honeycomb in question.
    /// @param allColors All available colors.
    function fillAnimation(
        HoneycombRenderData memory data,
        uint256 offset,
        string[80] memory allColors
    ) public pure returns (bytes memory) {
        // We only pick 20 colors from our gradient to reduce execution time.
        uint8 count = 20;

        bytes memory values;

        // Reverse loop through our color gradient.
        if (data.honeycomb.direction == 0) {
            for (uint256 i = offset + 80; i > offset; ) {
                values = abi.encodePacked(values, "#", allColors[i % 80], ";");
                unchecked {
                    i -= 4;
                }
            }
            // Forward loop through our color gradient.
        } else {
            for (uint256 i = offset; i < offset + 80; ) {
                values = abi.encodePacked(values, "#", allColors[i % 80], ";");
                unchecked {
                    i += 4;
                }
            }
        }

        // Add initial color as last one for smooth animations.
        values = abi.encodePacked(values, "#", allColors[offset]);

        // Render the SVG snipped for the animation
        // prettier-ignore
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
        string[80] memory allColors = Colors.COLORS();

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
            // prettier-ignore
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

    /// @dev Add positioning to the honeycombs (center of canvas).
    /// @param data The data object containing rendering settings.
    function addPositioning(
        HoneycombRenderData memory data,
        HoneycombGrid memory honeycombGrid
    ) public pure returns (HoneycombGrid memory) {
        // Compute grid properties.
        uint16 rowDistance = HEXAGON_WIDTH - (0.25 * HEXAGON_WIDTH - 0.75 * HEXAGON_STROKE_WIDTH);
        uint16 columnDistance = HEXAGON_WIDTH / 2;
        uint16 gridWidth = honeycombGrid.maxRowCount * HEXAGON_WIDTH + HEXAGON_STROKE_WIDTH;
        uint16 gridHeight = honeycombGrid.rows * HEXAGON_HEIGHT + HEXAGON_STROKE_WIDTH;

        // Swap variables if it is a flat top hexagon.
        if (data.baseHexagonType == HEXAGON_TYPE.FLAT) {
            (rowDistance, columnDistance) = Utilities.swap(rowDistance, columnDistance);
            (gridWidth, gridHeight) = Utilities.swap(gridWidth, gridHeight);
        }

        // Compute grid positioning.
        uint16 gridX = (CANVAS_WIDTH - gridWidth) / 2 - (HEXAGON_STROKE_WIDTH / 2);
        uint16 gridY = (CANVAS_HEIGHT - gridHeight) / 2;

        // Add positioning to each hexagon.
        for (uint256 i; i < honeycombGrid.hexagons.length; i++) {
            honeycombGrid.hexagons[i].x = gridX + honeycombGrid.hexagons[i].xIndex * columnDistance;
            honeycombGrid.hexagons[i].y = gridY + honeycombGrid.hexagons[i].yIndex * rowDistance;
        }

        return honeycombGrid;
    }

    /// @dev Get the honeycomb grid for a random shape.
    /// @param data The data object containing rendering settings.
    function getRandomGrid(HoneycombRenderData memory data) public pure returns (HoneycombGrid memory) {
        HoneycombGrid memory honeycombGrid;

        // Get random rows from 1 to MAX_HEXAGONS_PER_ROW.
        honeycombGrid.rows = Utilities.random(data.honeycomb.seed, "rows", MAX_HEXAGONS_PER_ROW) + 1;
        honeycombGrid.totalGradients = honeycombGrid.rows;

        // Get random hexagons in each row from 1 to MAX_HEXAGONS_PER_ROW - 1.
        uint8[] memory hexagonsInRow = new uint8[](honeycombGrid.rows);
        for (uint8 i; i < honeycombGrid.rows; i++) {
            hexagonsInRow[i] =
                Utilities.random(
                    data.honeycomb.seed,
                    abi.encodePacked("hexagonsInRow", Utilities.uint2str(i)),
                    MAX_HEXAGONS_PER_ROW - 1
                ) + 1; // prettier-ignore
            honeycombGrid.maxRowCount = Utilities.max(hexagonsInRow[i], honeycombGrid.maxRowCount);
        }

        int8 lastRowEvenOdd = -1; // Helps avoid overlapping hexagons: -1 = unset, 0 = even, 1 = odd
        // Create random grid. Only working with pointy tops for simplicity.
        for (uint8 i; i < honeycombGrid.rows; i++) {
            uint8 firstX = honeycombGrid.maxRowCount - hexagonsInRow[i];

            // Increment firstX if last row's evenness/oddness is same as this rows and update with current.
            if (lastRowEvenOdd == firstX % 2) firstX++;
            lastRowEvenOdd = firstX % 2;

            // Assign indexes for each hexagon.
            for (uint8 j; j < hexagonsInRow[i]; j++) {
                honeycombGrid.hexagons.push(Hexagon({xIndex: firstX + (j * 2), yIndex: i, gradientId: i + 1}));
            }
        }

        return honeycombGrid;
    }

    /// @dev Get the honeycomb grid for a hexagon shape.
    /// @param data The data object containing rendering settings.
    function getHexagonGrid(HoneycombRenderData memory data) public pure returns (HoneycombGrid memory) {
        HoneycombGrid memory honeycombGrid;

        // Get random rows from 3 to MAX_HEXAGONS_PER_ROW, only odd.
        honeycombGrid.rows = Utilities.random(data.honeycomb.seed, "rows", (MAX_HEXAGONS_PER_ROW / 2) - 1) * 2 + 3;
        uint8 flatTopRows = honeycombGrid.rows * 2 - 1;
        honeycombGrid.maxRowCount = honeycombGrid.rows;
        honeycombGrid.totalGradients = data.baseHexagonType == HEXAGON_TYPE.POINTY ? honeycombGrid.rows : flatTopRows;

        // Create grid based on hexagon base type.
        if (data.baseHexagonType == HEXAGON_TYPE.POINTY) {
            for (uint8 i; i < honeycombGrid.rows; i++) {
                // Compute hexagons in row.
                uint8 hexagonsInRow = honeycombGrid.rows - Utilities.absDiff(honeycombGrid.rows / 2, i);

                // Assign indexes for each hexagon.
                for (uint8 j; j < hexagonsInRow; j++) {
                    honeycombGrid.hexagons.push(
                        Hexagon({xIndex: (honeycombGrid.rows - hexagonsInRow) + (j * 2), yIndex: i, gradientId: i + 1})
                    );
                }
            }
        } else if (data.baseHexagonType == HEXAGON_TYPE.FLAT) {
            for (uint8 i; i < flatTopRows; i++) {
                // Determine hexagons in row.
                uint8 hexagonsInRow;
                if (i < honeycombGrid.rows / 2) {
                    // ascending, i.e. rows = 1 2 3 4 5 when rows = 5
                    hexagonsInRow = i / 2 + 1;
                } else if (i < flatTopRows - honeycombGrid.rows / 2 - 1) {
                    // alternate between rows / 2 + 1 and rows / 2 every other row
                    hexagonsInRow = (honeycombGrid.rows / 2 + i) % 2 == 0
                        ? honeycombGrid.rows / 2 + 1
                        : honeycombGrid.rows / 2;
                } else {
                    // descending, i.e. rows = 5, 4, 3, 2, 1 when rows = 5
                    hexagonsInRow = flatTopRows - i;
                }

                // Assign indexes for each hexagon.
                for (uint8 j; j < hexagonsInRow; j++) {
                    honeycombGrid.hexagons.push(
                        Hexagon({
                            xIndex: (honeycombGrid.rows - hexagonsInRow) - honeycombGrid.rows / 2 + (j * 2),
                            yIndex: i,
                            gradientId: i + 1
                        })
                    );
                }
            }
        }

        return honeycombGrid;
    }

    /// @dev Get the honeycomb grid for a diamond shape.
    /// @param data The data object containing rendering settings.
    function getDiamondGrid(HoneycombRenderData memory data) public pure returns (HoneycombGrid memory) {
        HoneycombGrid memory honeycombGrid;

        // Get random rows from 3 to MAX_HEXAGONS_PER_ROW, only odd.
        honeycombGrid.rows = Utilities.random(data.honeycomb.seed, "rows", (MAX_HEXAGONS_PER_ROW / 2) - 1) * 2 + 3;
        honeycombGrid.maxRowCount = honeycombGrid.rows / 2 + 1;
        honeycombGrid.totalGradients = honeycombGrid.rows;

        // Create diamond grid. Both flat top and pointy top result in the same grid, so no need to check hexagon type.
        for (uint8 i; i < honeycombGrid.rows; i++) {
            // Determine hexagons in row. Pattern is ascending/descending sequence, i.e 1 2 3 2 1 when rows = 5.
            uint8 hexagonsInRow = i < honeycombGrid.rows / 2 ? i + 1 : honeycombGrid.rows - i;
            uint8 firstXInRow = i < honeycombGrid.rows / 2 ? honeycombGrid.rows / 2 - i : i - honeycombGrid.rows / 2;

            // Assign indexes for each hexagon.
            for (uint8 j; j < hexagonsInRow; j++) {
                honeycombGrid.hexagons.push(Hexagon({xIndex: firstXInRow + (j * 2), yIndex: i, gradientId: i + 1}));
            }
        }

        return honeycombGrid;
    }

    /// @dev Get the honeycomb grid for a triangle shape.
    /// @param data The data object containing rendering settings.
    function getTriangleGrid(HoneycombRenderData memory data) public pure returns (HoneycombGrid memory) {
        HoneycombGrid memory honeycombGrid;

        // Get random rows from 2 to MAX_HEXAGONS_PER_ROW.
        honeycombGrid.rows = Utilities.random(data.honeycomb.seed, "rows", MAX_HEXAGONS_PER_ROW - 1) + 2;
        uint8 flatTopRows = honeycombGrid.rows * 2 - 1;
        honeycombGrid.maxRowCount = honeycombGrid.rows;
        honeycombGrid.totalGradients = data.baseHexagonType == HEXAGON_TYPE.POINTY ? honeycombGrid.rows : flatTopRows;

        // Create grid based on hexagon base type.
        if (data.baseHexagonType == HEXAGON_TYPE.POINTY) {
            // Iterate through rows - will only be north/south facing (design).
            for (uint8 i; i < honeycombGrid.rows; i++) {
                // Assign indexes for each hexagon. Each row has i + 1 hexagons.
                for (uint8 j; j < i + 1; j++) {
                    honeycombGrid.hexagons.push(
                        Hexagon({xIndex: honeycombGrid.rows - 1 - i + (j * 2), yIndex: i, gradientId: i + 1})
                    );
                }
            }
        } else if (data.baseHexagonType == HEXAGON_TYPE.FLAT) {
            // Iterate through rows - will only be west/east facing (design).
            for (uint8 i; i < flatTopRows; i++) {
                // Determine hexagons in row. First half is ascending. Second half is descending.
                uint8 hexagonsInRow;
                if (i < flatTopRows / 2) {
                    // ascending with peak, i.e. rows = 1 1 2 2 3 when rows = 5
                    hexagonsInRow = i / 2 + 1;
                } else {
                    // descending with peak, i.e. rows = 2 2 1 1 when rows = 5
                    hexagonsInRow = (flatTopRows - i) / 2 + 1;
                }

                // Assign indexes for each hexagon. Each row has i + 1 hexagons.
                for (uint8 j; j < i + 1; j++) {
                    honeycombGrid.hexagons.push(Hexagon({xIndex: (i % 2) + (j * 2), yIndex: i, gradientId: i + 1}));
                }
            }
        }

        return honeycombGrid;
    }

    /// @dev Create the honeycomb grid.
    /// @dev Using double coordinates: https://www.redblobgames.com/grids/hexagons/#coordinates-doubled
    /// @param data The data object containing rendering settings.
    function getHoneycombGrid(HoneycombRenderData memory data) public pure returns (HoneycombGrid memory) {
        HoneycombGrid memory honeycombGrid;

        // Get grid based on shape.
        if (data.shape == SHAPE.TRIANGLE) {
            honeycombGrid = getTriangleGrid(data);
        } else if (data.shape == SHAPE.DIAMOND) {
            honeycombGrid = getDiamondGrid(data);
        } else if (data.shape == SHAPE.HEXAGON) {
            honeycombGrid = getHexagonGrid(data);
        } else if (data.shape == SHAPE.RANDOM) {
            honeycombGrid = getRandomGrid(data);
        }

        // Add positioning data for hexagon.
        honeycombGrid = addPositioning(data, honeycombGrid);

        return honeycombGrid;
    }

    /// @dev Generate the SVG code for the overall honeycomb grid.
    /// @param data The data object containing rendering settings.
    function generateHoneycomb(HoneycombRenderData memory data) public pure returns (bytes memory) {
        bytes memory honeycombSvg;

        // Create the honeycomb grid.
        HoneycombGrid memory honeycombGrid = getHoneycombGrid(data);

        // Formulate SVG string for hexagons in the grid.
        bytes memory hexagonsSvg;
        for (uint8 i; i < honeycombGrid.count; i++) {
            // prettier-ignore
            hexagonsSvg = abi.encodePacked(hexagonsSvg, abi.encodePacked(
                '<use href="#hexagon" stroke="url(#gradient', Utilities.uint2str(honeycombGrid[i].gradient), ')" ',
                    'x="', Utilities.uint2str(honeycombGrid[i].x), '" y="', Utilities.uint2str(honeycombGrid[i].y), '"',
                '/>'
            ));
        }

        // Render the current honeycomb.
        // prettier-ignore
        honeycombSvg = abi.encodePacked(
            '<g transform="scale(1) rotate(', 
                    Utilities.uint2str(data.rotation) ,',', 
                    Utilities.uint2str(CANVAS_WIDTH/2) ,',', 
                    Utilities.uint2str(CANVAS_HEIGHT/2), '">',
                hexagonsSvg,
            '</g>'
        );

        return honeycombSvg;
    }

    /// @dev Collect relevant rendering data for easy access across functions.
    /// @param honeycomb Our current honeycomb loaded from storage.
    /// @param honeycombs The DB containing all honeycombs.
    function collectRenderData(
        IHoneycombs.Honeycomb memory honeycomb,
        IHoneycombs.Honeycombs storage honeycombs
    ) public view returns (HoneycombRenderData memory data) {
        // Carry through base settings.
        data.honeycomb = honeycomb;

        // Get the canvas color.
        data.canvasColor = Utilities.random(honeycomb.seed, "canvasColor", 2) == 0 ? "white" : "black";

        // Get the base hexagon properties.
        uint8 baseHexagonType = Utilities.random(honeycomb.seed, "hexagonType", 2);
        data.baseHexagonType = baseHexagonType == 0 ? HEXAGON_TYPE.FLAT : HEXAGON_TYPE.POINTY;
        data.baseHexagonPath = getHexagonPath(data.baseHexagonType);
        data.baseHexagonStrokeWidth =
            Utilities.random(honeycomb.seed, "strokeWidth", MAX_HEXAGON_STROKE_WIDTH) +
            MIN_HEXAGON_STROKE_WIDTH;
        data.baseHexagonFillColor = Utilities.random(honeycomb.seed, "hexagonFillColor", 2) == 0 ? "white" : "black";

        // Get the honeycomb properties.
        data.shape = getShape([Utilities.random(honeycomb.seed, "gridShape", 4)]);
        data.rotation = data.shape == SHAPE.TRIANGLE // triangles are exceptions as artist design choices
            ? Utilities.random(honeycomb.seed, "rotation", 4) * 90
            : Utilities.random(honeycomb.seed, "rotation", 12) * 30;

        // Get the gradient properties.
    }

    /// @dev Generate the complete SVG code for a given Honeycomb.
    /// @param honeycomb The honeycomb to render.
    /// @param honeycombs The DB containing all honeycombs.
    function generateSVG(
        IHoneycombs.Honeycomb memory honeycomb,
        IHoneycombs.Honeycombs storage honeycombs
    ) public view returns (bytes memory) {
        HoneycombRenderData memory data = collectRenderData(honeycomb, honeycombs);
        string canvasWidth = Utilities.uint2str(CANVAS_WIDTH);
        string canvasHeight = Utilities.uint2str(CANVAS_HEIGHT);

        // prettier-ignore
        return abi.encodePacked(
            '<svg viewBox="0 0 ', canvasWidth, ' ', canvasHeight, '"fill="none" xmlns="http://www.w3.org/2000/svg" style="width:100%;background:', data.canvasColor, ';">',
                '<defs>',
                    '<path id="hexagon" fill="', data.baseHexagonFillColor  ,'" stroke-width="', Utilities.uint2str(data.baseHexagonStrokeWidth) ,'" d="', data.baseHexagonPath ,'" />',
                    data.gradientsData.gradients,
                '</defs>',
                '<rect width="', canvasWidth, '" height="', canvasHeight, '" fill="', data.canvasColor, '"/>',
                generateHoneycombs(data),
                '<rect width="', canvasWidth, '" height="', canvasHeight, '" fill="transparent">',
                    '<animate attributeName="width" from="', canvasWidth, '" to="0" dur="0.2s" fill="freeze" ',
                        'begin="click" id="animation"/>',
                '</rect>',
            '</svg>'
        );
    }
}

/// @dev Bag holding all data relevant for rendering.
struct HoneycombRenderData {
    IHoneycombs.Honeycomb honeycomb;
    string canvasColor;
    HEXAGON_TYPE baseHexagonType;
    string baseHexagonPath;
    uint8 baseHexagonStrokeWidth;
    string baseHexagonFillColor;
    uint8 shape;
    uint16 rotation;
    uint256[] colorIndexes;
    string[] colors;
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

/// @dev All data relevant for the grid.
struct HoneycombGrid {
    uint8 rows; // number of rows in the grid
    uint8 maxRowCount; // largest row size in the grid for centering purposes
    uint8 totalGradients; // total number of gradients for gradient generation
    Hexagon[] hexagons; // all hexagons
}

/// @dev All data relevant for a single hexagon.
struct Hexagon {
    uint8 x; // x coordinate, in SVG user units (pixels)
    uint8 y; // y coordinate, in SVG user units (pixels)
    uint8 xIndex; // x index in the grid, using doubled coordinates
    uint8 yIndex; // y index in the grid, using doubled coordinates
    uint8 gradientId; // gradient id for the hexagon
}
