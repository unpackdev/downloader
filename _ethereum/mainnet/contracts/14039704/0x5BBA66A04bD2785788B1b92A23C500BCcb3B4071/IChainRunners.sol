// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IChainRunners {
    function ownerOf(uint256 tokenId) external view returns (address);
    function getDna(uint256 _tokenId) external view returns (uint256);
    function balanceOf(address _addr) external view returns (uint256);
}
