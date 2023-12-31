// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "./Types.sol";

interface ISignatureVerifierUpgradeable {
    /* ========== ERRORS ========== */
    error LowThreshold();
    error ExpiredSignature();
    error InvalidOracle();
    error DuplicateSignatures();
    error NotEnoughOracles();

    function threshHold() external view returns (uint8);

    function verifyExchange(bytes32 hash_, Types.Signature[] calldata signs_) external view returns (bool);
}
