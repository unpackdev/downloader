// SPDX-License-Identifier: MIT
// Creator: base64.tech
pragma solidity ^0.8.13;

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