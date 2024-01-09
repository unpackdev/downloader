// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./Base64.sol";

interface IMoPArMetadata {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

interface IMoPAr {
    function getCollectionId(uint256 tokenId) external view returns (uint256);
    function getName(uint256 tokenId) external view returns (string memory);
    function getDescription(uint256 tokenId) external view returns (string memory);
    function getImage(uint256 tokenId) external view returns (string memory);
    function getAttributes(uint256 tokenId, uint256 index) external view returns (string memory);
    function getCollection(uint256 collectionId) external view returns (bool exists, string memory name, string memory artist, bool paused, uint128 max, uint128 circulating);
}

contract MoPArMetadata is Ownable, IMoPArMetadata {
    IMoPAr private mopar;

    string private _uriPrefix;             // uri prefix
    string[] public metadataKeys;

    constructor(string memory initURIPrefix_, address moparAddress_)
    Ownable() 
    {
        _uriPrefix = initURIPrefix_;
        mopar = IMoPAr(moparAddress_);
        metadataKeys = [
            "Date",
            "Type Of Art",
            "Format",
            "Medium",
            "Colour",
            "Location",
            "Distinguishing Attributes",
            "Dimensions"
        ];
    }

    function tokenURI(uint256 tokenId) override external view returns (string memory) {

        (, string memory collectionName, string memory collectionArtist, , , ) = mopar.getCollection(mopar.getCollectionId(tokenId));
        string memory json;
        json = string(abi.encodePacked(json, '{\n '));
        json = string(abi.encodePacked(json, '"platform": "Museum of Permuted Art",\n '));
        json = string(abi.encodePacked(json, '"name": "' , mopar.getName(tokenId) , '",\n '));
        json = string(abi.encodePacked(json, '"artist": "' , collectionArtist , '",\n '));
        json = string(abi.encodePacked(json, '"collection": "' , collectionName , '",\n '));
        json = string(abi.encodePacked(json, '"description": "' , mopar.getDescription(tokenId) , '",\n '));
        json = string(abi.encodePacked(json, '"image": "' , _uriPrefix, mopar.getImage(tokenId) , '",\n '));
        json = string(abi.encodePacked(json, '"external_url": "https://permuted.xyz",\n '));  //image
        json = string(abi.encodePacked(json, '"attributes": [\n\t'));
        for (uint8 i=0; i<metadataKeys.length; i++) {
            string memory metadataValue = mopar.getAttributes(tokenId,i);
            if (bytes(metadataValue).length > 0) {
                if (i != 0) {
                    json = string(abi.encodePacked(json, ',')); 
                }
                json = string(abi.encodePacked(json, '{"trait_type": "', metadataKeys[i], '", "value": "', metadataValue, '"}\n\t'));
            }
        }
        json = string(abi.encodePacked(json, ']\n}'));
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
    }

    function setURIPrefix(string calldata newURIPrefix) external onlyOwner {
        _uriPrefix = newURIPrefix;
    }

    function setMetadataKeys(string[] memory metadataKeys_) external onlyOwner {
        require(metadataKeys_.length <=20, "TOO_MANY_METADATA_KEYS");
        metadataKeys = metadataKeys_;
    }

}
