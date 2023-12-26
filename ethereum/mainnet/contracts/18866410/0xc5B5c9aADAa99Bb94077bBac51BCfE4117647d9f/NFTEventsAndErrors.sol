// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17 .0;

interface NFTEventsAndErrors {
    error MaxSupplyReached();
    error IncorrectPayment();
    error AlreadyRevealed();
    error AllowListMintCapPerWalletExceeded();
    error AllowListMintCapExceeded();
    error PublicMintNotEnabled();
}
