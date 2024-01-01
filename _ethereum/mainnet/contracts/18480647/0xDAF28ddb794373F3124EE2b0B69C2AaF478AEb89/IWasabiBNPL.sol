// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./WasabiStructs.sol";

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
    error FlashLoanNotPaid();

    /// @notice ETH Transfer Failed
    error EthTransferFailed();

    /// @notice Invalid Param
    error InvalidParam();

    /// @dev Emitted when a new option is issued
    event OptionIssued(uint256 optionId);

    /// @dev Emitted when an option is rolledover into a new one
    event OptionRolledOver(uint256 optionId, uint256 previousOptionId, uint256 refundAmount);

    /// @dev Emitted when an option is executed
    event OptionExecuted(uint256 optionId);

    /// @dev Emitted when an option is executed and the NFT is sold to the market
    event OptionExecutedWithArbitrage(uint256 optionId, uint256 payout);

    /// @notice returns the OptionData for the given option id
    /// 
    function getOptionData(uint256 _optionId) external view returns (WasabiStructs.OptionData memory optionData);

    /// @notice Executes BNPL flow
    /// @dev BNLP flow
    ///      1. take flashloan
    ///      2. buy nft from marketplace
    ///      3. get loan from nft lending protocol
    /// @param _nftLending NFTLending contract address
    /// @param _borrowData Borrow data
    /// @param _flashLoanAmount Call value
    /// @param _marketplaceCallData List of marketplace calldata
    /// @param _signatures Signatures
    function bnpl(
        address _nftLending,
        bytes calldata _borrowData,
        uint256 _flashLoanAmount,
        FunctionCallData[] calldata _marketplaceCallData,
        bytes[] calldata _signatures
    ) external payable returns (uint256);

    /// @notice Executes the given option
    /// @param _optionId the option id
    function executeOption(uint256 _optionId) external payable;

    /// @notice Executes the given option and trades the underlying NFT to collect a payout
    /// @param _optionId the option id
    /// @param _marketplaceCallData marketplace calldata list
    /// @param _signatures the signatures for the marketplace call data
    function executeOptionWithArbitrage(
        uint256 _optionId,
        FunctionCallData[] calldata _marketplaceCallData,
        bytes[] calldata _signatures
    ) external payable;

    /// @notice Rolls the given option over by repaying the loan and getting a new one (mints a new option)
    /// @param _optionId the option id
    /// @param _nftLending the nft lending contract address
    /// @param _borrowData  the borrow data
    function rolloverOption(uint256 _optionId, address _nftLending, bytes calldata _borrowData) external payable;
}
