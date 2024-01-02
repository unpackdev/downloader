// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./IERC721.sol";
import "./LibString.sol";
import "./Base64.sol";
import "./LeetFont.sol";

contract LeetCollectiveRenderer {
    address private _font;
    address private _skulls;

    constructor(address font, address skulls) {
        _font = font;
        _skulls = skulls;
    }

    function render(
        address owner,
        string memory name,
        string memory bio,
        string memory color,
        string memory role,
        uint256 skull
    ) external view returns (string memory metadata) {
        uint256 skullCount = IERC721(_skulls).balanceOf(owner);
        bytes memory attributes = abi.encodePacked(_buildMetadata("name", name), ",");
        if (skull >= 0) {
            attributes = abi.encodePacked(attributes, _buildMetadata("skull", LibString.toString(skull)), ",");
        }
        attributes = abi.encodePacked(attributes, _buildMetadata("skulls owned", LibString.toString(skullCount)), ",");
        attributes = abi.encodePacked(attributes, _buildMetadata("role", role));
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "',
                        name,
                        '", "description": "',
                        bio,
                        '","image_url": "data:image/svg+xml;base64,',
                        _buildImage(name, color, role),
                        '","attributes": [',
                        attributes,
                        "]}"
                    )
                )
            )
        );
        metadata = string(abi.encodePacked("data:application/json;base64,", json));
    }

    function _buildMetadata(string memory key, string memory value) internal pure returns (string memory trait) {
        return string.concat('{"trait_type":"', key, '","value": "', value, '"}');
    }

    function _buildImage(string memory name, string memory color, string memory role)
        internal
        view
        returns (string memory image)
    {
        bytes memory imageData = abi.encodePacked(
            '<svg id="art" width="400" height="400" viewBox="0 0 400 400" xmlns="http://www.w3.org/2000/svg">',
            "<style>",
            "@font-face { font-family: leetFont; src: url(",
            LeetFont(_font).getFontURI(),
            "); }",
            "#art { background-color: #000000;}",
            "text { font-family: leetFont; font-size: 16px; fill: ",
            color,
            "; }",
            "</style>"
        );

        imageData = abi.encodePacked(
            imageData,
            '<text x="90%" y="10%" text-anchor="middle">&#xE001;</text>',
            '<text x="90%" y="17%" text-anchor="middle">&#xE002;</text>',
            '<text x="50%" y="50%" text-anchor="middle">',
            name,
            "</text>",
            '<text x="5%" y="90%"  text-anchor="start">[',
            role,
            "]</text>",
            "</svg>"
        );

        return Base64.encode(imageData);
    }
}
