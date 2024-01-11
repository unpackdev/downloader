//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./ERC1155Upgradeable.sol";
import "./AdminableUpgradeable.sol";

abstract contract ERC1155OnChainBaseUpgradeable is Initializable, AdminableUpgradeable, ERC1155Upgradeable {

    // struct to store each trait's data for metadata and rendering
    struct Image {
        string name;
        string png;
    }

    // storage of each image data
    mapping(uint256  => Image) public traitData;

    function __ERC1155OnChainBase_init() internal initializer {
        // Empty because it's generated onchain
        ERC1155Upgradeable.__ERC1155_init("");
    }

    function uploadImage(uint256 typeId, Image calldata image) external onlyAdminOrOwner {
        traitData[typeId] = Image(
            image.name,
            image.png
        );
    }

    function _drawImage(Image memory image) internal pure returns (string memory) {
        return string(abi.encodePacked(
            '<image x="4" y="4" width="32" height="32" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,',
            image.png,
            '"/>'
        ));
    }

    function _drawSVG(uint256 typeId) internal view returns (string memory) {
        string memory svgString = string(abi.encodePacked(
            _drawImage(traitData[typeId])
        ));

        return string(abi.encodePacked(
            '<svg id="imageRender" width="100%" height="100%" version="1.1" viewBox="0 0 40 40" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
            svgString,
            "</svg>"
        ));
    }

    uint256[50] private __gap;
}