// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interfaces/IHoneycombs.sol";
import "./libraries/HoneycombsArt.sol";
import "./libraries/HoneycombsMetadata.sol";
import "./libraries/Utilities.sol";
import "./standards/HONEYCOMBS721.sol";

/**
@title  Honeycombs
@notice Lokah Samastah Sukhino Bhavantu
*/
contract Honeycombs is IHoneycombs, HONEYCOMBS721 {
    /// @notice The VV Honeycombs Edition contract.
    IHoneycombsEdition public editionHoneycombs;

    /// @dev We use this database for persistent storage.
    Honeycombs honeycombs;

    /// @dev Initializes the Honeycombs Originals contract and links the Edition contract.
    constructor() {
        editionHoneycombs = IHoneycombsEdition(0x34eEBEE6942d8Def3c125458D1a86e0A897fd6f9);
        honeycombs.day0 = uint32(block.timestamp);
        honeycombs.epoch = 1;
    }

    /// @notice Migrate Honeycombs Editions to Honeycombs Originals by burning the Editions.
    ///         Requires the Approval of this contract on the Edition contract.
    /// @param tokenIds The Edition token IDs you want to migrate.
    /// @param recipient The address to receive the tokens.
    function mint(uint256[] calldata tokenIds, address recipient) external {
        uint256 count = tokenIds.length;

        // Initialize new epoch / resolve previous epoch.
        resolveEpochIfNecessary();

        // Burn the Editions for the given tokenIds & mint the Originals.
        for (uint256 i; i < count; ) {
            uint256 id = tokenIds[i];
            address owner = editionHoneycombs.ownerOf(id);

            // Honeycomb whether we're allowed to migrate this Edition.
            if (
                owner != msg.sender &&
                (!editionHoneycombs.isApprovedForAll(owner, msg.sender)) &&
                editionHoneycombs.getApproved(id) != msg.sender
            ) {
                revert NotAllowed();
            }

            // Burn the Edition.
            editionHoneycombs.burn(id);

            // Initialize our Honeycomb.
            StoredHoneycomb storage honeycomb = honeycombs.all[id];
            honeycomb.day = Utilities.day(honeycombs.day0, block.timestamp);
            honeycomb.epoch = uint32(honeycombs.epoch);
            honeycomb.seed = uint16(id);
            honeycomb.divisorIndex = 0;

            // Mint the original.
            // If we're minting to a vault, transfer it there.
            if (msg.sender != recipient) {
                _safeMintVia(recipient, msg.sender, id);
            } else {
                _safeMint(msg.sender, id);
            }

            unchecked {
                ++i;
            }
        }

        // Keep track of how many honeycombs have been minted.
        unchecked {
            honeycombs.minted += uint32(count);
        }
    }

    /// @notice Get a specific honeycomb with its genome settings.
    /// @param tokenId The token ID to fetch.
    function getHoneycomb(uint256 tokenId) external view returns (Honeycomb memory honeycomb) {
        return HoneycombsArt.getHoneycomb(tokenId, honeycombs);
    }

    /// @notice Sacrifice a token to transfer its visual representation to another token.
    /// @param tokenId The token ID transfer the art into.
    /// @param burnId The token ID to sacrifice.
    function inItForTheArt(uint256 tokenId, uint256 burnId) external {
        _sacrifice(tokenId, burnId);

        unchecked {
            ++honeycombs.burned;
        }
    }

    /// @notice Sacrifice multiple tokens to transfer their visual to other tokens.
    /// @param tokenIds The token IDs to transfer the art into.
    /// @param burnIds The token IDs to sacrifice.
    function inItForTheArts(uint256[] calldata tokenIds, uint256[] calldata burnIds) external {
        uint256 pairs = _multiTokenOperation(tokenIds, burnIds);

        for (uint256 i; i < pairs; ) {
            _sacrifice(tokenIds[i], burnIds[i]);

            unchecked {
                ++i;
            }
        }

        unchecked {
            honeycombs.burned += uint32(pairs);
        }
    }

    /// @notice Composite one token into another. This mixes the visual and reduces the number of honeycombs.
    /// @param tokenId The token ID to keep alive. Its visual will change.
    /// @param burnId The token ID to composite into the tokenId.
    /// @param swap Swap the visuals before compositing.
    function composite(uint256 tokenId, uint256 burnId, bool swap) external {
        // Allow swapping the visuals before executing the composite.
        if (swap) {
            StoredHoneycomb memory toKeep = honeycombs.all[tokenId];

            honeycombs.all[tokenId] = honeycombs.all[burnId];
            honeycombs.all[burnId] = toKeep;
        }

        _composite(tokenId, burnId);

        unchecked {
            ++honeycombs.burned;
        }
    }

    /// @notice Composite multiple tokens. This mixes the visuals and honeycombs in remaining tokens.
    /// @param tokenIds The token IDs to keep alive. Their art will change.
    /// @param burnIds The token IDs to composite.
    function compositeMany(uint256[] calldata tokenIds, uint256[] calldata burnIds) external {
        uint256 pairs = _multiTokenOperation(tokenIds, burnIds);

        for (uint256 i; i < pairs; ) {
            _composite(tokenIds[i], burnIds[i]);

            unchecked {
                ++i;
            }
        }

        unchecked {
            honeycombs.burned += uint32(pairs);
        }
    }

    /// @notice Sacrifice 64 single-honeycomb tokens to form a black honeycomb.
    /// @param tokenIds The token IDs to burn for the black honeycomb.
    /// @dev The honeycomb at index 0 survives.
    function infinity(uint256[] calldata tokenIds) external {
        uint256 count = tokenIds.length;

        // Make sure we're allowed to mint the black honeycomb.
        if (count != 64) {
            revert InvalidTokenCount();
        }
        for (uint256 i; i < count; ) {
            uint256 id = tokenIds[i];
            if (honeycombs.all[id].divisorIndex != 6) {
                revert BlackHoneycomb__InvalidHoneycomb();
            }
            if (!_isApprovedOrOwner(msg.sender, id)) {
                revert NotAllowed();
            }

            unchecked {
                ++i;
            }
        }

        // Complete final composite.
        uint256 blackHoneycombId = tokenIds[0];
        StoredHoneycomb storage honeycomb = honeycombs.all[blackHoneycombId];
        honeycomb.day = Utilities.day(honeycombs.day0, block.timestamp);
        honeycomb.divisorIndex = 7;

        // Burn all 63 other Honeycombs.
        for (uint i = 1; i < count; ) {
            _burn(tokenIds[i]);

            unchecked {
                ++i;
            }
        }
        unchecked {
            honeycombs.burned += 63;
        }

        // When one is released from the prison of self, that is indeed freedom.
        // For the most great prison is the prison of self.
        emit Infinity(blackHoneycombId, tokenIds[1:]);
        emit MetadataUpdate(blackHoneycombId);
    }

    /// @notice Burn a honeycomb. Note: This burn does not composite or swap tokens.
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

            // Notify DAPPs about the new epoch.
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

    /// @notice Simulate a composite.
    /// @param tokenId The token to render.
    /// @param burnId The token to composite.
    function simulateComposite(uint256 tokenId, uint256 burnId) public view returns (Honeycomb memory honeycomb) {
        _requireMinted(tokenId);
        _requireMinted(burnId);

        // We want to simulate for the next divisor honeycomb count.
        uint8 index = honeycombs.all[tokenId].divisorIndex;
        uint8 nextDivisor = index + 1;
        honeycomb = HoneycombsArt.getHoneycomb(tokenId, nextDivisor, honeycombs);

        // Simulate composite tree
        honeycomb.stored.composites[index] = uint16(burnId);

        // Simulate visual composite in stored data if we have many honeycombs
        if (index < 5) {
            (uint8 gradient, uint8 colorBand) = _compositeGenes(tokenId, burnId);
            honeycomb.stored.colorBands[index] = colorBand;
            honeycomb.stored.gradients[index] = gradient;
        }

        // Simulate composite in memory data
        honeycomb.composite = !honeycomb.isRoot && index < 7 ? honeycomb.stored.composites[index] : 0;
        honeycomb.colorBand = HoneycombsArt.colorBandIndex(honeycomb, nextDivisor);
        honeycomb.gradient = HoneycombsArt.gradientIndex(honeycomb, nextDivisor);
    }

    /// @notice Render the SVG for a simulated composite.
    /// @param tokenId The token to render.
    /// @param burnId The token to composite.
    function simulateCompositeSVG(uint256 tokenId, uint256 burnId) external view returns (string memory) {
        return string(HoneycombsArt.generateSVG(simulateComposite(tokenId, burnId), honeycombs));
    }

    /// @notice Get the colors of all honeycombs in a given token.
    /// @param tokenId The token ID to get colors for.
    /// @dev Consider using the HoneycombsArt and EightyColors Libraries
    ///      in combination with the getHoneycomb function to resolve this yourself.
    function colors(uint256 tokenId) external view returns (string[] memory, uint256[] memory) {
        return HoneycombsArt.colors(HoneycombsArt.getHoneycomb(tokenId, honeycombs), honeycombs);
    }

    /// @notice Render the SVG for a given token.
    /// @param tokenId The token to render.
    /// @dev Consider using the HoneycombsArt Library directly.
    function svg(uint256 tokenId) external view returns (string memory) {
        return string(HoneycombsArt.generateSVG(HoneycombsArt.getHoneycomb(tokenId, honeycombs), honeycombs));
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

    /// @dev Sacrifice one token to transfer its art to another.
    /// @param tokenId The token ID to keep.
    /// @param burnId The token ID to burn.
    function _sacrifice(uint256 tokenId, uint256 burnId) internal {
        (, StoredHoneycomb storage toBurn, ) = _tokenOperation(tokenId, burnId);

        // Copy over static genome settings
        honeycombs.all[tokenId] = toBurn;

        // Update the birth date for this token.
        honeycombs.all[tokenId].day = Utilities.day(honeycombs.day0, block.timestamp);

        // Perform the burn.
        _burn(burnId);

        // Notify DAPPs about the Sacrifice.
        emit Sacrifice(burnId, tokenId);
        emit MetadataUpdate(tokenId);
    }

    /// @dev Composite one token into to another and burn it.
    /// @param tokenId The token ID to keep. Its art and honeycomb-count will change.
    /// @param burnId The token ID to burn in the process.
    function _composite(uint256 tokenId, uint256 burnId) internal {
        (StoredHoneycomb storage toKeep, , uint8 divisorIndex) = _tokenOperation(tokenId, burnId);

        uint8 nextDivisor = divisorIndex + 1;

        // We only need to breed band + gradient up until 4-Honeycombs.
        if (divisorIndex < 5) {
            (uint8 gradient, uint8 colorBand) = _compositeGenes(tokenId, burnId);

            toKeep.colorBands[divisorIndex] = colorBand;
            toKeep.gradients[divisorIndex] = gradient;
        }

        // Composite our honeycomb
        toKeep.day = Utilities.day(honeycombs.day0, block.timestamp);
        toKeep.composites[divisorIndex] = uint16(burnId);
        toKeep.divisorIndex = nextDivisor;

        // Perform the burn.
        _burn(burnId);

        // Notify DAPPs about the Composite.
        emit Composite(tokenId, burnId, HoneycombsArt.DIVISORS()[toKeep.divisorIndex]);
        emit MetadataUpdate(tokenId);
    }

    /// @dev Composite the gradient and colorBand settings.
    /// @param tokenId The token ID to keep.
    /// @param burnId The token ID to burn.
    function _compositeGenes(uint256 tokenId, uint256 burnId) internal view returns (uint8 gradient, uint8 colorBand) {
        Honeycomb memory keeper = HoneycombsArt.getHoneycomb(tokenId, honeycombs);
        Honeycomb memory burner = HoneycombsArt.getHoneycomb(burnId, honeycombs);

        // Pseudorandom gene manipulation.
        uint256 randomizer = uint256(keccak256(abi.encodePacked(keeper.seed, burner.seed)));

        // If at least one token has a gradient, we force it in ~20% of cases.
        gradient = Utilities.random(randomizer, 100) > 80
            ? randomizer % 2 == 0
                ? Utilities.minGt0(keeper.gradient, burner.gradient)
                : Utilities.max(keeper.gradient, burner.gradient)
            : Utilities.min(keeper.gradient, burner.gradient);

        // We breed the lower end average color band when breeding.
        colorBand = Utilities.avg(keeper.colorBand, burner.colorBand);
    }

    /// @dev Make sure this is a valid request to composite/switch with multiple tokens.
    /// @param tokenIds The token IDs to keep.
    /// @param burnIds The token IDs to burn.
    function _multiTokenOperation(
        uint256[] calldata tokenIds,
        uint256[] calldata burnIds
    ) internal pure returns (uint256 pairs) {
        pairs = tokenIds.length;
        if (pairs != burnIds.length) {
            revert InvalidTokenCount();
        }
    }

    /// @dev Make sure this is a valid request to composite/switch a token pair.
    /// @param tokenId The token ID to keep.
    /// @param burnId The token ID to burn.
    function _tokenOperation(
        uint256 tokenId,
        uint256 burnId
    ) internal view returns (StoredHoneycomb storage toKeep, StoredHoneycomb storage toBurn, uint8 divisorIndex) {
        toKeep = honeycombs.all[tokenId];
        toBurn = honeycombs.all[burnId];
        divisorIndex = toKeep.divisorIndex;

        if (
            !_isApprovedOrOwner(msg.sender, tokenId) ||
            !_isApprovedOrOwner(msg.sender, burnId) ||
            divisorIndex != toBurn.divisorIndex ||
            tokenId == burnId ||
            divisorIndex > 5
        ) {
            revert NotAllowed();
        }
    }
}
