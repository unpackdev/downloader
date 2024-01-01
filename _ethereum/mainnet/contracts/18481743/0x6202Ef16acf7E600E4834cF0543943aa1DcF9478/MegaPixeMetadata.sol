// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Strings.sol";
import "./Base64.sol";
import "./Ownable.sol";
import "./MegaPixeNFT.sol";

contract MegaPixeMetadata is MetadataInterface, Ownable {
    using Strings for uint256;

    uint256[8] public oneOfOneIds = [456, 2239, 3988, 2503, 848, 1290, 3221, 583];
    string public ordinalsGateway = "https://ordinals-ws.gamma.io/";

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

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        string memory typeName = isOneOfOne(tokenId) ? "One of One" : "Generative";
        string memory imageURI = string(abi.encodePacked(
            ordinalsGateway,
            "content/7b995eeab27c9fdf2f65193802667fc574082dcd7dbd7bc9139b3ccb52caa2edi0?id=",
            tokenId.toString()
        ));

        string memory metadata = string(abi.encodePacked(
            '{"name":"MegaPixe #',
            tokenId.toString(),
            '", "animation_url":"',
            imageURI,
            '", "attributes": [{"trait_type": "Type", "value":"',
            typeName,
            '"}]}'
        ));

        return string(abi.encodePacked(
            'data:application/json;base64,',
            Base64.encode(bytes(metadata))
        ));
    }
}
