// SPDX-License-Identifier: ISC
pragma solidity ^0.8.21;

// ===================== SturdyPairConstants ========================

/// @title SturdyPairConstants
/// @author Drake Evans (Frax Finance) https://github.com/drakeevans
/// @notice  An abstract contract which contains the errors and constants for the SturdyPair contract
abstract contract SturdyPairConstants {
    // ============================================================================================
    // Constants
    // ============================================================================================

    // Precision settings
    uint256 internal constant LTV_PRECISION = 1e5; // 5 decimals
    uint256 internal constant LIQ_PRECISION = 1e5;
    uint256 internal constant UTIL_PREC = 1e5;
    uint256 internal constant FEE_PRECISION = 1e5;
    uint256 internal constant EXCHANGE_PRECISION = 1e18;
    uint256 internal constant DEVIATION_PRECISION = 1e5;
    uint256 internal constant RATE_PRECISION = 1e18;

    // Protocol Fee
    uint256 internal constant MAX_PROTOCOL_FEE = 5e4; // 50% 1e5 precision

    error Insolvent(uint256 _borrow, uint256 _collateral, uint256 _exchangeRate);
    error BorrowerSolvent();
    error InsufficientAssetsInContract(uint256 _assets, uint256 _request);
    error SlippageTooHigh(uint256 _minOut, uint256 _actual);
    error BadSwapper();
    error InvalidPath(address _expected, address _actual);
    error BadProtocolFee();
    error PastDeadline(uint256 _blockTimestamp, uint256 _deadline);
    error SetterRevoked();
    error ExceedsMaxOracleDeviation();
    error InvalidReceiver();
    error InvalidOnBehalfOf();
    error InvalidApproveBorrowDelegation();
    error InvalidBorrower();
    error InvalidDelegator();
}
