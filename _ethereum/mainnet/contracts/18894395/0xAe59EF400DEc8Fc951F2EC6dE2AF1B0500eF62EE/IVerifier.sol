// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVerifier {
    /// @dev The ZK verifier for proving a row of the artwork
    function verifyProof(
        uint256[24] calldata _proof,
        uint256[3] calldata _pubSignals
    ) external view returns (bool);

    /// @dev The ZK verifier for proving the price of the artwork
    function verifyProof(
        uint256[24] calldata _proof,
        uint256[33] calldata _pubSignals
    ) external view returns (bool);

    /// @dev The ZK verifier for proving the purchase of the artwork
    function verifyProof(
        uint256[24] calldata _proof,
        uint256[34] calldata _pubSignals
    ) external view returns (bool);

    /// @dev The ZK verifier for revealing a row of the artwork
    function verifyProof(
        uint256[24] calldata _proof,
        uint256[35] calldata _pubSignals
    ) external view returns (bool);
}
