// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface ISellToken {
    function balanceOf(address _address) external view returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function safeTransferFrom(address _from, address _to, uint256 _tokebId) external;
}