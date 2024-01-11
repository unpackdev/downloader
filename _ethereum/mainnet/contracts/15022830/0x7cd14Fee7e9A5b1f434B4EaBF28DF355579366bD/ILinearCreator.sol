// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface ILinearCreator{
    event VestingCreated(address indexed vesting, uint index);
    
    function owner() external  view returns (address);
    
    function allVestingsLength() external view returns(uint);
    
    function allVestings(uint) external view returns(address);
    
    function createVesting(address, uint32, uint32, uint32[2] calldata) external returns (address);
    
    function transferOwnership(address) external;
}
