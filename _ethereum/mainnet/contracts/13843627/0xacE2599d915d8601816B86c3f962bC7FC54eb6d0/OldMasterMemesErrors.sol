// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

error ContractAddressInvalid();
error ContractAlreadyInitialized();
error EmptyAddress();
error SaleOfOriginalContractActive();
error OriginalContractAddressMismatch();

error ExceedCap();
error AmountExceedsMaxPerMint();
error AmountExceedsMaxPerUser();
error AmountExceedsMax();
error AmountExceedsCommunityMax();
error ExceedsMaxMintsForMintInterval();

error EtherValueIncorrect();
error WalletSenderMismatch();
error InvalidSignature();
error CommunityLinkAlreadyUsed();

error SaleInactive();
error CommunitySaleInactive();
error BurnInactive();

error MaxOmmIsZero();
error MaxPerMintIsZero();
error MaxPerUserIsZero();
error MintPriceIsZero();
error MintPriceCommunityIsZero();
