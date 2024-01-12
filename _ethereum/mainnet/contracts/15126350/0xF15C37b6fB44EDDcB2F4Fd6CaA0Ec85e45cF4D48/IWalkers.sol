// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./IERC721AQueryable.sol";

interface IWalkers is IERC721AQueryable {
    error NonEOA();
    error InvalidSaleState();
    error WalletLimitExceeded();
    error InvalidEtherAmount();
    error InvalidSignature();
    error MaxSupplyExceeded();
    error TokenClaimed();
    error AccountMismatch();
    error PublicSupplyExceeded();
    error InvalidTokenAmount();

    function tokenOwnership(uint256) external view returns (TokenOwnership memory);
}