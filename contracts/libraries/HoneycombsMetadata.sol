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
    function tokenURI(
        uint256 tokenId, IHoneycombs.Honeycombs storage honeycombs
    ) public view returns (string memory) {
        IHoneycombs.Honeycomb memory honeycomb = HoneycombsArt.getHoneycomb(tokenId, honeycombs);

        bytes memory svg = HoneycombsArt.generateSVG(honeycomb, honeycombs);

        bytes memory metadata = abi.encodePacked(
            '{',
                '"name": "Honeycombs ', Utilities.uint2str(tokenId), '",',
                '"description": "Lokah Samastah Sukhino Bhavantu",',
                '"image": ',
                    '"data:image/svg+xml;base64,',
                    Base64.encode(svg),
                    '",',
                '"animation_url": ',
                    '"data:text/html;base64,',
                    Base64.encode(generateHTML(tokenId, svg)),
                    '",',
                '"attributes": [', attributes(honeycomb), ']',
            '}'
        );

        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(metadata)
            )
        );
    }

    /// @dev Render the JSON atributes for a given Honeycombs token.
    /// @param honeycomb The honeycomb to render.
    function attributes(IHoneycombs.Honeycomb memory honeycomb) public pure returns (bytes memory) {
        bool showVisualAttributes = honeycomb.isRevealed && honeycomb.hasManyHoneycombs;
        bool showAnimationAttributes = honeycomb.isRevealed && honeycomb.honeycombsCount > 0;

        return abi.encodePacked(
            showVisualAttributes
                ? trait('Color Band', colorBand(HoneycombsArt.colorBandIndex(honeycomb, honeycomb.stored.divisorIndex)), ',')
                : '',
            showVisualAttributes
                ? trait('Gradient', gradients(HoneycombsArt.gradientIndex(honeycomb, honeycomb.stored.divisorIndex)), ',')
                : '',
            showAnimationAttributes
                ? trait('Speed', honeycomb.speed == 4 ? '2x' : honeycomb.speed == 2 ? '1x' : '0.5x', ',')
                : '',
            showAnimationAttributes
                ? trait('Shift', honeycomb.direction == 0 ? 'IR' : 'UV', ',')
                : '',
            honeycomb.isRevealed == false
                ? trait('Revealed', 'No', ',')
                : '',
            trait('Honeycombs', Utilities.uint2str(honeycomb.honeycombsCount), ','),
            trait('Day', Utilities.uint2str(honeycomb.stored.day), '')
        );
    }

    /// @dev Get the names for different gradients. Compare HoneycombsArt.GRADIENTS.
    /// @param gradientIndex The index of the gradient.
    function gradients(uint8 gradientIndex) public pure returns (string memory) {
        return [
            'None', 'Linear', 'Double Linear', 'Reflected', 'Double Angled', 'Angled', 'Linear Z'
        ][gradientIndex];
    }

    /// @dev Get the percentage values for different color bands. Compare HoneycombsArt.COLOR_BANDS.
    /// @param bandIndex The index of the color band.
    function colorBand(uint8 bandIndex) public pure returns (string memory) {
        return [
            'Eighty', 'Sixty', 'Forty', 'Twenty', 'Ten', 'Five', 'One'
        ][bandIndex];
    }

    /// @dev Generate the SVG snipped for a single attribute.
    /// @param traitType The `trait_type` for this trait.
    /// @param traitValue The `value` for this trait.
    /// @param append Helper to append a comma.
    function trait(
        string memory traitType, string memory traitValue, string memory append
    ) public pure returns (string memory) {
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
        return abi.encodePacked(
            '<!DOCTYPE html>',
            '<html lang="en">',
            '<head>',
                '<meta charset="UTF-8">',
                '<meta http-equiv="X-UA-Compatible" content="IE=edge">',
                '<meta name="viewport" content="width=device-width, initial-scale=1.0">',
                '<title>Honeycomb #', Utilities.uint2str(tokenId), '</title>',
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
