// contracts/NFT.sol
// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./PaymentSplitter.sol";

contract Vault is PaymentSplitter {
    constructor(address[] memory recipients, uint256[] memory shares) PaymentSplitter(recipients, shares) {}
}

