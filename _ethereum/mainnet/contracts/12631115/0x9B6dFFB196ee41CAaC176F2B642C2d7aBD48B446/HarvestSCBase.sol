// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./HarvestBase.sol";

contract HarvestSCBase is StrategyBase, HarvestBase {

    //-----------------------------------------------------------------------------------------------------------------//
    //------------------------------------ Events -------------------------------------------------//
    //-----------------------------------------------------------------------------------------------------------------//
    /// @notice Event emitted when rewards are exchanged to ETH or to a specific Token
    event RewardsExchanged(
        address indexed user,
        string exchangeType, //ETH or Token
        uint256 rewardsAmount,
        uint256 obtainedAmount
    );

    /// @notice Event emitted when user makes a deposit
    event Deposit(
        address indexed user,
        address indexed origin,
        uint256 amountToken,
        uint256 amountfToken
    );

    /// @notice Event emitted when user withdraws
    event Withdraw(
        address indexed user,
        address indexed origin,
        uint256 amountToken,
        uint256 amountfToken,
        uint256 treasuryAmountEth
    );
}
