// Copyright Immutable Pty Ltd 2018 - 2023
// SPDX-License-Identifier: Apache 2.0
pragma solidity 0.8.19;

import "./IERC20.sol";

/**
 * @notice Interface for the Wrapped ETH (wETH) contract.
 * @dev Interface for the standard wrapped ETH contract deployed on Ethereum: https://etherscan.io/address/0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2
 */
interface IWETH is IERC20 {
    /**
     * @notice Emitted when native ETH is deposited to the contract, and a corresponding amount of wETH are minted
     * @param account The address of the account that deposited the tokens.
     * @param value The amount of tokens that were deposited.
     */
    event Deposit(address indexed account, uint256 value);

    /**
     * @notice Emitted when wETH is withdrawn from the contract, and a corresponding amount of wETH are burnt.
     * @param account The address of the account that withdrew the tokens.
     * @param value The amount of tokens that were withdrawn.
     */
    event Withdrawal(address indexed account, uint256 value);

    /**
     * @notice Deposit native ETH to the contract and mint an equal amount of wrapped ETH to msg.sender.
     */
    function deposit() external payable;

    /**
     * @notice Withdraw given amount of native ETH to msg.sender after burning an equal amount of wrapped ETH.
     * @param value The amount to withdraw.
     */
    function withdraw(uint256 value) external;
}
