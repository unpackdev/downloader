// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.4 <0.9.0;

library Errors {
    error DuplicateTransaction(bytes32 nonce);
    error TokensUnavailable();
    error AlreadyUpgraded(uint256 tokenID);
    error AlreadySacrificed(uint256 tokenID);
    error AttemptingToUpgradeSacrificedToken(uint256 tokenID);
    error UnownedToken(uint256 tokenID);
    error InvalidSignature();

    error UserPermissions();
    error AddressTarget(address target);
    error NotInitialized();
    error InsufficientBalance(uint256 available, uint256 required);
    error NotAContract();
    error UnsignedOverflow(uint256 value);
    error OutOfRange(uint256 value);
    error PaymentFailed(uint256 amount);
}
