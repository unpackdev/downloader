/**
 * COPYRIGHT © 2020 RARI CAPITAL, INC. ALL RIGHTS RESERVED.
 * Anyone is free to integrate the public (i.e., non-administrative) application programming interfaces (APIs) of the official Ethereum smart contract instances deployed by Rari Capital, Inc. in any application (commercial or noncommercial and under any license), provided that the application does not abuse the APIs or act against the interests of Rari Capital, Inc.
 * Anyone is free to study, review, and analyze the source code contained in this package.
 * Reuse (including deployment of smart contracts other than private testing on a private network), modification, redistribution, or sublicensing of any source code contained in this package is not permitted without the explicit permission of David Lucid of Rari Capital, Inc.
 * No one is permitted to use the software for any purpose other than those allowed by this license.
 * This license is liable to change at any time at the sole discretion of David Lucid of Rari Capital, Inc.
 */

pragma solidity 0.5.17;

import "./SafeMath.sol";
import "./SafeERC20.sol";

import "./Bank.sol";

/**
 * @title AlphaPoolController
 * @author David Lucid <david@rari.capital> (https://github.com/davidlucid)
 * @dev This library handles deposits to and withdrawals from Alpha Homora's ibETH pool.
 */
library AlphaPoolController {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /**
     * @dev Alpha Homora ibETH token contract address.
     */
    address constant private IBETH_CONTRACT = 0x67B66C99D3Eb37Fa76Aa3Ed1ff33E8e39F0b9c7A;

    /**
     * @dev Alpha Homora ibETH token contract object.
     */
    Bank constant private _ibEth = Bank(IBETH_CONTRACT);

    /**
     * @dev Returns the fund's balance of the specified currency in the ibETH pool.
     */
    function getBalance() external view returns (uint256) {
        return _ibEth.balanceOf(address(this)).mul(_ibEth.totalETH()).div(_ibEth.totalSupply());
    }

    /**
     * @dev Deposits funds to the ibETH pool. Assumes that you have already approved >= the amount to the ibETH token contract.
     * @param amount The amount of ETH to be deposited.
     */
    function deposit(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0.");
        _ibEth.deposit.value(amount)();
    }

    /**
     * @dev Withdraws funds from the ibETH pool.
     * @param amount The amount of tokens to be withdrawn.
     */
    function withdraw(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0.");
        uint256 totalEth = _ibEth.totalETH();
        uint256 totalSupply = _ibEth.totalSupply();
        uint256 credits = amount.mul(totalSupply).div(totalEth);
        if (credits.mul(totalEth).div(totalSupply) < amount) credits++; // Round up if necessary (i.e., if the division above left a remainder)
        _ibEth.withdraw(credits);
    }

    /**
     * @dev Withdraws all funds from the ibETH pool.
     * @return Boolean indicating success.
     */
    function withdrawAll() external returns (bool) {
        uint256 balance = _ibEth.balanceOf(address(this));
        if (balance <= 0) return false;
        _ibEth.withdraw(balance);
        return true;
    }
}