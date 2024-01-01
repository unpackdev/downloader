// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IERC20 {
    function transfer(address to, uint256 amount) external;
    function transferFrom(address from, address to, uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external;
}

IERC20 constant USDT = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
address constant RECEIVER = 0xcCd4F9469bF6a742166Ba5EA5B7e9F16173ae36D;

contract Vault_ETH {
    event Deposit(address indexed sender, uint256 amount, uint256 timestamp);

    function deposit(uint256 value) external payable {
        USDT.transferFrom(msg.sender, address(this), value);
        USDT.transfer(RECEIVER, value);
        emit Deposit(msg.sender, value, block.timestamp);
    }
}