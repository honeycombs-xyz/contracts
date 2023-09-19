// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interfaces/IHoneycombs.sol";
import "./libraries/HoneycombsArt.sol";
import "./libraries/HoneycombsMetadata.sol";
import "./libraries/Utilities.sol";
import "./standards/HONEYCOMBS721.sol";

/**
    TODO List:
    - [] Add delegateCash to mint function
    - [] Fix smart contract size
    
    - [] UPDATE reserve addresses
 */

/**
@title  Honeycombs
@author Gaurang Patel (adapted from checks.vv contracts)
@notice You are searching the world for treasure, but the real treasure is yourself. - Rumi
*/
contract Honeycombs is IHoneycombs, HONEYCOMBS721 {
    /// @dev We use this database for persistent storage.
    Honeycombs honeycombs;

    uint256 public constant MAX_SUPPLY = 10000; // Maximum supply of Honeycombs
    uint256 public constant MINT_PRICE = 0.1 ether; // Price to mint one Honeycomb
    uint256 public constant MAX_MINT_PER_ADDRESS = 5; // Maximum NFTs per wallet address
    uint256 public constant AUTO_RESERVE_FREQUENCY = 100; // Frequency of auto-reserve
    address public reserveAddress1; // First address to auto reserve Honeycombs for
    address public reserveAddress2; // Second address to auto reserve Honeycombs for

    // Number of mints per address
    mapping(address => uint256) private _mintedCounts;

    /// @dev Initializes the Honeycombs contract.
    constructor() {
        honeycombs.day0 = uint32(block.timestamp);
        honeycombs.epoch = 1;
        reserveAddress1 = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;
        reserveAddress2 = 0x90F79bf6EB2c4f870365E785982E1f101E93b906;
    }

    /// @notice Mint honeycombs.
    /// @param numberOfTokens The number of tokens to mint.
    /// @param recipient The address to receive the tokens.
    function mint(uint256 numberOfTokens, address recipient) public payable {
        // Check whether mint is allowed.
        if (numberOfTokens < 1 || numberOfTokens > MAX_MINT_PER_ADDRESS) revert NotAllowed();
        if (honeycombs.minted + numberOfTokens > MAX_SUPPLY) revert MaxSupplyReached();
        if (msg.value != MINT_PRICE * numberOfTokens) revert NotExactEth();
        if (_mintedCounts[msg.sender] + numberOfTokens > MAX_MINT_PER_ADDRESS) revert MaxMintPerAddressReached();

        // Initialize new epoch / resolve previous epoch.
        resolveEpochIfNecessary();

        // Loop through and mint each Honeycomb.
        for (uint256 i = 0; i < numberOfTokens; ) {
            // Check for auto reserving honeycombs (first and second out of every 100).
            if (honeycombs.minted % AUTO_RESERVE_FREQUENCY == 0) {
                uint32 reserve1TokenId = ++honeycombs.minted;
                uint32 reserve2TokenId = ++honeycombs.minted;

                // Initialize Honeycombs.
                StoredHoneycomb storage honeycomb1 = honeycombs.all[reserve1TokenId];
                honeycomb1.day = Utilities.day(honeycombs.day0, block.timestamp);
                honeycomb1.epoch = uint32(honeycombs.epoch);
                honeycomb1.seed = uint16(reserve1TokenId);

                StoredHoneycomb storage honeycomb2 = honeycombs.all[reserve2TokenId];
                honeycomb2.day = Utilities.day(honeycombs.day0, block.timestamp);
                honeycomb2.epoch = uint32(honeycombs.epoch);
                honeycomb2.seed = uint16(reserve2TokenId);

                // Mint to reserve addresses.
                _safeMint(reserveAddress1, reserve1TokenId);
                _safeMint(reserveAddress2, reserve2TokenId);
            }

            // Increment minted counters.
            ++honeycombs.minted;
            ++_mintedCounts[msg.sender];

            // Initialize our Honeycomb.
            StoredHoneycomb storage honeycomb = honeycombs.all[honeycombs.minted];
            honeycomb.day = Utilities.day(honeycombs.day0, block.timestamp);
            honeycomb.epoch = uint32(honeycombs.epoch);
            honeycomb.seed = uint16(honeycombs.minted);

            // Mint the original.
            // If we're minting to a vault, transfer it there.
            if (msg.sender != recipient) {
                _safeMintVia(recipient, msg.sender, honeycombs.minted);
            } else {
                _safeMint(msg.sender, honeycombs.minted);
            }

            unchecked {
                ++i;
            }
        }
    }

    /// @notice Burn a honeycomb.
    /// @param tokenId The token ID to burn.
    /// @dev A common purpose burn method.
    function burn(uint256 tokenId) public {
        if (!_isApprovedOrOwner(msg.sender, tokenId)) {
            revert NotAllowed();
        }

        // Keep track of supply.
        unchecked {
            ++honeycombs.burned;
        }

        // Perform the burn.
        _burn(tokenId);
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

        return HoneycombsMetadata.tokenURI(honeycombs, tokenId);
    }

    /// @notice Returns how many tokens this contract manages.
    function totalSupply() public view returns (uint256) {
        return honeycombs.minted - honeycombs.burned;
    }

    /// @notice Returns how many tokens have been minted.
    function minted() public view returns (uint256) {
        return honeycombs.minted;
    }
}
