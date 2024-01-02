// SPDX-License-Identifier: ISC
pragma solidity ^0.8.21;

// ================ SturdyPairAccessControlErrors ===================

/// @title SturdyPairAccessControlErrors
/// @author Drake Evans (Frax Finance) https://github.com/drakeevans
/// @notice  An abstract contract which contains the errors for the Access Control contract
abstract contract SturdyPairAccessControlErrors {
    error OnlyProtocolOrOwner();
    error OnlyTimelockOrOwner();
    error ExceedsBorrowLimit();
    error AccessControlRevoked();
    error RepayPaused();
    error ExceedsDepositLimit();
    error WithdrawPaused();
    error LiquidatePaused();
    error InterestPaused();
}
