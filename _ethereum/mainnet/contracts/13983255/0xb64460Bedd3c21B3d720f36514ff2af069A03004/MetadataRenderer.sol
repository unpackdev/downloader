// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./Strings.sol";
import "./IMetadataRenderer.sol";
import "./Base64.sol";

contract MetadataRenderer is IMetadataRenderer {
    string public constant DESCRIPTION = "Synesthesia is a collaborative NFT art project in partnership with well-known generative artist @Hyperglu. Synesthesia enables users to use their Color NFTs to participant in the creation of new generative artworks.";
    string public constant UNREVEAL_IMAGE_URL = "https://www.synesspace.com/synesspace-unreveal.svg";

    function renderInternal(
        bytes memory tokenName,
        bytes memory imageURL,
        bytes memory attributes
    ) internal pure returns (string memory) {
        return string(abi.encodePacked(
            "data:application/json;base64,",
            Base64.encode(abi.encodePacked(
                '{"name":"', tokenName, '",',
                '"description":"', DESCRIPTION, '",',
                '"image":"', imageURL, '",',
                '"attributes":[', attributes, ']}'))));
    }

    function renderUnreveal(uint16 tokenId) external pure returns (string memory) {
        return renderInternal(
            abi.encodePacked("Synesthesia #", Strings.toString(tokenId)),
            bytes(UNREVEAL_IMAGE_URL),
            "");
    }

    function render(uint16 tokenId, Color memory color) external pure returns (string memory) {
        bytes memory svg = abi.encodePacked(
            "data:image/svg+xml;base64,",
            Base64.encode(abi.encodePacked(
                "<svg version='1.1' xmlns='http://www.w3.org/2000/svg' width='512' height='512'><rect x='0' y='0' width='512' height='512' style='fill:#",
                color.rgb,
                "'/><rect x='0' y='376' width='512' height='50' style='fill:#FFFFFF;'/><text x='26' y='413' class='name-label' style='fill:#231815;font-family:Arial;font-weight:bold;font-size:32px;'>",
                color.name,
                "</text><text x='370' y='411' class='color-label' style='fill:#898989;font-family:Arial;font-weight:bold;font-style:italic;font-size: 28px;'>#",
                color.rgb,
                "</text></svg>")));

        bytes memory attributes = abi.encodePacked('{"trait_type":"Name","value":"', color.name, '"},{"trait_type":"RGB","value":"#', color.rgb, '"}');

        return renderInternal(
            abi.encodePacked(color.name, ' #', Strings.toString(tokenId)),
            svg,
            attributes);
    }
}