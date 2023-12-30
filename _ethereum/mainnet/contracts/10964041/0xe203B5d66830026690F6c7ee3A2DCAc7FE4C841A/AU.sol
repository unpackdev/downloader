// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.8;

contract AU {
function isContract(address _addr) public view returns (bool addressCheck) { 
    uint256 size;
    assembly { size := extcodesize(_addr) } 
    addressCheck = size > 0;
} }