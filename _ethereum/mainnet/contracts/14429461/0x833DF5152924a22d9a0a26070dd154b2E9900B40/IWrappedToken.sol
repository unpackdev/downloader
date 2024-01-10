// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IWrappedToken {
    
    function mint(uint _amount) external; 
    
    function burn(uint _amount) external;

    function underlyingCToken() external view returns (address);
}