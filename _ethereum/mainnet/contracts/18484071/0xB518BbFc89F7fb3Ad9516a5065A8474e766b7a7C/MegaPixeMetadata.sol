// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Strings.sol";
import "./Base64.sol";
import "./Ownable.sol";
import "./MegaPixeNFT.sol";

contract MegaPixeMetadata is MetadataInterface, Ownable {
    using Strings for uint256;

    uint256[8] public oneOfOneIds = [456, 2239, 3988, 2503, 848, 1290, 3221, 583];
    string public ordinalsGateway = "https://ordinals-ws.gamma.io/content/";
    string public imageGateway = "https://storage.googleapis.com/megapixe-art/";
    string public builderInscription = "9f3938dbfeb6723c869e7de33ab5c0b79ab6c9e2ac7cdb49f0e652862a892286i0";

    constructor() Ownable(msg.sender) {}

    function isOneOfOne(uint256 tokenId) internal view returns (bool) {
        for (uint256 i = 0; i < oneOfOneIds.length; i++) {
            if (oneOfOneIds[i] == tokenId) {
                return true;
            }
        }
        return false;
    }

    function setOrdinalsGateway(string memory newGateway) external onlyOwner {
        ordinalsGateway = newGateway;
    }

    function setImageGateway(string memory newGateway) external onlyOwner {
        imageGateway = newGateway;
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        string memory typeName = isOneOfOne(tokenId) ? "One of One" : "Generative";
        string memory animationURI =
            string(abi.encodePacked(ordinalsGateway, builderInscription, "?id=", tokenId.toString()));
        string memory imageURI = string(abi.encodePacked(imageGateway, tokenId.toString(), ".png"));

        string memory metadata = string(
            abi.encodePacked(
                '{"name":"MegaPixe #',
                tokenId.toString(),
                '", "image":"',
                imageURI,
                '", "animation_url":"',
                animationURI,
                '", "attributes": [{"trait_type": "Type", "value":"',
                typeName,
                '"}]}'
            )
        );

        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(metadata))));
    }
}
