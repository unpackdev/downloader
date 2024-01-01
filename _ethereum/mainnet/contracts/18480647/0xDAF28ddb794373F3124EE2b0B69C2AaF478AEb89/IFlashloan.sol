// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/// @title Flashloan Interface
interface IFlashloan {
    /// @notice Flashloan Info Struct
    /// @param enabled Enabled flag
    /// @param flashloanPremiumValue;
    struct FlashLoanInfo {
        bool enabled;
        uint256 flashloanPremiumValue;
    }

    /// @notice ETH Transfer Failed
    error EthTransferFailed();

    /// @notice Borrow ETH
    /// @param amount Flashloan amount
    /// @return flashLoanRepayAmount Flashloan repayment amount
    function borrow(uint256 amount) external returns (uint256 flashLoanRepayAmount);
}
