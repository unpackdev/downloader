// SPDX-FileCopyrightText: 2021 Lido <info@lido.fi>

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.1;

/**
 * @title StETH token wrapper with static balances.
 * @dev It's an ERC20 token that represents the account's share of the total
 * supply of stETH tokens. WstETH token's balance only changes on transfers,
 * unlike StETH that is also changed when oracles report staking rewards and
 * penalties. It's a "power user" token for DeFi protocols which don't
 * support rebasable tokens.
 *
 * The contract is also a trustless wrapper that accepts stETH tokens and mints
 * wstETH in return. Then the user unwraps, the contract burns user's wstETH
 * and sends user locked stETH in return.
 *
 * The contract provides the staking shortcut: user can send ETH with regular
 * transfer and get wstETH in return. The contract will send ETH to Lido submit
 * method, staking it and wrapping the received stETH.
 *
 */
interface IwstETH {
    /**
     * @notice Get amount of wstETH for a one stETH
     * @return Amount of stETH for 1 wstETH
     */
    function stEthPerToken() external view returns (uint256);
}
