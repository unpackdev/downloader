// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;


/**
 * The purpose of this contract is to hold USDE tokens for gas compensation:
 * 
 * When a borrower opens a trove, an additional 200 USDE debt is issued,
 * and 200 USDE is minted and sent to this contract.
 * When a borrower closes their active trove, this gas compensation is refunded:
 * 200 USDE is burned from the this contract's balance, and the corresponding
 * 200 USDE debt on the trove is cancelled.
 */
contract GasPool {
    // do nothing, as the core contracts have permission to send to and burn from this address
}
