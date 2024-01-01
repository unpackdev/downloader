// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// interface for IBuildingNFT
interface IBuildingNFT {

    struct NFTInfo {
        uint256 isleId;
        string usage;
        uint256 scale;
        string form;
    }
    
    function getNFT(uint256 id) external view returns(NFTInfo memory);
    function getUsageWeight(string memory usage) external view returns(uint256);
    function getScaleWeight(uint256 scale) external view returns(uint256);
}
