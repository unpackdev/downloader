// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface ISTBTMinter {
    function mint(address token, uint depositAmount, uint minProposedAmount, bytes32 salt, bytes calldata extraData) external;
    
    function redeem(uint amount, address token, bytes32 salt, bytes calldata extraData) external;
}