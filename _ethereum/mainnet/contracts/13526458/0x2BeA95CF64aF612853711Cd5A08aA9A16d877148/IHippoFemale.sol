pragma solidity ^0.8.0;

//SPDX-License-Identifier: MIT

interface IHippoFemale{
    function totalSupply() external view returns (uint256 total);
    function ownerOf(uint256 _tokenId) external view returns(address);
    function approve(address _addr, uint256 _tokenId) external;     
}