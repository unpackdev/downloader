// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;
                                                                                                                                                                                                                                      
import "./IMerge.sol";

contract PakMergeSnapshot {    
        
    IMerge immutable public _mergeContract;

    constructor() {
        _mergeContract = IMerge(0xc3f8a0F5841aBFf777d3eefA5047e8D413a1C9AB);
    }       

    function getOwners(uint256 tokenIdBegin, uint256 tokenIdEnd) public view returns (address[] memory) {
        require(tokenIdEnd >= tokenIdBegin, "Invalid arguments");
        uint256 numTokens = tokenIdEnd - tokenIdBegin + 1;
        address[] memory owners = new address[](numTokens);
        for(uint256 tokenId = tokenIdBegin; tokenId <= tokenIdEnd; tokenId++) {
            try _mergeContract.ownerOf(tokenId) returns (address owner) {
                owners[tokenId - tokenIdBegin] = owner;
            } catch Error(string memory /*reason*/) {                
                owners[tokenId - tokenIdBegin] = address(0);
            }
        }
        return owners;
    }

    function getMasses(uint256 tokenIdBegin, uint256 tokenIdEnd) public view returns (uint256[] memory) {
        require(tokenIdEnd >= tokenIdBegin, "Invalid arguments");
        uint256 numTokens = tokenIdEnd - tokenIdBegin + 1;
        uint256[] memory masses = new uint256[](numTokens);
        for(uint256 tokenId = tokenIdBegin; tokenId <= tokenIdEnd; tokenId++) {
            try _mergeContract.massOf(tokenId) returns (uint256 mass) {
                masses[tokenId - tokenIdBegin] = mass;
            } catch Error(string memory /*reason*/) {                
                masses[tokenId - tokenIdBegin] = 0;
            }
        }
        return masses;        
    }

    function getMergeCounts(uint256 tokenIdBegin, uint256 tokenIdEnd) public view returns (uint256[] memory) {
        require(tokenIdEnd >= tokenIdBegin, "Invalid arguments");
        uint256 numTokens = tokenIdEnd - tokenIdBegin + 1;
        uint256[] memory merges = new uint256[](numTokens);
        for(uint256 tokenId = tokenIdBegin; tokenId <= tokenIdEnd; tokenId++) {
            try _mergeContract.getMergeCount(tokenId) returns (uint256 mergeCount) {
                merges[tokenId - tokenIdBegin] = mergeCount;
            } catch Error(string memory /*reason*/) {                
                merges[tokenId - tokenIdBegin] = 0;
            }
        }
        return merges;
    }

    function getClasses(uint256 tokenIdBegin, uint256 tokenIdEnd) public view returns (uint256[] memory) {
        require(tokenIdEnd >= tokenIdBegin, "Invalid arguments");
        uint256 numTokens = tokenIdEnd - tokenIdBegin + 1;
        uint256[] memory classes = new uint256[](numTokens);
        for(uint256 tokenId = tokenIdBegin; tokenId <= tokenIdEnd; tokenId++) {
            try _mergeContract.getValueOf(tokenId) returns (uint256 value) {
                uint256 tensDigit = tokenId % 100 / 10;
                uint256 onesDigit = tokenId % 10;
                uint256 class = tensDigit * 10 + onesDigit;
                classes[tokenId - tokenIdBegin] = class;
            } catch Error(string memory /*reason*/) {                
                classes[tokenId - tokenIdBegin] = 0;
            }
        }
        return classes;
    }

    function getTiers(uint256 tokenIdBegin, uint256 tokenIdEnd) public view returns (uint256[] memory) {
        require(tokenIdEnd >= tokenIdBegin, "Invalid arguments");
        uint256 numTokens = tokenIdEnd - tokenIdBegin + 1;
        uint256[] memory tiers = new uint256[](numTokens);
        for(uint256 tokenId = tokenIdBegin; tokenId <= tokenIdEnd; tokenId++) {
            try _mergeContract.getValueOf(tokenId) returns (uint256 value) {
                tiers[tokenId - tokenIdBegin] = _mergeContract.decodeClass(value);
            } catch Error(string memory /*reason*/) {                
                tiers[tokenId - tokenIdBegin] = 0;
            }
        }
        return tiers;        
    }

    function getExists(uint256 tokenIdBegin, uint256 tokenIdEnd) public view returns (bool[] memory) {
        require(tokenIdEnd >= tokenIdBegin, "Invalid arguments");
        uint256 numTokens = tokenIdEnd - tokenIdBegin + 1;
        bool[] memory existence = new bool[](numTokens);
        for(uint256 tokenId = tokenIdBegin; tokenId <= tokenIdEnd; tokenId++) {
            try _mergeContract.exists(tokenId) returns (bool exists) {
                existence[tokenId - tokenIdBegin] = exists;
            } catch Error(string memory /*reason*/) {                
                existence[tokenId - tokenIdBegin] = false;
            }
        }
        return existence;        
    }
}