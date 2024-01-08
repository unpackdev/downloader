// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

//Interface for characters NFT
interface I_TokenCharacter {

    function Mint(uint8, address) external; //amount, to
    
    function totalSupply() external view returns (uint256);
    function setApprovalForAll(address, bool) external;  //address, operator
    function transferFrom(address, address, uint256) external;
    function ownerOf(uint256) external view returns (address); //who owns this token
    function _ownerOf16(uint16) external view returns (address);

    function addController(address) external;

}