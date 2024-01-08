pragma solidity ^0.8.0;

//SPDX-License-Identifier: MIT

interface IHippoMale {
    function ownerOf(uint256 _tokenId) external view returns(address);
    function approve(address _addr, uint256 _tokenId) external;
}