// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IVerifier {
    error SignerNotVerified(bytes32 hash, bytes signature);

    function recoverSigner(bytes32 hash, bytes memory signature) external returns (address);

    function verifySigner(bytes32 hash, bytes memory signature) external view returns (bool);

    function signedHashApplied(bytes32 hash) external view returns (bool);
}
