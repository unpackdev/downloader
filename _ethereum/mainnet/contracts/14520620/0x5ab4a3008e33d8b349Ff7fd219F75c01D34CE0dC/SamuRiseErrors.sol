// SPDX-License-Identifier: MIT
// Creator: base64.tech
pragma solidity ^0.8.13;

//"Not enough ETH Sent"
error NotEnoughETHSent();
//"free claim is not active"
error FreeClaimIsNotActive();
//"pre-sale is not active"
error PreSaleIsNotActive();
//"pre-sale round 2 is not active"
error PreSaleRound2IsNotActive();
//"public sale is not active"
error PublicSaleIsNotActive();
//"Purchase would exceed max supply"
error PurchaseWouldExceedMaxSupply();
//"Mint would exceed maximum allocation of mints for this wallet/mint type"
error MintWouldExceedMaxAllocation();
// "Hash was already used"
error HashWasAlreadyUsed();
// "Unrecognizable Hash"
error UnrecognizeableHash(); 
// "The caller is another contract"
error CallerIsAnotherContract();

