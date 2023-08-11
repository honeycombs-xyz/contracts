// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IHoneycombs {
    struct StoredHoneycomb {
        uint32 epoch; // Each honeycomb is revealed in an epoch
        uint16 seed; // A unique identifier to enable swapping
        uint24 day; // The days since token was created
    }

    struct Honeycomb {
        StoredHoneycomb stored; // We carry over the honeycomb from storage
        bool isRevealed; // Whether the honeycomb is revealed
        uint256 seed; // The instantiated seed for pseudo-randomisation
        bytes svg; // final svg for the honeycomb
        Canvas canvas; // all data relevant to the canvas
        BaseHexagon baseHexagon; // all data relevant to the base hexagon
        Grid grid; // all data relevant to the grid
        Gradients gradient; // all data relevant to the gradients
    }

    struct Honeycombs {
        mapping(uint256 => StoredHoneycomb) all; // All honeycombs
        uint32 maxSupply; // The maximum number of honeycombs that can be minted
        uint32 minted; // The number of honeycombs that have been minted
        uint32 burned; // The number of honeycombs that have been burned
        uint32 day0; // Marks the start of this journey
        mapping(uint256 => Epoch) epochs; // All epochs
        uint256 epoch; // The current epoch index
    }

    struct Canvas {
        string color; // background color of canvas
        uint16 width; // width of canvas
        uint16 height; // height of canvas
    }

    struct BaseHexagon {
        string path; // path of base hexagon
        string fillColor; // fill color of base hexagon
        uint8 strokeWidth; // stroke width size in user units (pixels)
        uint8 hexagonType; // type of base hexagon, i.e. flat or pointy
    }

    struct Grid {
        bytes hexagonsSvg; // final svg for all hexagons
        bytes svg; // final svg for the grid
        uint16 gridX; // x coordinate of the grid
        uint16 gridY; // y coordinate of the grid
        uint16 rowDistance; // distance between rows in user units (pixels)
        uint16 columnDistance; // distance between columns in user units (pixels)
        uint16 rotation; // rotation of entire shape in degrees
        uint8 shape; // shape of the grid, i.e. triangle, diamond, hexagon, random
        uint8 totalGradients; // number of gradients required based on the grid size and shape
        uint8 rows; // number of rows in the grid
        uint8 longestRowCount; // largest row size in the grid for centering purposes
    }

    struct Gradients {
        bytes svg; // final svg for the gradients
        uint16 duration; // duration of animation in seconds
        uint8 direction; // direction of animation, i.e. forward or backward
        uint8 chrome; // max number of colors in all the gradients, aka chrome
    }

    struct Epoch {
        uint128 randomness; // The source of randomness for tokens from this epoch
        uint64 revealBlock; // The block at which this epoch was / is revealed
        bool committed; // Whether the epoch has been instantiated
        bool revealed; // Whether the epoch has been revealed
    }

    event NewEpoch(uint256 indexed epoch, uint64 indexed revealBlock);

    error NotAllowed();
}