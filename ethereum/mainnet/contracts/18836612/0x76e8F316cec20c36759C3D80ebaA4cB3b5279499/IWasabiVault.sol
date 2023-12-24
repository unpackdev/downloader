// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./IERC4626.sol";

interface IWasabiVault is IERC4626 {
    error EthTransferFailed();
    error CannotDepositEth();
    error CallerNotPool();
    error InvalidEthAmount();

    /// @dev Records an interest payment
    function recordInterestEarned(uint256 _interestAmount) external;

    /// @dev Records any losses from liquidations
    function recordLoss(uint256 _amountLost) external;

    /// @dev The pool address that holds the assets
    function getPoolAddress() external view returns (address);
}