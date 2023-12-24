// SPDX-License-Identifier: MIT

pragma solidity >=0.8.19;

/**
 * @dev Xeno Mining - Error definition contract
 */
contract MiningErrors {
    error InvalidPublisher(string errMsg);
    string constant WRONG_XENO_STAKING_CONTRACT = "Wrong Xeno Staking contract";

    error InvalidState(string errMsg);
    string constant CYCLE_NOT_STARTED = "Cycle not started";


    error ProofError(string errMsg);
    string constant INVALID_CONTRACT = "Invalid contract";
    string constant INVALID_DISTRIBUTOR = "Invalid distributor";
    string constant INVALID_CYCLE = "Invalid cycle";
    string constant INVALID_CLAIMER = "Invalid claimer";
    string constant INSUFFICIENT_BALANCE = "Insufficient balance";
    string constant INVALID_SIGNATURE = "Invalid signature";
}
