// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IHoneycombs {
    struct StoredHoneycomb {
        uint16[6] composites; // The tokenIds that were composited into this one
        uint8[5] colorBands; // The length of the used color band in percent
        uint8[5] gradients; // Gradient settings for each generation
        uint32 epoch; // Each honeycomb is revealed in an epoch
        uint16 seed; // A unique identifier to enable swapping
        uint24 day; // The days since token was created
    }

    struct Honeycomb {
        StoredHoneycomb stored; // We carry over the honeycomb from storage
        bool isRevealed; // Whether the honeycomb is revealed
        uint256 seed; // The instantiated seed for pseudo-randomisation
        uint8 honeycombsCount; // How many honeycombs this token has
        bool hasManyHoneycombs; // Whether the honeycomb has many honeycombs
        uint16 composite; // The parent tokenId that was composited into this one
        bool isRoot; // Whether it has no parents (80 honeycombs)
        uint8 colorBand; // 100%, 50%, 25%, 12.5%, 6.25%, 5%, 1.25%
        uint8 gradient; // Linearly through the colorBand [1, 2, 3]
        uint8 direction; // Animation direction
        uint8 speed; // Animation speed
    }

    struct Epoch {
        uint128 randomness; // The source of randomness for tokens from this epoch
        uint64 revealBlock; // The block at which this epoch was / is revealed
        bool committed; // Whether the epoch has been instantiated
        bool revealed; // Whether the epoch has been revealed
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

    event NewEpoch(uint256 indexed epoch, uint64 indexed revealBlock);

    error NotAllowed();
}
