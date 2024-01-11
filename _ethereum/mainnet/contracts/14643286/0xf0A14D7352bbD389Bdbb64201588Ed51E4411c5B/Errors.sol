// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

error ContractLocked();
error SoldOut();
error SaleClosed();
error PresaleClosed();
error WalletLimitReached(uint256 limit);
error InvalidPriceSentForAmount(uint256 sent, uint256 required);
error MintingTooMany();
error NotWhitelisted();
error NotAuthorized();
error NotOnAllowlist();
