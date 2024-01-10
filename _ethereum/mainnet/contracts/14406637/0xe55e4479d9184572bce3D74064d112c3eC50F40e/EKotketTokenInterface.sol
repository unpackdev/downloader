// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;


interface EKotketTokenInterface {
    function allowance(address owner, address spender) external view returns (uint256);
    
    function balanceOf(address account) external view returns (uint256);
    
    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}