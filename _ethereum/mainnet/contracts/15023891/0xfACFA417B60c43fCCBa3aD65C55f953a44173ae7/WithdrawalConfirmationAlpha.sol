// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./WithdrawalConfirmation.sol";

/** 
* @author Formation.Fi.
* @notice Implementation of the contract WithdrawalConfirmationAlpha.
*/
 contract WithdrawalConfirmationAlpha is WithdrawalConfirmation {
    constructor() WithdrawalConfirmation("WALPHA", "WALPHA") {
    }
}