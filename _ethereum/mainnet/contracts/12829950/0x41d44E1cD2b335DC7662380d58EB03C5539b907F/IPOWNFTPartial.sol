//SPDX-License-Identifier: Lapdog millionaire
pragma solidity ^0.8.0;

interface IPOWNFTPartial{
    function UNMIGRATED() external view returns(uint);
    function hashOf(uint _tokenId) external view returns(bytes32);
    function totalSupply() external view returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns(address);
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}