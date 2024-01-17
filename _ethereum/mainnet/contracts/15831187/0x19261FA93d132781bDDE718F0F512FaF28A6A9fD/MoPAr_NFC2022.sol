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
    function ownerOf(uint256 tokenId) external view returns (address);
}

contract MoPAr_NFC2022 is Ownable, IMoPArMetadata {
    IMoPAr private mopar;

    string private _uriPrefix;             // uri prefix
    string private _baseURI;
    uint256 private constant SEPARATOR = 10**4;
    uint16 public collectionId;
    address public mintingWallet;
    //hardcode the starting token id
    //on tokenURI, do an of owner check for all three
    //if all three are owned show, json with single NFT AND triptych NFT
    //else show json with single NFT


    constructor(string memory initURIPrefix_, string memory initBaseURI_, address moparAddress_, address mintingWallet_)
    Ownable() 
    {
        _uriPrefix = initURIPrefix_;
        _baseURI = initBaseURI_;
        mintingWallet = mintingWallet_;
        mopar = IMoPAr(moparAddress_);
    }

    function tokenURI(uint256 tokenId) override external view returns (string memory) {
        //check if all three are owned
        //if all three are owned show, json with single NFT AND triptych NFT
        //else show json with single NFT
        if (mopar.ownerOf(SEPARATOR * collectionId) != mintingWallet && mopar.ownerOf(SEPARATOR * collectionId + 1) != mintingWallet && mopar.ownerOf(SEPARATOR * collectionId + 2) != mintingWallet) {
            return string(abi.encodePacked(_baseURI, _toString(tokenId), "-state1.json"));
        } else {
            return string(abi.encodePacked(_baseURI, _toString(tokenId), "-state0.json"));
        }
    }

    function setMintingWallet(address mintingWallet_) external onlyOwner {
        mintingWallet = mintingWallet_;
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
    function beforeTokenTransfer(address, address, uint256 tokenId) override external {
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
