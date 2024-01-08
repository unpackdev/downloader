// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
//Contract Address for ArtBlocks: { 0x47e312d99C09Ce61A866c83cBbbbED5A4b9d33E7 }
interface IArtBlocks 
{    
    function purchase(uint256 _projectId) payable external returns (uint tokenID);
}
