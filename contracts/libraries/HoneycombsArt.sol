//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../interfaces/IHoneycombs.sol";
import "./Colors.sol";
import "./Utilities.sol";

/**
    TODO
    - [] Verify base stroke width should be 8 as constant or based on hexagon size
    - [] Verify max hexagons per row and column should be 9 as constant or formulas
    - [] Verify CANVAS_WIDTH, etc should be global (in renderingData) or constant or as is?
    - [] Verify public/internal and view/pure for all functions
    - [!!] Implement floating point math for hexagon stroke width
    - [] Unit test that randomness creates different outcomes for each block and different tokenIds
    - [] Unit test random for hexagon array of length rows actually works in getHexagonGrid()
    
    - [] Verify +4/+2 for animation color makes sense 
    - [] Verify the animation count is 30 total values, 15 diff colors
    - [] Add logic for selecting initial primary colors of the gradients that isn't purely random, loosely based on the color palette
    
    - [] Add logic for isRevealed for commit and reveal scheme
    - [] Add logic for probabilities of some random variables
    - [!!] Diff between storage and memory for stored structs?
    - [!!] Does both stored and honeycomb struct need to have seed?
    - [!!] Ensure code compiles
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

    /// @dev All data relevant for a gradient stop.
    struct GradientStop {
        string color; // color of the gradient stop
        bytes animationColorValues; // color values for the animation
    }

    /// @dev The paths for a 72x72 px hexagon.
    function getHexagonPath(HEXAGON_TYPE pathType) public pure returns (string memory) {
        if (pathType == HEXAGON_TYPE.FLAT) {
            return "M22.2472 7.32309L4.82457 37.5C3.93141 39.047 3.93141 40.953 4.82457 42.5L22.2472 72.6769C23.1404 74.2239 24.791 75.1769 26.5774 75.1769H61.4226C63.209 75.1769 64.8596 74.2239 65.7528 72.6769L83.1754 42.5C84.0686 40.953 84.0686 39.047 83.1754 37.5L65.7528 7.32309C64.8596 5.77608 63.209 4.82309 61.4226 4.82309H26.5774C24.791 4.82309 23.1404 5.77608 22.2472 7.32309Z"; // prettier-ignore
        } else if (pathType == HEXAGON_TYPE.POINTY) {
            return "M72.6769 22.2472L42.5 4.82457C40.953 3.93141 39.047 3.93141 37.5 4.82457L7.32309 22.2472C5.77608 23.1404 4.82309 24.791 4.82309 26.5774V61.4226C4.82309 63.209 5.77608 64.8596 7.32309 65.7528L37.5 83.1754C39.047 84.0686 40.953 84.0686 42.5 83.1754L72.6769 65.7528C74.2239 64.8596 75.1769 63.209 75.1769 61.4226V26.5774C75.1769 24.791 74.2239 23.1404 72.6769 22.2472Z"; // prettier-ignore
        }
    }

    /// @dev Get from different shapes of the honeycomb. Corresponds to shape trait in HoneycombsMetadata.sol.
    function getShape(uint8 index) public pure returns (uint8) {
        return uint8([SHAPE.TRIANGLE, SHAPE.DIAMOND, SHAPE.HEXAGON, SHAPE.RANDOM][index]);
    }

    /// @dev Get from different chromes or max primary colors. Corresponds to chrome trait in HoneycombsMetadata.sol.
    function getChrome(uint8 index) public pure returns (uint8) {
        return uint8([0, 1, 2, 3, 4, 5, 6, Colors.COLORS().length][index]);
    }

    /// @dev Get from different animation durations in seconds. Corresponds to duration trait in HoneycombsMetadata.sol.
    function getDuration(uint8 index) public pure returns (uint8) {
        return uint8([10, 40, 80, 240][index]);
    }

    /// @dev Get the linear gradient's svg.
    /// @param stop1 First gradient stop.
    /// @param stop2 Second gradient stop.
    /// @param gradientId Gradient id per row.
    /// @param x1 X1 coordinate of linear gradient from 0-100 (percentage).
    /// @param x2 X2 coordinate of linear gradient from 0-100 (percentage).
    /// @param y1 Y1 coordinate of linear gradient from 0-100 (percentage).
    /// @param y2 Y2 coordinate of linear gradient from 0-100 (percentage).
    /// @param offset Offset using for the second gradient from 0-100 (decimal).
    /// @param duration Duration of the animation.
    function getLinearGradientSvg(
        GradientStop memory stop1,
        GradientStop memory stop2,
        uint16 duration,
        uint8 gradientId,
        uint8 x1,
        uint8 x2,
        uint8 y1,
        uint8 y2,
        uint8 offset
    ) public pure returns (bytes memory) {
        // prettier-ignore
        bytes memory svg = abi.encodePacked(
            '<linearGradient id="gradient', gradientId, '" x1="', x1, '%" x2="', x2, '%" y1="', y1,
                    '%" y2="', y2, '%">',
                '<stop stop-color="', stop1.color, '">',
                    '<animate attributeName="stop-color" values="', stop1.animationColorValues, '" dur="', duration,
                        's" begin="animation.begin" repeatCount="indefinite" />',
                '</stop>',
                '<stop offset="0.', offset, '" stop-color="', stop2.color, '">',
                    '<animate attributeName="stop-color" values="', stop2.animationColorValues, '" dur="', duration,
                        's" begin="animation.begin" repeatCount="indefinite" />',
                '</stop>',
            '</linearGradient>'
        );

        return svg;
    }

    /// @dev Get the stop for a linear gradient.
    /// @param honeycomb The honeycomb data used for rendering.
    function getLinearGradientStopSvg(
        IHoneycombs.Honeycomb memory honeycomb
    ) public pure returns (GradientStop memory) {
        GradientStop memory stop;

        // We pick 14 colors for our gradient, which leads to 15 different colors including the initial color.
        uint8 count = 14;
        string[46] memory allColors = Colors.COLORS();

        // Get random stop color.
        uint8 initialIndex = Utilities.random(honeycomb.seed, "linearGradientStop", allColors.length);
        stop.color = allColors[initialIndex];

        bytes memory values;
        // Forward loop through our color gradient. First and last value is the initial stop color.
        if (honeycomb.gradients.direction == 0) {
            for (uint256 i; i < count - 2; ) {
                values = abi.encodePacked(values, "#", allColors[(initialIndex + ((i * 2) % allColors.length))], ";");
                unchecked {
                    ++i;
                }
            }

            // Reverse for smooth animations.
            for (uint256 i = count - 2; i >= 0; ) {
                values = abi.encodePacked(values, "#", allColors[(initialIndex + ((i * 2) % allColors.length))], ";");
                unchecked {
                    --i;
                }
            }
        } else {
            // Reverse loop through our color gradient. First and last value is the initial stop color.
            for (uint256 i = count - 2; i >= 0; ) {
                values = abi.encodePacked(values, "#", allColors[(initialIndex + ((i * 2) % allColors.length))], ";");
                unchecked {
                    --i;
                }
            }

            // Reverse for smooth animations.
            for (uint256 i; i < count - 2; ) {
                values = abi.encodePacked(values, "#", allColors[(initialIndex + ((i * 2) % allColors.length))], ";");
                unchecked {
                    ++i;
                }
            }
        }

        stop.animationColorValues = abi.encodePacked(values, "#", allColors[initialIndex]);

        return stop;
    }

    /// @dev Get all gradients data, particularly the svg.
    /// @param honeycomb The honeycomb data used for rendering.
    function generateGradientsSvg(IHoneycombs.Honeycomb memory honeycomb) public pure returns (bytes memory) {
        bytes memory svg;

        // Initialize mapping of stops (id => svgString) for reuse once we reach the max color count.
        mapping(uint256 => GradientStop) memory stops;
        GradientStop memory prevStop = getLinearGradientStopSvg(honeycomb.gradients);
        stops[0] = prevStop;

        // Loop through all gradients and generate the svg.
        for (uint256 i; i < honeycomb.gradients.count; ) {
            GradientStop memory stop;

            // Get next stop.
            if (stops.length < honeycomb.gradients.chrome) {
                stop = getLinearGradientStopSvg(honeycomb.gradients.duration);
                stops[i + 1] = stop;
            } else {
                // Randomly select a stop from existing ones.
                stop = stops[Utilities.random(honeycomb.seed, abi.encodePacked("stop", i), stops.length)];
            }

            // Get gradients svg based on the base hexagon type.
            if (honeycomb.baseHexagon.hexagonType == HEXAGON_TYPE.POINTY) {
                bytes memory gradientSvg = getLinearGradientSvg(
                    prevStop,
                    stop,
                    honeycomb.gradients.duration,
                    i + 1,
                    0, // x1
                    0, // x2
                    25, // y1
                    81, // y2
                    72 // offset
                );

                // Append gradient to svg, update previous stop, and increment index.
                svg = abi.encodePacked(svg, gradientSvg);
                prevStop = stop;
                unchecked {
                    ++i;
                }
            } else if (honeycomb.baseHexagon.hexagonType == HEXAGON_TYPE.FLAT) {
                // Flat tops require two gradients.
                bytes memory gradient1Svg = getLinearGradientSvg(
                    prevStop,
                    stop,
                    honeycomb.gradients.duration,
                    i + 1,
                    0, // x1
                    0, // x2
                    50, // y1
                    100, // y2
                    72 // offset
                );

                bytes memory gradient2Svg = getLinearGradientSvg(
                    prevStop,
                    stop,
                    honeycomb.gradients.duration,
                    i + 2,
                    0, // x1
                    0, // x2
                    4, // y1
                    100, // y2
                    30 // offset
                );

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
    /// @param grid The grid metadata.
    /// @param baseHexagonType The base hexagon type.
    function addGridPositioning(
        IHoneycombs.Grid memory grid,
        HEXAGON_TYPE baseHexagonType
    ) public pure returns (IHoneycombs.Grid memory) {
        // Compute grid properties.
        grid.rowDistance = HEXAGON_WIDTH - (0.25 * HEXAGON_WIDTH - 0.75 * HEXAGON_STROKE_WIDTH);
        grid.columnDistance = HEXAGON_WIDTH / 2;
        uint16 gridWidth = grid.longestRowCount * HEXAGON_WIDTH + HEXAGON_STROKE_WIDTH;
        uint16 gridHeight = grid.rows * HEXAGON_HEIGHT + HEXAGON_STROKE_WIDTH;

        /**
         * Swap variables if it is a flat top hexagon (this math assumes pointy top as default). Rotating a flat top
         * hexagon 90 degrees clockwise results in a pointy top hexagon. This effectively swaps the x and y axis.
         */
        if (baseHexagonType == HEXAGON_TYPE.FLAT) {
            (grid.rowDistance, grid.columnDistance) = Utilities.swap(grid.rowDistance, grid.columnDistance);
            (gridWidth, gridHeight) = Utilities.swap(gridWidth, gridHeight);
        }

        // Compute grid positioning.
        grid.gridX = (CANVAS_WIDTH - gridWidth) / 2 - (HEXAGON_STROKE_WIDTH / 2);
        grid.gridY = (CANVAS_HEIGHT - gridHeight) / 2;

        return grid;
    }

    /// @dev Get the honeycomb grid for a random shape.
    /// @param honeycomb The honeycomb data used for rendering.
    function getRandomGrid(IHoneycombs.Honeycomb memory honeycomb) public pure returns (IHoneycombs.Grid memory) {
        IHoneycombs.Grid memory grid;

        // Get random rows from 1 to MAX_HEXAGONS_PER_ROW.
        grid.rows = Utilities.random(honeycomb.seed, "rows", MAX_HEXAGONS_PER_ROW) + 1;

        // Get random hexagons in each row from 1 to MAX_HEXAGONS_PER_ROW - 1.
        uint8[] memory hexagonsInRow = new uint8[](grid.rows);
        for (uint8 i; i < grid.rows; ) {
            hexagonsInRow[i] =
                Utilities.random(
                    honeycomb.seed,
                    abi.encodePacked("hexagonsInRow", Utilities.uint2str(i)),
                    MAX_HEXAGONS_PER_ROW - 1
                ) + 1; // prettier-ignore
            grid.longestRowCount = Utilities.max(hexagonsInRow[i], grid.longestRowCount);

            unchecked {
                ++i;
            }
        }

        // Determine positioning of entire grid, which is based on the longest row.
        grid = addGridPositioning(honeycomb.baseHexagon.hexagonType, grid); // appends to grid object

        int8 lastRowEvenOdd = -1; // Helps avoid overlapping hexagons: -1 = unset, 0 = even, 1 = odd
        // Create random grid. Only working with pointy tops for simplicity.
        for (uint8 i; i < grid.rows; ) {
            uint8 firstX = grid.longestRowCount - hexagonsInRow[i];

            // Increment firstX if last row's evenness/oddness is same as this rows and update with current.
            if (lastRowEvenOdd == firstX % 2) ++firstX;
            lastRowEvenOdd = firstX % 2;

            // Assign indexes for each hexagon.
            for (uint8 j; j < hexagonsInRow[i]; ) {
                uint8 xIndex = firstX + (j * 2);
                grid.hexagonsSvg = getUpdatedHexagonsSvg(grid.hexagonsSvg, grid, xIndex, i, i + 1);
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

        // Get random rows from 3 to MAX_HEXAGONS_PER_ROW, only odd.
        grid.rows = Utilities.random(honeycomb.seed, "rows", (MAX_HEXAGONS_PER_ROW / 2) - 1) * 2 + 3;

        // Determine positioning of entire grid, which is based on the longest row.
        grid.longestRowCount = grid.rows;
        grid = addGridPositioning(honeycomb.baseHexagon.hexagonType, grid); // appends to grid object

        // Create grid based on hexagon base type.
        if (honeycomb.baseHexagonType == HEXAGON_TYPE.POINTY) {
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
        } else if (honeycomb.baseHexagonType == HEXAGON_TYPE.FLAT) {
            uint8 flatTopRows = grid.rows * 2 - 1;
            grid.totalGradients = flatTopRows;

            for (uint8 i; i < flatTopRows; ) {
                // Determine hexagons in row.
                uint8 hexagonsInRow;
                if (i < grid.rows / 2) {
                    // ascending, i.e. rows = 1 2 3 4 5 when rows = 5
                    hexagonsInRow = i / 2 + 1;
                } else if (i < flatTopRows - grid.rows / 2 - 1) {
                    // alternate between rows / 2 + 1 and rows / 2 every other row
                    hexagonsInRow = (grid.rows / 2 + i) % 2 == 0 ? grid.rows / 2 + 1 : grid.rows / 2;
                } else {
                    // descending, i.e. rows = 5, 4, 3, 2, 1 when rows = 5
                    hexagonsInRow = flatTopRows - i;
                }

                // Assign indexes for each hexagon.
                for (uint8 j; j < hexagonsInRow; ) {
                    uint8 xIndex = (grid.rows - hexagonsInRow) - grid.rows / 2 + (j * 2);
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

        // Get random rows from 3 to MAX_HEXAGONS_PER_ROW, only odd.
        grid.rows = Utilities.random(honeycomb.seed, "rows", (MAX_HEXAGONS_PER_ROW / 2) - 1) * 2 + 3;

        // Determine positioning of entire grid, which is based on the longest row.
        grid.longestRowCount = grid.rows / 2 + 1;
        grid = addGridPositioning(honeycomb.baseHexagon.hexagonType, grid); // appends to grid object

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

        // Get random rows from 2 to MAX_HEXAGONS_PER_ROW.
        grid.rows = Utilities.random(honeycomb.seed, "rows", MAX_HEXAGONS_PER_ROW - 1) + 2;

        // Determine positioning of entire grid, which is based on the longest row.
        grid.longestRowCount = grid.rows;
        grid = addGridPositioning(honeycomb.baseHexagon.hexagonType, grid); // appends to grid object

        // Create grid based on hexagon base type.
        if (honeycomb.baseHexagonType == HEXAGON_TYPE.POINTY) {
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
        } else if (honeycomb.baseHexagonType == HEXAGON_TYPE.FLAT) {
            uint8 flatTopRows = grid.rows * 2 - 1;
            grid.totalGradients = flatTopRows;

            // Iterate through rows - will only be west/east facing (design).
            for (uint8 i; i < flatTopRows; ) {
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
                for (uint8 j; j < i + 1; ) {
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
    function generateGrid(IHoneycombs.Honeycomb memory honeycomb) public pure returns (IHoneycombs.Grid memory) {
        // Carry through original grid data.
        IHoneycombs.Grid memory grid = honeycomb.grid;

        // Get grid data based on shape, which includes the hexagonsSvg and totalGradients required.
        IHoneycombs.Grid memory gridData; // partial and temporary grid object used to store supportive variables
        if (grid == SHAPE.TRIANGLE) {
            gridData = getTriangleGrid(honeycomb);
        } else if (grid == SHAPE.DIAMOND) {
            gridData = getDiamondGrid(honeycomb);
        } else if (grid == SHAPE.HEXAGON) {
            gridData = getHexagonGrid(honeycomb);
        } else if (grid == SHAPE.RANDOM) {
            gridData = getRandomGrid(honeycomb);
        }

        // Append data to the grid object.
        // prettier-ignore
        grid.svg = abi.encodePacked(
            '<g transform="scale(1) rotate(', 
                    Utilities.uint2str(grid.rotation) ,',', 
                    Utilities.uint2str(honeycomb.canvas.width / 2) ,',', 
                    Utilities.uint2str(honeycomb.canvas.height / 2), '">',
                gridData.hexagonsSvg,
            '</g>'
        );
        grid.totalGradients = gridData.totalGradients;

        return grid;
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

        // Set up the source of randomness + seed for this Honeycomb.
        uint128 randomness = honeycombs.epochs[stored.epoch].randomness;
        honeycomb.seed = (uint256(keccak256(abi.encodePacked(randomness, stored.seed))) % type(uint128).max);
        honeycomb.isRevealed = randomness > 0;

        // Set the canvas properties.
        honeycomb.canvas.color = Utilities.random(honeycomb.seed, "canvasColor", 2) == 0 ? "white" : "black";
        honeycomb.canvas.width = CANVAS_WIDTH;
        honeycomb.canvas.height = CANVAS_HEIGHT;

        // Get the base hexagon properties.
        honeycomb.baseHexagon.hexagonType = Utilities.random(honeycomb.seed, "hexagonType", 2) == 0
            ? HEXAGON_TYPE.FLAT
            : HEXAGON_TYPE.POINTY;
        honeycomb.baseHexagon.path = getHexagonPath(honeycomb.baseHexagon.hexagonType);
        honeycomb.baseHexagon.strokeWidth =
            Utilities.random(honeycomb.seed, "strokeWidth", MAX_HEXAGON_STROKE_WIDTH) +
            MIN_HEXAGON_STROKE_WIDTH;
        honeycomb.baseHexagon.fillColor = Utilities.random(honeycomb.seed, "hexagonFillColor", 2) == 0
            ? "white"
            : "black";

        /**
         * Get the grid properties, including the actual svg.
         * Note: Random shapes must only have pointy top hexagon bases (artist design choice).
         * Note: Triangles have unique rotation options (artist design choice).
         */
        honeycomb.grid.shape = getShape([Utilities.random(honeycomb.seed, "gridShape", 4)]);
        if (honeycomb.grid.shape == SHAPE.RANDOM) honeycomb.baseHexagon.hexagonType = HEXAGON_TYPE.POINTY;

        honeycomb.grid.rotation = honeycomb.grid.shape == SHAPE.TRIANGLE
            ? Utilities.random(honeycomb.seed, "rotation", 4) * 90
            : Utilities.random(honeycomb.seed, "rotation", 12) * 30;

        honeycomb.grid = generateGrid(honeycomb);

        // Get the gradients properties, including the actual svg.
        honeycomb.gradients.chrome = getChrome([Utilities.random(honeycomb.seed, "chrome", 7)]);
        honeycomb.gradients.duration = getDuration([Utilities.random(honeycomb.seed, "duration", 4)]);
        honeycomb.gradients.direction = Utilities.random(honeycomb.seed, "direction", 2);
        honeycomb.gradients.svg = generateGradientsSvg(honeycomb);
    }

    /// @dev Generate the complete SVG and its associated data for a honeycomb.
    /// @param honeycombs The DB containing all honeycombs.
    /// @param tokenId The tokenId of the honeycomb to render.
    function generateHoneycomb(
        IHoneycombs.Honeycombs storage honeycombs,
        uint256 tokenId
    ) public view returns (IHoneycombs.Honeycomb memory) {
        IHoneycombs.Honeycomb memory honeycomb = generateHoneycombRenderData(honeycombs, tokenId);

        // prettier-ignore
        honeycomb.svg = abi.encodePacked(
            '<svg viewBox="0 0 ', Utilities.uint2str(honeycomb.canvas.width), ' ', 
                    Utilities.uint2str(honeycomb.canvas.height), '"fill="none" xmlns="http://www.w3.org/2000/svg"', 
                    'style="width:100%;background:', honeycomb.canvas.color, ';">',
                '<defs>',
                    '<path id="hexagon" fill="', honeycomb.baseHexagon.fillColor,
                        '" stroke-width="', Utilities.uint2str(honeycomb.baseHexagon.strokeWidth),
                        '" d="', honeycomb.baseHexagon.path ,'" />',
                    honeycomb.gradients.svg,
                '</defs>',
                '<rect width="', Utilities.uint2str(honeycomb.canvas.width),
                    '" height="', Utilities.uint2str(honeycomb.canvas.width), '" fill="', honeycomb.canvas.color, '"/>',
                honeycomb.grid.svg,
                '<rect width="', Utilities.uint2str(honeycomb.canvas.width),
                    '" height="', Utilities.uint2str(honeycomb.canvas.width), '" fill="transparent">',
                    '<animate attributeName="width" from="', Utilities.uint2str(honeycomb.canvas.width),
                        '" to="0" dur="0.2s" fill="freeze" begin="click" id="animation"/>',
                '</rect>',
            '</svg>'
        );

        return honeycomb;
    }
}
