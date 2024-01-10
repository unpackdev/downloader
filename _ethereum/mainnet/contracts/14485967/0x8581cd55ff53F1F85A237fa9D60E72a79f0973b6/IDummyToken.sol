// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IDummyToken {

    function name() external view  returns (string memory);

    function symbol() external view returns (string memory);
    
    function decimals() external view returns (uint8);

    function mint(address _to, uint _amount) external; 

    function buy(uint _amount) external; 

    function sell(uint _amount) external; 
}