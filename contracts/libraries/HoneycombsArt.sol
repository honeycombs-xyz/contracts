//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../interfaces/IHoneycombs.sol";
import "./Colors.sol";
import "./Utilities.sol";

import "hardhat/console.sol";

/**
    TODO
    - [] Unit test that randomness creates different outcomes for each block and different tokenIds
    - [] Unit test random for hexagon array of length rows actually works in getHexagonGrid() + individual salt index
    - [] Add art for isRevealed = false
 */

/**
@title  HoneycombsArt
@notice Renders the Honeycombs visuals.
*/
library HoneycombsArt {
    enum HEXAGON_TYPE { FLAT, POINTY } // prettier-ignore
    enum SHAPE { TRIANGLE, DIAMOND, HEXAGON, RANDOM } // prettier-ignore

    /// @dev The paths for a 72x72 px hexagon.
    function getHexagonPath(uint8 pathType) public pure returns (string memory path) {
        if (pathType == uint8(HEXAGON_TYPE.FLAT)) {
            return "M22.2472 7.32309L4.82457 37.5C3.93141 39.047 3.93141 40.953 4.82457 42.5L22.2472 72.6769C23.1404 74.2239 24.791 75.1769 26.5774 75.1769H61.4226C63.209 75.1769 64.8596 74.2239 65.7528 72.6769L83.1754 42.5C84.0686 40.953 84.0686 39.047 83.1754 37.5L65.7528 7.32309C64.8596 5.77608 63.209 4.82309 61.4226 4.82309H26.5774C24.791 4.82309 23.1404 5.77608 22.2472 7.32309Z"; // prettier-ignore
        } else if (pathType == uint8(HEXAGON_TYPE.POINTY)) {
            return "M72.6769 22.2472L42.5 4.82457C40.953 3.93141 39.047 3.93141 37.5 4.82457L7.32309 22.2472C5.77608 23.1404 4.82309 24.791 4.82309 26.5774V61.4226C4.82309 63.209 5.77608 64.8596 7.32309 65.7528L37.5 83.1754C39.047 84.0686 40.953 84.0686 42.5 83.1754L72.6769 65.7528C74.2239 64.8596 75.1769 63.209 75.1769 61.4226V26.5774C75.1769 24.791 74.2239 23.1404 72.6769 22.2472Z"; // prettier-ignore
        }
    }

    /// @dev Get from different chromes or max primary colors. Corresponds to chrome trait in HoneycombsMetadata.sol.
    function getChrome(uint8 index) public pure returns (uint8) {
        return uint8([1, 2, 3, 4, 5, 6, Colors.COLORS().length][index]);
    }

    /// @dev Get from different animation durations in seconds. Corresponds to duration trait in HoneycombsMetadata.sol.
    function getDuration(uint16 index) public pure returns (uint16) {
        return uint16([10, 40, 80, 240][index]);
    }

    /// @dev Get the linear gradient's svg.
    /// @param data The gradient data.
    function getLinearGradientSvg(GradientData memory data) public pure returns (bytes memory) {
        // prettier-ignore
        bytes memory svg = abi.encodePacked(
            '<linearGradient id="gradient', Utilities.uint2str(data.gradientId), '" x1="0%" x2="0%" y1="', 
                    Utilities.uint2str(data.y1), '%" y2="', Utilities.uint2str(data.y2), '%">',
                '<stop stop-color="', data.stop1.color, '">',
                    '<animate attributeName="stop-color" values="', data.stop1.animationColorValues, '" dur="', 
                        Utilities.uint2str(data.duration), 's" begin="animation.begin" repeatCount="indefinite" />',
                '</stop>',
                '<stop offset="0.', Utilities.uint2str(data.offset), '" stop-color="', data.stop2.color, '">',
                    '<animate attributeName="stop-color" values="', data.stop2.animationColorValues, '" dur="', 
                        Utilities.uint2str(data.duration), 's" begin="animation.begin" repeatCount="indefinite" />',
                '</stop>',
            '</linearGradient>'
        );

        return svg;
    }

    /// @dev Get the stop for a linear gradient.
    /// @param honeycomb The honeycomb data used for rendering.
    /// @param stopCount The current stop count - used for seeding the random number generator.
    function getLinearGradientStopSvg(
        IHoneycombs.Honeycomb memory honeycomb,
        uint8 stopCount
    ) public pure returns (GradientStop memory) {
        GradientStop memory stop;
        string[46] memory allColors = Colors.COLORS();

        // Get random stop color.
        uint256 currentIndex = Utilities.random(
            honeycomb.seed,
            abi.encodePacked("linearGradientStop", Utilities.uint2str(stopCount)),
            allColors.length
        );
        stop.color = abi.encodePacked("#", allColors[currentIndex]);
        // console.log("getLinearGradientStopSvg(): initialIndex", currentIndex);

        bytes memory values;
        // Add the initial color.
        values = abi.encodePacked(values, stop.color, ";");

        // Get all animation values based on the direction.
        bool forwardDirection = honeycomb.gradients.direction == 0;

        // We pick 14 more different colors for the gradient.
        uint8 count = 14;
        for (uint256 i = 0; i <= (count * 2) - 2; ) {
            bool isFirstHalf = i < count;

            // For the first half, follow the direction. For the second half, reverse the direction.
            if (isFirstHalf == forwardDirection) {
                currentIndex = (currentIndex + 2) % allColors.length;
            } else {
                currentIndex = (currentIndex + allColors.length - 2) % allColors.length;
            }

            // console.log("getLinearGradientStopSvg(): i", i);
            // console.log("getLinearGradientStopSvg(): colorIndex", currentIndex);

            values = abi.encodePacked(values, "#", allColors[currentIndex], ";");

            unchecked {
                ++i;
            }
        }

        // console.log("About to exit getLinearGradientStopSvg()");

        // Add the last color.
        stop.animationColorValues = abi.encodePacked(values, stop.color);
        return stop;
    }

    /// @dev Get all gradients data, particularly the svg.
    /// @param honeycomb The honeycomb data used for rendering.
    function generateGradientsSvg(IHoneycombs.Honeycomb memory honeycomb) public pure returns (bytes memory) {
        bytes memory svg;

        // Initialize array of stops (id => svgString) for reuse once we reach the max color count.
        GradientStop[] memory stops = new GradientStop[](honeycomb.grid.totalGradients + 1);
        // console.log("Stops MAX LENGTH length is: ", stops.length);

        uint8 stopCount;
        GradientStop memory prevStop = getLinearGradientStopSvg(honeycomb, stopCount);
        stops[stopCount] = prevStop;
        ++stopCount;

        // Loop through all gradients and generate the svg.
        for (uint256 i; i < honeycomb.grid.totalGradients; ) {
            GradientStop memory stop;

            // console.log("Stops length is: ", stopCount);

            // Get next stop.
            if (stopCount < honeycomb.gradients.chrome) {
                // console.log("We are generating a new stop.");
                stop = getLinearGradientStopSvg(honeycomb, stopCount);
                stops[stopCount] = stop;
                unchecked {
                    ++stopCount;
                }
            } else {
                // console.log("We are reusing a stop.");
                // Randomly select a stop from existing ones.
                stop = stops[
                    Utilities.random(honeycomb.seed, abi.encodePacked("stop", Utilities.uint2str(i)), stopCount)
                ];
                // console.log("Stop is: ", string(stop.color));
            }

            // // Print out all stop colors.
            // for (uint256 j; j < 33; ) {
            //     uint256 index = Utilities.random(
            //         honeycomb.seed,
            //         abi.encodePacked("stop", Utilities.uint2str(j)),
            //         stopCount
            //     );
            //     console.log("Stop color is: ", string(stops[index].color));
            //     unchecked {
            //         ++j;
            //     }
            // }

            // console.log("About to get gradient svg.");

            // Get gradients svg based on the base hexagon type.
            if (honeycomb.baseHexagon.hexagonType == uint8(HEXAGON_TYPE.POINTY)) {
                GradientData memory gradientData;
                gradientData.stop1 = prevStop;
                gradientData.stop2 = stop;
                gradientData.duration = honeycomb.gradients.duration;
                gradientData.gradientId = uint8(i + 1);
                gradientData.y1 = 25;
                gradientData.y2 = 81;
                gradientData.offset = 72;
                bytes memory gradientSvg = getLinearGradientSvg(gradientData);

                // Append gradient to svg, update previous stop, and increment index.
                svg = abi.encodePacked(svg, gradientSvg);
                prevStop = stop;
                unchecked {
                    ++i;
                }
            } else if (honeycomb.baseHexagon.hexagonType == uint8(HEXAGON_TYPE.FLAT)) {
                // Flat tops require two gradients.
                GradientData memory gradientData1;
                gradientData1.stop1 = prevStop;
                gradientData1.stop2 = stop;
                gradientData1.duration = honeycomb.gradients.duration;
                gradientData1.gradientId = uint8(i + 1);
                gradientData1.y1 = 50;
                gradientData1.y2 = 100;
                gradientData1.offset = 72;
                bytes memory gradient1Svg = getLinearGradientSvg(gradientData1);

                if (i == honeycomb.grid.totalGradients - 1) {
                    // If this is the last gradient, we don't need to generate the second gradient.
                    svg = abi.encodePacked(svg, gradient1Svg);
                    break;
                }

                GradientData memory gradientData2;
                gradientData2.stop1 = prevStop;
                gradientData2.stop2 = stop;
                gradientData2.duration = honeycomb.gradients.duration;
                gradientData2.gradientId = uint8(i + 2);
                gradientData2.y1 = 4;
                gradientData2.y2 = 100;
                gradientData2.offset = 30;
                bytes memory gradient2Svg = getLinearGradientSvg(gradientData2);

                // Append both gradients to svg, update previous stop, and increment index.
                svg = abi.encodePacked(svg, gradient1Svg, gradient2Svg);
                prevStop = stop;
                unchecked {
                    i += 2;
                }
            }
        }

        return svg;
    }

    /// @dev Get hexagon from given grid and hexagon properties.
    /// @param grid The grid metadata.
    /// @param xIndex The x index in the grid.
    /// @param yIndex The y index in the grid.
    /// @param gradientId The gradient id for the hexagon.
    function getUpdatedHexagonsSvg(
        IHoneycombs.Grid memory grid,
        uint16 xIndex,
        uint16 yIndex,
        uint16 gradientId
    ) public pure returns (bytes memory) {
        uint16 x = grid.gridX + xIndex * grid.columnDistance;
        uint16 y = grid.gridY + yIndex * grid.rowDistance;

        // prettier-ignore
        return abi.encodePacked(grid.hexagonsSvg, abi.encodePacked(
            '<use href="#hexagon" stroke="url(#gradient', Utilities.uint2str(gradientId), ')" ',
                'x="', Utilities.uint2str(x), '" y="', Utilities.uint2str(y), '"',
            '/>'
        ));
    }

    /// @dev Add positioning to the grid (for centering on canvas).
    /// @dev Note this function appends attributes to grid object, so returned object has original grid + positioning.
    /// @param honeycomb The honeycomb data used for rendering.
    /// @param grid The grid metadata.
    function addGridPositioning(
        IHoneycombs.Honeycomb memory honeycomb,
        IHoneycombs.Grid memory grid
    ) public pure returns (IHoneycombs.Grid memory) {
        // Compute grid properties.
        grid.rowDistance =
            honeycomb.canvas.hexagonSize -
            ((honeycomb.canvas.hexagonSize / 4) - ((3 * honeycomb.baseHexagon.strokeWidth) / 4));
        grid.columnDistance = honeycomb.canvas.hexagonSize / 2;
        uint16 gridWidth = grid.longestRowCount * honeycomb.canvas.hexagonSize + honeycomb.baseHexagon.strokeWidth;
        uint16 gridHeight = grid.rows * honeycomb.canvas.hexagonSize + honeycomb.baseHexagon.strokeWidth;

        /**
         * Swap variables if it is a flat top hexagon (this math assumes pointy top as default). Rotating a flat top
         * hexagon 90 degrees clockwise results in a pointy top hexagon. This effectively swaps the x and y axis.
         */
        if (honeycomb.baseHexagon.hexagonType == uint8(HEXAGON_TYPE.FLAT)) {
            (grid.rowDistance, grid.columnDistance) = Utilities.swap(grid.rowDistance, grid.columnDistance);
            (gridWidth, gridHeight) = Utilities.swap(gridWidth, gridHeight);
        }

        // Compute grid positioning.
        grid.gridX = (810 - gridWidth) / 2 - (honeycomb.baseHexagon.strokeWidth / 2);
        grid.gridY = (810 - gridHeight) / 2;

        return grid;
    }

    /// @dev Get the honeycomb grid for a random shape.
    /// @dev Note: can only be called for pointy tops (flat tops are not supported as they would be redundant).
    /// @param honeycomb The honeycomb data used for rendering.
    function getRandomGrid(IHoneycombs.Honeycomb memory honeycomb) public pure returns (IHoneycombs.Grid memory) {
        IHoneycombs.Grid memory grid;

        // Get random rows from 1 to honeycomb.canvas.maxHexagonsPerline.
        grid.rows = uint8(Utilities.random(honeycomb.seed, "rows", honeycomb.canvas.maxHexagonsPerLine) + 1);

        // Get random hexagons in each row from 1 to honeycomb.canvas.maxHexagonsPerLine - 1.
        uint8[] memory hexagonsInRow = new uint8[](grid.rows);
        for (uint8 i; i < grid.rows; ) {
            hexagonsInRow[i] =
                uint8(Utilities.random(
                    honeycomb.seed,
                    abi.encodePacked("hexagonsInRow", Utilities.uint2str(i)),
                    honeycomb.canvas.maxHexagonsPerLine - 1
                ) + 1); // prettier-ignore
            grid.longestRowCount = Utilities.max(hexagonsInRow[i], grid.longestRowCount);

            unchecked {
                ++i;
            }
        }

        // Determine positioning of entire grid, which is based on the longest row.
        grid = addGridPositioning(honeycomb, grid); // appends to grid object

        int8 lastRowEvenOdd = -1; // Helps avoid overlapping hexagons: -1 = unset, 0 = even, 1 = odd
        // Create random grid. Only working with pointy tops for simplicity.
        for (uint8 i; i < grid.rows; ) {
            uint8 firstX = grid.longestRowCount - hexagonsInRow[i];

            // Increment firstX if last row's evenness/oddness is same as this rows and update with current.
            if (lastRowEvenOdd == int8(firstX % 2)) ++firstX;
            lastRowEvenOdd = int8(firstX % 2);

            // Assign indexes for each hexagon.
            for (uint8 j; j < hexagonsInRow[i]; ) {
                uint8 xIndex = firstX + (j * 2);
                grid.hexagonsSvg = getUpdatedHexagonsSvg(grid, xIndex, i, i + 1);
                unchecked {
                    ++j;
                }
            }

            unchecked {
                ++i;
            }
        }

        grid.totalGradients = grid.rows;
        return grid;
    }

    /// @dev Get the honeycomb grid for a hexagon shape.
    /// @param honeycomb The honeycomb data used for rendering.
    function getHexagonGrid(IHoneycombs.Honeycomb memory honeycomb) public pure returns (IHoneycombs.Grid memory) {
        IHoneycombs.Grid memory grid;

        // Get random rows from 3 to honeycomb.canvas.maxHexagonsPerLine, only odd.
        grid.rows = uint8(
            Utilities.random(honeycomb.seed, "rows", (honeycomb.canvas.maxHexagonsPerLine / 2) - 1) * 2 + 3
        );

        // Determine positioning of entire grid, which is based on the longest row.
        grid.longestRowCount = grid.rows;
        grid = addGridPositioning(honeycomb, grid); // appends to grid object

        // Create grid based on hexagon base type.
        if (honeycomb.baseHexagon.hexagonType == uint8(HEXAGON_TYPE.POINTY)) {
            grid.totalGradients = grid.rows;

            for (uint8 i; i < grid.rows; ) {
                // Compute hexagons in row.
                uint8 hexagonsInRow = grid.rows - Utilities.absDiff(grid.rows / 2, i);

                // Assign indexes for each hexagon.
                for (uint8 j; j < hexagonsInRow; ) {
                    uint8 xIndex = (grid.rows - hexagonsInRow) + (j * 2);
                    grid.hexagonsSvg = getUpdatedHexagonsSvg(grid, xIndex, i, i + 1);
                    unchecked {
                        ++j;
                    }
                }

                unchecked {
                    ++i;
                }
            }
        } else if (honeycomb.baseHexagon.hexagonType == uint8(HEXAGON_TYPE.FLAT)) {
            uint8 flatTopRows = grid.rows * 2 - 1;
            grid.totalGradients = flatTopRows;
            uint8 halfRows = grid.rows / 2;

            for (uint8 i; i < flatTopRows; ) {
                // Determine hexagons in row.
                uint8 hexagonsInRow;
                if (i <= grid.rows / 2) {
                    // ascending, i.e. rows = 1 2 3 4 5 when rows = 5
                    hexagonsInRow = i + 1;
                } else if (i < flatTopRows - halfRows - 1) {
                    // alternate between rows / 2 + 1 and rows / 2 every other row
                    hexagonsInRow = (halfRows + i) % 2 == 0 ? halfRows + 1 : halfRows;
                } else {
                    // descending, i.e. rows = 5, 4, 3, 2, 1 when rows = 5
                    hexagonsInRow = flatTopRows - i;
                }

                // Assign indexes for each hexagon.
                for (uint8 j; j < hexagonsInRow; ) {
                    uint8 xIndex = (grid.rows - hexagonsInRow) - halfRows + (j * 2);
                    grid.hexagonsSvg = getUpdatedHexagonsSvg(grid, xIndex, i, i + 1);
                    unchecked {
                        ++j;
                    }
                }

                unchecked {
                    ++i;
                }
            }
        }

        return grid;
    }

    /// @dev Get the honeycomb grid for a diamond shape.
    /// @param honeycomb The honeycomb data used for rendering.
    function getDiamondGrid(IHoneycombs.Honeycomb memory honeycomb) public pure returns (IHoneycombs.Grid memory) {
        IHoneycombs.Grid memory grid;

        // Get random rows from 3 to honeycomb.canvas.maxHexagonsPerLine, only odd.
        grid.rows = uint8(
            Utilities.random(honeycomb.seed, "rows", (honeycomb.canvas.maxHexagonsPerLine / 2) - 1) * 2 + 3
        );

        // Determine positioning of entire grid, which is based on the longest row.
        grid.longestRowCount = grid.rows / 2 + 1;
        grid = addGridPositioning(honeycomb, grid); // appends to grid object

        // Create diamond grid. Both flat top and pointy top result in the same grid, so no need to check hexagon type.
        for (uint8 i; i < grid.rows; ) {
            // Determine hexagons in row. Pattern is ascending/descending sequence, i.e 1 2 3 2 1 when rows = 5.
            uint8 hexagonsInRow = i < grid.rows / 2 ? i + 1 : grid.rows - i;
            uint8 firstXInRow = i < grid.rows / 2 ? grid.rows / 2 - i : i - grid.rows / 2;

            // Assign indexes for each hexagon.
            for (uint8 j; j < hexagonsInRow; ) {
                uint8 xIndex = firstXInRow + (j * 2);
                grid.hexagonsSvg = getUpdatedHexagonsSvg(grid, xIndex, i, i + 1);
                unchecked {
                    ++j;
                }
            }

            unchecked {
                ++i;
            }
        }

        grid.totalGradients = grid.rows;
        return grid;
    }

    /// @dev Get the honeycomb grid for a triangle shape.
    /// @param honeycomb The honeycomb data used for rendering.
    function getTriangleGrid(IHoneycombs.Honeycomb memory honeycomb) public pure returns (IHoneycombs.Grid memory) {
        IHoneycombs.Grid memory grid;

        // Get random rows from 2 to honeycomb.canvas.maxHexagonsPerLine.
        grid.rows = uint8(Utilities.random(honeycomb.seed, "rows", honeycomb.canvas.maxHexagonsPerLine - 1) + 2);

        // Determine positioning of entire grid, which is based on the longest row.
        grid.longestRowCount = grid.rows;
        grid = addGridPositioning(honeycomb, grid); // appends to grid object

        // Create grid based on hexagon base type.
        if (honeycomb.baseHexagon.hexagonType == uint8(HEXAGON_TYPE.POINTY)) {
            grid.totalGradients = grid.rows;

            // Iterate through rows - will only be north/south facing (design).
            for (uint8 i; i < grid.rows; ) {
                // Assign indexes for each hexagon. Each row has i + 1 hexagons.
                for (uint8 j; j < i + 1; ) {
                    uint8 xIndex = grid.rows - 1 - i + (j * 2);
                    grid.hexagonsSvg = getUpdatedHexagonsSvg(grid, xIndex, i, i + 1);
                    unchecked {
                        ++j;
                    }
                }

                unchecked {
                    ++i;
                }
            }
        } else if (honeycomb.baseHexagon.hexagonType == uint8(HEXAGON_TYPE.FLAT)) {
            uint8 flatTopRows = grid.rows * 2 - 1;
            grid.totalGradients = flatTopRows;

            // Iterate through rows - will only be west/east facing (design).
            for (uint8 i; i < flatTopRows; ) {
                // Determine hexagons in row. First half is ascending. Second half is descending.
                uint8 hexagonsInRow;
                if (i <= flatTopRows / 2) {
                    // ascending with peak, i.e. rows = 1 1 2 2 3 when rows = 5
                    hexagonsInRow = i / 2 + 1;
                } else {
                    // descending with peak, i.e. rows = 2 2 1 1 when rows = 5
                    hexagonsInRow = ((flatTopRows - i - 1) / 2) + 1;
                }

                // Assign indexes for each hexagon. Each row has i + 1 hexagons.
                for (uint8 j; j < hexagonsInRow; ) {
                    uint8 xIndex = (i % 2) + (j * 2);
                    grid.hexagonsSvg = getUpdatedHexagonsSvg(grid, xIndex, i, i + 1);
                    unchecked {
                        ++j;
                    }
                }

                unchecked {
                    ++i;
                }
            }
        }

        return grid;
    }

    /// @dev Generate the overall honeycomb grid, including the final svg.
    /// @dev Using double coordinates: https://www.redblobgames.com/grids/hexagons/#coordinates-doubled
    /// @param honeycomb The honeycomb data used for rendering.
    /// @return (bytes, uint8, uint8) The svg, totalGradients, and rows.
    function generateGrid(IHoneycombs.Honeycomb memory honeycomb) public pure returns (bytes memory, uint8, uint8) {
        // Partial grid object used to store supportive variables
        IHoneycombs.Grid memory gridData;

        // Get grid data based on shape.
        if (honeycomb.grid.shape == uint8(SHAPE.TRIANGLE)) {
            gridData = getTriangleGrid(honeycomb);
        } else if (honeycomb.grid.shape == uint8(SHAPE.DIAMOND)) {
            gridData = getDiamondGrid(honeycomb);
        } else if (honeycomb.grid.shape == uint8(SHAPE.HEXAGON)) {
            gridData = getHexagonGrid(honeycomb);
        } else if (honeycomb.grid.shape == uint8(SHAPE.RANDOM)) {
            gridData = getRandomGrid(honeycomb);
        }

        // Generate grid svg.
        // prettier-ignore
        bytes memory svg = abi.encodePacked(
            '<g transform="scale(1) rotate(', 
                    Utilities.uint2str(honeycomb.grid.rotation) ,',', 
                    Utilities.uint2str(honeycomb.canvas.size / 2) ,',', 
                    Utilities.uint2str(honeycomb.canvas.size / 2), ')">',
                gridData.hexagonsSvg,
            '</g>'
        );

        return (svg, gridData.totalGradients, gridData.rows);
    }

    /// @dev Generate relevant rendering data by loading honeycomb from storage and filling its attribute settings.
    /// @param honeycombs The DB containing all honeycombs.
    /// @param tokenId The tokenId of the honeycomb to render.
    function generateHoneycombRenderData(
        IHoneycombs.Honeycombs storage honeycombs,
        uint256 tokenId
    ) public view returns (IHoneycombs.Honeycomb memory honeycomb) {
        IHoneycombs.StoredHoneycomb memory stored = honeycombs.all[tokenId];
        honeycomb.stored = stored;

        // Determine if the honeycomb is revealed via the epoch randomness.
        uint128 randomness = honeycombs.epochs[stored.epoch].randomness;
        honeycomb.isRevealed = randomness > 0;

        // console.log("\nRENDER DATA Stored Epoch is %s", stored.epoch);
        // console.log("RENDER DATA Honeycombs Epoch Committed is %s", honeycombs.epochs[stored.epoch].committed);
        // console.log("RENDER DATA Honeycombs Epoch Revealed is %s", honeycombs.epochs[stored.epoch].revealed);
        // console.log("RENDER DATA Honeycombs Epoch Reveal Block is %s", honeycombs.epochs[stored.epoch].revealBlock);
        // console.log("RENDER DATA Current Block is %s", block.number);
        // console.log("RENDER DATA Randomness is %s", randomness);

        // Exit early if the honeycomb is not revealed.
        if (!honeycomb.isRevealed) {
            return honeycomb;
        }

        // Set the seed.
        honeycomb.seed = (uint256(keccak256(abi.encodePacked(randomness, stored.seed))) % type(uint128).max);

        // Set the canvas properties.
        honeycomb.canvas.color = Utilities.random(honeycomb.seed, "canvasColor", 2) == 0 ? "White" : "Black";
        honeycomb.canvas.size = 810;
        honeycomb.canvas.hexagonSize = 72;
        honeycomb.canvas.maxHexagonsPerLine = 8; // (810 (canvasSize) - 90 (padding) / 72 (hexagon size)) - 1 = 8

        console.log("\nSeed is: %s", Utilities.uint2str(honeycomb.seed));
        console.log("Canvas Color: %s", honeycomb.canvas.color);
        console.log("Canvas Size: %s", Utilities.uint2str(honeycomb.canvas.size));
        console.log("Canvas Hexagon Size: %s", Utilities.uint2str(honeycomb.canvas.hexagonSize));
        console.log("Canvas Max Hexagons Per Line: %s", Utilities.uint2str(honeycomb.canvas.maxHexagonsPerLine));

        // Get the base hexagon properties.
        honeycomb.baseHexagon.hexagonType = uint8(
            Utilities.random(honeycomb.seed, "hexagonType", 2) == 0 ? HEXAGON_TYPE.FLAT : HEXAGON_TYPE.POINTY
        );
        honeycomb.baseHexagon.path = getHexagonPath(honeycomb.baseHexagon.hexagonType);
        honeycomb.baseHexagon.strokeWidth = uint8(Utilities.random(honeycomb.seed, "strokeWidth", 15) + 3);
        honeycomb.baseHexagon.fillColor = Utilities.random(honeycomb.seed, "hexagonFillColor", 2) == 0
            ? "White"
            : "Black";

        console.log("Base Hexagon Type: %s", honeycomb.baseHexagon.hexagonType);
        console.log("Base Hexagon Stroke Width: %s", Utilities.uint2str(honeycomb.baseHexagon.strokeWidth));
        console.log("Base Hexagon Fill Color: %s", honeycomb.baseHexagon.fillColor);

        /**
         * Get the grid properties, including the actual svg.
         * Note: Random shapes must only have pointy top hexagon bases (artist design choice).
         * Note: Triangles have unique rotation options (artist design choice).
         */
        honeycomb.grid.shape = uint8(Utilities.random(honeycomb.seed, "gridShape", 4));
        if (honeycomb.grid.shape == uint8(SHAPE.RANDOM)) {
            honeycomb.baseHexagon.hexagonType = uint8(HEXAGON_TYPE.POINTY);
            honeycomb.baseHexagon.path = getHexagonPath(honeycomb.baseHexagon.hexagonType);
        }

        honeycomb.grid.rotation = honeycomb.grid.shape == uint8(SHAPE.TRIANGLE)
            ? uint16(Utilities.random(honeycomb.seed, "rotation", 4) * 90)
            : uint16(Utilities.random(honeycomb.seed, "rotation", 12) * 30);

        console.log("Grid Shape: %s", honeycomb.grid.shape);
        console.log("Grid Rotation: %s", Utilities.uint2str(honeycomb.grid.rotation));

        (honeycomb.grid.svg, honeycomb.grid.totalGradients, honeycomb.grid.rows) = generateGrid(honeycomb);

        console.log("Grid Total Gradients: %s", Utilities.uint2str(honeycomb.grid.totalGradients));
        console.log("Grid Rows: %s", Utilities.uint2str(honeycomb.grid.rows));

        // Get the gradients properties, including the actual svg.
        honeycomb.gradients.chrome = getChrome(uint8(Utilities.random(honeycomb.seed, "chrome", 7)));
        honeycomb.gradients.duration = getDuration(uint16(Utilities.random(honeycomb.seed, "duration", 4)));
        honeycomb.gradients.direction = uint8(Utilities.random(honeycomb.seed, "direction", 2));
        console.log("Gradients Chrome: %s", honeycomb.gradients.chrome);
        console.log("Gradients Duration: %s", honeycomb.gradients.duration);
        console.log("Gradients Direction: %s", honeycomb.gradients.direction);
        honeycomb.gradients.svg = generateGradientsSvg(honeycomb);

        console.log("Done rendering");
    }

    /// @dev Generate the complete SVG and its associated data for a honeycomb.
    /// @param honeycombs The DB containing all honeycombs.
    /// @param tokenId The tokenId of the honeycomb to render.
    function generateHoneycomb(
        IHoneycombs.Honeycombs storage honeycombs,
        uint256 tokenId
    ) public view returns (IHoneycombs.Honeycomb memory) {
        IHoneycombs.Honeycomb memory honeycomb = generateHoneycombRenderData(honeycombs, tokenId);

        if (!honeycomb.isRevealed) {
            // prettier-ignore
            honeycomb.svg = abi.encodePacked(
                '<svg viewBox="0 0 810 810" fill="none" xmlns="http://www.w3.org/2000/svg"',
                    'style="width:100%;background:black;">',
                    '<rect width="810" height="810" fill="black"/>',
                '</svg>'
            );
        } else {
            // prettier-ignore
            honeycomb.svg = abi.encodePacked(
                // Note: Use 810 as hardcoded size to avoid stack too deep error.
                '<svg viewBox="0 0 810 810" fill="none" xmlns="http://www.w3.org/2000/svg"', 
                        'style="width:100%;background:', honeycomb.canvas.color, ';">',
                    '<defs>',
                        '<path id="hexagon" fill="', honeycomb.baseHexagon.fillColor,
                            '" stroke-width="', Utilities.uint2str(honeycomb.baseHexagon.strokeWidth),
                            '" d="', honeycomb.baseHexagon.path ,'" />',
                        honeycomb.gradients.svg,
                    '</defs>',
                    '<rect width="810" height="810" fill="', honeycomb.canvas.color, '"/>',
                    honeycomb.grid.svg,
                    '<rect width="810" height="810" fill="transparent">',
                        '<animate attributeName="width" from="810" to="0" dur="0.2s" fill="freeze" ',
                            'begin="click" id="animation"/>',
                    '</rect>',
                '</svg>'
            );
        }

        return honeycomb;
    }
}

/// @dev All internal data relevant to a gradient stop.
struct GradientStop {
    bytes color; // color of the gradient stop
    bytes animationColorValues; // color values for the animation
}

/// @dev All additional internal data for rendering a gradient svg string.
struct GradientData {
    GradientStop stop1; // first gradient stop
    GradientStop stop2; // second gradient stop
    uint16 duration; // duration of the animation
    uint8 gradientId; // id of the gradient
    uint8 y1; // y1 of the gradient
    uint8 y2; // y2 of the gradient
    uint8 offset; // offset of the gradient
}
