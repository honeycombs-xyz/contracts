//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Base64.sol";

import "./HoneycombsArt.sol";
import "../interfaces/IHoneycombs.sol";
import "./Utilities.sol";

/**
@title  HoneycombsMetadata
@notice Renders ERC721 compatible metadata for Honeycombs.
*/
library HoneycombsMetadata {
    /// @dev Render the JSON Metadata for a given Honeycombs token.
    /// @param tokenId The id of the token to render.
    /// @param honeycombs The DB containing all honeycombs.
    function tokenURI(uint256 tokenId, IHoneycombs.Honeycombs storage honeycombs) public view returns (string memory) {
        bytes memory data = HoneycombsArt.generateHoneycomb(honeycombs, tokenId);

        // prettier-ignore
        bytes memory metadata = abi.encodePacked(
            '{',
                '"name": "Honeycombs ', Utilities.uint2str(tokenId), '",',
                '"description": "Lokah Samastah Sukhino Bhavantu",',
                '"image": ',
                    '"data:image/svg+xml;base64,',
                    Base64.encode(data.svg),
                    '",',
                '"animation_url": ',
                    '"data:text/html;base64,',
                    Base64.encode(generateHTML(tokenId, data.svg)),
                    '",',
                '"attributes": [', attributes(data), ']',
            '}'
        );

        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(metadata)));
    }

    /// @dev Render the JSON atributes for a given Honeycombs token.
    /// @param honeycomb The honeycomb to render.
    function attributes(IHoneycombs.Honeycomb memory honeycomb) public pure returns (bytes memory) {
        bool showVisualAttributes = honeycomb.isRevealed && honeycomb.hasManyHoneycombs;

        return
            abi.encodePacked(
                showVisualAttributes ? trait("Canvas Color", honeycomb.canvas.color, ",") : "",
                showVisualAttributes
                    ? trait("Base Hexagon", honeycomb.baseHexagon.hexagonType == 0 ? "Flat Top" : "Pointy Top", ",")
                    : "",
                showVisualAttributes ? trait("Base Hexagon Fill Color", honeycomb.baseHexagon.fillColor, ",") : "",
                showVisualAttributes ? trait("Stroke Width", honeycomb.baseHexagon.strokeWidth, ",") : "",
                showVisualAttributes ? trait("Shape", shapes(honeycomb.grid.shape), ",") : "",
                showVisualAttributes ? trait("Rows", honeycomb.grid.rows, ",") : "",
                showVisualAttributes ? trait("Rotation", honeycomb.grid.rotation, ",") : "",
                showVisualAttributes ? trait("Chrome", chromes(honeycomb.gradients.chrome), ",") : "",
                showVisualAttributes ? trait("Duration", durations(honeycomb.duration), ",") : "",
                showVisualAttributes ? trait("Direction", honeycomb.direction == 0 ? "Forward" : "Reverse", ",") : "",
                honeycomb.isRevealed == false ? trait("Revealed", "No", ",") : "",
                trait("Day", Utilities.uint2str(honeycomb.stored.day), "")
            );
    }

    /// @dev Get the names for different shapes. Compare HoneycombsArt.getShape().
    /// @param shapeIndex The index of the shape.
    function shapes(uint8 shapeIndex) public pure returns (string memory) {
        return ["Triangle", "Diamond", "Hexagon", "Random"][shapeIndex];
    }

    /// @dev Get the names for different chromes (max colors). Compare HoneycombsArt.getChrome().
    /// @param chromeIndex The index of the chrome.
    function chromes(uint8 chromeIndex) public pure returns (string memory) {
        return ["Monochrome", "Dichrome", "Trichrome", "Tetrachrome", "Pentachrome", "Hexachrome", "Many"][chromeIndex];
    }

    /// @dev Get the names for different durations. Compare HoneycombsArt.getDuration().
    /// @param durationIndex The index of the duration.
    function durations(uint8 durationIndex) public pure returns (string memory) {
        return ["Rave", "Normal", "Soothing", "Meditative"][durationIndex];
    }

    /// @dev Generate the SVG snipped for a single attribute.
    /// @param traitType The `trait_type` for this trait.
    /// @param traitValue The `value` for this trait.
    /// @param append Helper to append a comma.
    function trait(
        string memory traitType,
        string memory traitValue,
        string memory append
    ) public pure returns (string memory) {
        // prettier-ignore
        return string(abi.encodePacked(
            '{',
                '"trait_type": "', traitType, '",'
                '"value": "', traitValue, '"'
            '}',
            append
        ));
    }

    /// @dev Generate the HTML for the animation_url in the metadata.
    /// @param tokenId The id of the token to generate the embed for.
    /// @param svg The rendered SVG code to embed in the HTML.
    function generateHTML(uint256 tokenId, bytes memory svg) public pure returns (bytes memory) {
        // prettier-ignore
        return abi.encodePacked(
            '<!DOCTYPE html>',
            '<html lang="en">',
            '<head>',
                '<meta charset="UTF-8">',
                '<meta http-equiv="X-UA-Compatible" content="IE=edge">',
                '<meta name="viewport" content="width=device-width, initial-scale=1.0">',
                '<title>Check #', Utilities.uint2str(tokenId), '</title>',
                '<style>',
                    'html,',
                    'body {',
                        'margin: 0;',
                        'background: #EFEFEF;',
                        'overflow: hidden;',
                    '}',
                    'svg {',
                        'max-width: 100vw;',
                        'max-height: 100vh;',
                    '}',
                '</style>',
            '</head>',
            '<body>',
                svg,
            '</body>',
            '</html>'
        );
    }
}
