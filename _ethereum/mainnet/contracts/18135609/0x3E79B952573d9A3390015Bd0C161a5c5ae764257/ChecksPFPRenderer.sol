// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Base64.sol";

import "./IChecks.sol";
import "./IRenderer.sol";
import "./Utilities.sol";

contract ChecksPFPRenderer is IRenderer {

    IChecks checks = IChecks(0x036721e5A769Cc48B3189EFbb9ccE4471E8A48B1);

    /// @dev Render the metadata for the token.
    /// @param tokenId The token to render.
    /// @param owner The current owner of the token.
    function tokenURI(uint256 tokenId, address owner) public view returns (string memory) {
        bool linked = checks.ownerOf(tokenId) == owner;

        return string.concat(
            "data:application/json;base64,",
            Base64.encode(abi.encodePacked(renderMetadata(tokenId, linked)))
        );
    }

    /// @dev Render the SVG.
    /// @param tokenId The token to render.
    function svg(uint256 tokenId) public view returns (string memory) {
        (string[] memory colors, uint256[] memory colorIndexes) = checks.colors(tokenId);
        uint256 count = colors.length;
        bool isBlackCheck = colorIndexes[0] == 999;

        return string.concat(
            '<svg ',
                'viewBox="0 0 608 608" ',
                'fill="none" xmlns="http://www.w3.org/2000/svg" ',
                'style="width:100vw;height:100vh;background:#808080;margin:auto;"',
            '>',
                renderBackground(count, colors, isBlackCheck),
                renderChecks(count, isBlackCheck),
                renderDefs(tokenId),
            '</svg>'
        );
    }

    /// @dev Render the JSON token metadata.
    /// @param tokenId The token to render.
    /// @param linked Whether the token is linked.
    function renderMetadata(uint256 tokenId, bool linked) private view returns (string memory) {
        string memory id = Utilities.uint2str(tokenId);

        string memory img = string.concat('"data:image/svg+xml;base64,', Base64.encode(abi.encodePacked(svg(tokenId))));
        string memory description = linked
            ? string.concat('PFP mirroring VV Checks #',id)
            : string.concat('PFP for VV Checks #',id,'. Relink to its current owner on the VV Checks website.');

        return string.concat(
            '{',
                '"name": "Checks PFP #',id,'",',
                '"description": "',description,'",',
                '"image": "https://api.checks.art/checks/',id,'/pfp.png",',
                '"svg": ',img,'",',
                '"animation_url": ',img,'",',
                '"attributes": [', attributes(linked), ']',
            '}'
        );
    }

    /// @dev Render the background of the SVG.
    /// @param count Number of checks in the token.
    /// @param colors The colors of the checks token.
    /// @param isBlackCheck Whether this token is a black check.
    function renderBackground(
        uint256 count, string[] memory colors, bool isBlackCheck
    ) private pure returns (string memory) {
        string memory color = isBlackCheck
            ? '000'
            : count > 10
                ? '000'
                : count > 1
                    ? 'ebebeb'
                    : colors[0];

        return string.concat('<rect x="0" y="0" width="608" height="608" fill="#',color,'" />');
    }

    /// @dev Render the pfp body.
    /// @param count Number of checks in the token.
    /// @param isBlackCheck Whether this token is a black check.
    function renderChecks(uint256 count, bool isBlackCheck) private pure returns (string memory) {
        string memory color = isBlackCheck ? 'fff' : '111';

        return string.concat(
            '<rect x="152" y="152" width="304" height="304" fill="#',color,'" />',
            '<rect x="152" y="520" width="304" height="88" fill="#',color,'" />',
            '<mask id="head">',
                count < 5
                    ? '<rect x="195" y="195.5" width="290" height="289" fill="white" />'
                    : '<rect x="195" y="159" width="290" height="289.5" fill="white" />',
            '</mask>',

            '<mask id="torso">',
                '<rect x="195" y="447.5" width="290" height="73" fill="white" />',
            '</mask>',

            '<g mask="url(#head)" transform="translate(-36,', count < 5 ? '-36' : '0' ,')">',
                '<use href="#token" />',
            '</g>',

            '<g mask="url(#torso)" transform="translate(-36,80)">',
                '<use href="#token" />',
            '</g>'
        );
    }

    /// @dev Render the <defs> section of the SVG.
    /// @param tokenId The check to render.
    function renderDefs(uint256 tokenId) private view returns (string memory) {
        return string.concat(
            '<defs>',
                '<g id="token">',
                    '<svg viewBox="0 0 680 680" width="680" height="680" style="pointer-events:none;">',
                        checks.svg(tokenId),
                    '</svg>',
                '</g>',
            '</defs>'
        );
    }

    /// @dev Render the JSON attributes for a Checks PFP.
    /// @param linked Whether the token is owned by the same address as its check.
    function attributes(bool linked) private pure returns (string memory) {
        return string.concat(
            trait('Status', linked ? 'Linked' : 'Unlinked', '')
        );
    }

    /// @dev Generate the JSON snippet for a single attribute.
    /// @param traitType The `trait_type` for this trait.
    /// @param traitValue The `value` for this trait.
    /// @param append Helper to append a comma.
    function trait(
        string memory traitType, string memory traitValue, string memory append
    ) private pure returns (string memory) {
        return string(abi.encodePacked(
            '{',
                '"trait_type": "', traitType, '",'
                '"value": "', traitValue, '"'
            '}',
            append
        ));
    }

}
