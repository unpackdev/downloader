// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./Base64.sol";

interface IMoPArMetadata {
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function beforeTokenTransfer(address from, address to, uint256 tokenId) external;
}

interface IMoPAr {
    function getCollectionId(uint256 tokenId) external view returns (uint256);
}

contract MoPAr_RitesOfPassage is Ownable, IMoPArMetadata {
    IMoPAr private mopar;

    string private _uriPrefix;             // uri prefix
    string private _baseURI;
    uint256[10] public lotTimestamps;
    uint256 private constant SEPARATOR = 10**4;
    uint16 public collectionId;

    constructor(string memory initURIPrefix_, string memory initBaseURI_, address moparAddress_)
    Ownable() 
    {
        _uriPrefix = initURIPrefix_;
        _baseURI = initBaseURI_;
        mopar = IMoPAr(moparAddress_);
    }

    function tokenURI(uint256 tokenId) override external view returns (string memory) {
        if (lotTimestamps[tokenId - SEPARATOR * collectionId] != 0) {
            for (uint i = 6; i >= 0; i--) {
                if (block.timestamp >= lotTimestamps[tokenId - SEPARATOR * collectionId] + i*30 days) {
                    return string(abi.encodePacked(_baseURI, _toString(tokenId), "-state", _toString(i), ".json"));
                }
            }
            return string(abi.encodePacked(_baseURI, _toString(tokenId), "-state0.json"));
        } else {
            return string(abi.encodePacked(_baseURI, _toString(tokenId), "-state1.json"));
        }
    }

    function beforeTokenTransfer(address, address, uint256 tokenId) override external {
        require(collectionId > 0, "Custom Renderer: Collection ID must be set");
        lotTimestamps[tokenId - SEPARATOR * collectionId] = block.timestamp;
    }

    function setURIPrefix(string calldata newURIPrefix) external onlyOwner {
        _uriPrefix = newURIPrefix;
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        _baseURI = newBaseURI;
    }

    function setCollectionId(uint16 newCollectionId_) external onlyOwner {
        collectionId = newCollectionId_;
    }

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
