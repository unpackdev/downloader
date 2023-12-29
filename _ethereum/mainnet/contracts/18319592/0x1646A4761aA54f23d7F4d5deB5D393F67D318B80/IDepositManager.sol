// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IDepositManager {
    function depositERC20ForUser(address token, address user, uint256 amount) external;
}
