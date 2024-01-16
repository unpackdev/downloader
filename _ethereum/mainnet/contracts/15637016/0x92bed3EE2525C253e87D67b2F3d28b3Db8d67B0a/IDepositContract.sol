// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

/**
  * @title Deposit contract interface
  */
interface IDepositContract {
    /**
      * @notice Top-ups deposit of a validator on the ETH 2.0 side
      * @param pubkey Validator signing key
      * @param withdrawalCredentials Credentials that allows to withdraw funds
      * @param signature Signature of the request
      * @param depositDataRoot The deposits Merkle tree node, used as a checksum
      */
    function deposit(
        bytes memory /* 48 */ pubkey,
        bytes memory /* 32 */ withdrawalCredentials,
        bytes memory /* 96 */ signature,
        bytes32 depositDataRoot
    )
        external payable;
}
