// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBlurPool {
    /**
     * @dev deposit ETH into pool
     */
    function deposit() external payable;

    /**
     * @dev withdraw ETH from pool
     * @param amount Amount to withdraw
     */
    function withdraw(uint256 amount) external;

    function balanceOf(address user) external view returns (uint256);
}
