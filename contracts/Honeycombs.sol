// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interfaces/IHoneycombs.sol";
import "./libraries/HoneycombsArt.sol";
import "./libraries/HoneycombsMetadata.sol";
import "./libraries/Utilities.sol";
import "./standards/HONEYCOMBS721.sol";

/**
    TODO List:
    - [] Add product conditions for when not allowed to mint a new Honeycomb
    - [] Verify and remove MetadataUpdate functionality - used originally for compositing / sacrificing
 */

/**
@title  Honeycombs
@author Gaurang Patel (adapted from checks.vv contracts)
@notice Lokah Samastah Sukhino Bhavantu
*/
contract Honeycombs is IHoneycombs, HONEYCOMBS721 {
    /// @dev We use this database for persistent storage.
    Honeycombs honeycombs;

    /// @dev Initializes the Honeycombs contract.
    constructor() {
        honeycombs.day0 = uint32(block.timestamp);
        honeycombs.epoch = 1;
        honeycombs.maxSupply = 10000;
    }

    /// @notice Mint a new Honeycomb.
    /// @param tokenId The token ID to mint.
    /// @param recipient The address to receive the tokens.
    function mint(uint256 tokenId, address recipient) external {
        // Check whether tokenId is between 1 and maxSupply.
        if (tokenId < 1 || tokenId > honeycombs.maxSupply) {
            revert NotAllowed();
        }

        // Initialize new epoch / resolve previous epoch.
        resolveEpochIfNecessary();

        // Initialize our Honeycomb.
        StoredHoneycomb storage honeycomb = honeycombs.all[tokenId];
        honeycomb.day = Utilities.day(honeycombs.day0, block.timestamp);
        honeycomb.epoch = uint32(honeycombs.epoch);
        honeycomb.seed = uint16(tokenId);

        // Mint the original.
        // If we're minting to a vault, transfer it there.
        if (msg.sender != recipient) {
            _safeMintVia(recipient, msg.sender, tokenId);
        } else {
            _safeMint(msg.sender, tokenId);
        }

        // Keep track of how many honeycombs have been minted.
        unchecked {
            ++honeycombs.minted;
        }
    }

    /// @notice Burn a honeycomb.
    /// @param tokenId The token ID to burn.
    /// @dev A common purpose burn method.
    function burn(uint256 tokenId) external {
        if (!_isApprovedOrOwner(msg.sender, tokenId)) {
            revert NotAllowed();
        }

        // Perform the burn.
        _burn(tokenId);

        // Keep track of supply.
        unchecked {
            ++honeycombs.burned;
        }
    }

    /// @notice Initializes and closes epochs.
    /// @dev Based on the commit-reveal scheme proposed by MouseDev.
    function resolveEpochIfNecessary() public {
        Epoch storage currentEpoch = honeycombs.epochs[honeycombs.epoch];

        if (
            // If epoch has not been committed,
            currentEpoch.committed == false ||
            // Or the reveal commitment timed out.
            (currentEpoch.revealed == false && currentEpoch.revealBlock < block.number - 256)
        ) {
            // This means the epoch has not been committed, OR the epoch was committed but has expired.
            // Set committed to true, and record the reveal block:
            currentEpoch.revealBlock = uint64(block.number + 50);
            currentEpoch.committed = true;
        } else if (block.number > currentEpoch.revealBlock) {
            // Epoch has been committed and is within range to be revealed.
            // Set its randomness to the target block hash.
            currentEpoch.randomness = uint128(
                uint256(keccak256(abi.encodePacked(blockhash(currentEpoch.revealBlock), block.difficulty))) %
                    (2 ** 128 - 1)
            );
            currentEpoch.revealed = true;

            // Notify DApps about the new epoch.
            emit NewEpoch(honeycombs.epoch, currentEpoch.revealBlock);

            // Initialize the next epoch
            honeycombs.epoch++;
            resolveEpochIfNecessary();
        }
    }

    /// @notice The identifier of the current epoch
    function getEpoch() public view returns (uint256) {
        return honeycombs.epoch;
    }

    /// @notice Get the data for a given epoch
    /// @param index The identifier of the epoch to fetch
    function getEpochData(uint256 index) public view returns (Epoch memory) {
        return honeycombs.epochs[index];
    }

    /// @notice Get a specific honeycomb.
    /// @param tokenId The token ID to fetch.
    /// @dev Consider using the HoneycombsArt Library directly.
    function getHoneycomb(uint256 tokenId) external view returns (Honeycomb memory honeycomb) {
        return HoneycombsArt.generateHoneycomb(honeycombs, tokenId);
    }

    /// @notice Render the SVG for a given token.
    /// @param tokenId The token to render.
    /// @dev Consider using the HoneycombsArt Library directly.
    function svg(uint256 tokenId) external view returns (string memory) {
        return string(HoneycombsArt.generateHoneycomb(honeycombs, tokenId).svg);
    }

    /// @notice Get the metadata for a given token.
    /// @param tokenId The token to render.
    /// @dev Consider using the HoneycombsMetadata Library directly.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireMinted(tokenId);

        return HoneycombsMetadata.tokenURI(tokenId, honeycombs);
    }

    /// @notice Returns how many tokens this contract manages.
    function totalSupply() public view returns (uint256) {
        return honeycombs.minted - honeycombs.burned;
    }
}
