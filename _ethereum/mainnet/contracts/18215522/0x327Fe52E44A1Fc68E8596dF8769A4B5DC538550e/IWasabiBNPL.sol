// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/// @title WasabiBNPL Interface
interface IWasabiBNPL {
    /// @notice Function Calldata Struct
    /// @param to to address
    /// @param value call value
    /// @param data call data
    struct FunctionCallData {
        address to;
        uint256 value;
        bytes data;
    }

    /// @notice Loan Info Struct
    /// @param nftLending INFTLending address
    /// @param loanId loan id
    struct LoanInfo {
        address nftLending;
        uint256 loanId;
    }

    /// @notice Function Call Failed
    error FunctionCallFailed();

    /// @notice Loan Not Paid
    error LoanNotPaid();

    /// @notice ETH Transfer Failed
    error EthTransferFailed();

    /// @notice Invalid Param
    error InvalidParam();

    /// @dev Emitted when an option is executed
    event OptionExecuted(uint256 optionId);

    /// @dev Emitted when an option is executed and the NFT is sold to the market
    event OptionExecutedWithArbitrage(uint256 optionId, uint256 payout);
}
