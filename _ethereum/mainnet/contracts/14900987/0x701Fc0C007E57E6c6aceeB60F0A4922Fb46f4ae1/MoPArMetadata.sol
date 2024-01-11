// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./Base64.sol";

interface IMoPArMetadata {
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function beforeTokenTransfer(address from, address to, uint256 tokenId) external;
}

interface IMoPAr {
    struct Collection {
        string name;
        string artist;
        uint128 circulating;
        uint128 max;
        uint256 price;
        address payable artistWallet;
        uint128 artistMintBasis; //in basis points (ie 5.0% = 500)
        address royaltyWallet;
        uint128 royaltyBasis; //in basis points (ie 5.0% = 500)
        address customContract;
        bool mixedOnOffChain;
    }
    function getCollectionId(uint256 tokenId) external view returns (uint256);
    function getName(uint256 tokenId) external view returns (string memory);
    function getDescription(uint256 tokenId) external view returns (string memory);
    function getImage(uint256 tokenId) external view returns (string memory);
    function getAttributes(uint256 tokenId, uint256 index) external view returns (string memory);
    function getCollection(uint256 collectionId) external view returns (bool, Collection memory);
    function getSignature(uint256 tokenId) external view returns (bytes32);
}

contract MoPArMetadata is Ownable, IMoPArMetadata {
    IMoPAr private mopar;

    string private _uriPrefix;             // uri prefix
    string private _baseURI;
    string[] public metadataKeys;

    constructor(string memory initURIPrefix_, string memory initBaseURI_, address moparAddress_)
    Ownable() 
    {
        _uriPrefix = initURIPrefix_;
        _baseURI = initBaseURI_;
        mopar = IMoPAr(moparAddress_);
        metadataKeys = [
            "Date",
            "Type Of Art",
            "Format",
            "Medium",
            "Colour",
            "Location",
            "Distinguishing Attributes",
            "Dimensions",
            "On-Chain"
        ];
    }

    function tokenURI(uint256 tokenId) override external view returns (string memory) {
        bytes32 signature = mopar.getSignature(tokenId); //Index hardcoded for on-chain
        if (signature != 0) {
            ( , IMoPAr.Collection memory collection) = mopar.getCollection(mopar.getCollectionId(tokenId));
            string memory json;
            json = string(abi.encodePacked(json, '{\n '));
            json = string(abi.encodePacked(json, '"platform": "Museum of Permuted Art",\n '));
            json = string(abi.encodePacked(json, '"name": "' , mopar.getName(tokenId) , '",\n '));
            json = string(abi.encodePacked(json, '"artist": "' , collection.artist , '",\n '));
            json = string(abi.encodePacked(json, '"collection": "' , collection.name , '",\n '));
            json = string(abi.encodePacked(json, '"description": "' , mopar.getDescription(tokenId) , '",\n '));
            json = string(abi.encodePacked(json, '"image": "' , _uriPrefix, mopar.getImage(tokenId) , '",\n '));
            json = string(abi.encodePacked(json, '"external_url": "https://permuted.xyz",\n '));
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
            json = string(abi.encodePacked(json, ',{"trait_type": "On-Chain", "value": "true"}\n\t'));
            json = string(abi.encodePacked(json, ']\n}'));
            return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
        } else {
            return string(abi.encodePacked(_baseURI, _toString(tokenId), ".json"));
        }
    }

    function setURIPrefix(string calldata newURIPrefix) external onlyOwner {
        _uriPrefix = newURIPrefix;
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        _baseURI = newBaseURI;
    }

    function setMetadataKeys(string[] memory metadataKeys_) external onlyOwner {
        require(metadataKeys_.length <=20, "TOO_MANY_METADATA_KEYS");
        metadataKeys = metadataKeys_;
    }

    function beforeTokenTransfer(address from, address to, uint256 tokenId) override external {}
    
    function _toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    } 

}
