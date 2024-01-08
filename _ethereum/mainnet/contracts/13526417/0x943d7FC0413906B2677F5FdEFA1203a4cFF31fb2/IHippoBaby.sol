pragma solidity ^0.8.0;

//SPDX-License-Identifier: MIT

interface IHippoBaby {
    function totalSupply() external view returns (uint256 total);
    function breedingMint(address _to) external returns(uint );
    function ownerOf(uint _tokenId) external view returns(address);
    function approve(address _to, uint _tokenId) external;
    function transferFrom( address _from , address _to, uint _tokenId) external;
}