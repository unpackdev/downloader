// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface ISignatureVerifier {
    event UsedNonce(address account, bytes32 nonce, string action);

    function verifyWithdrawTokenFromLand (
        bytes32 nonce,
        address receiver,
        uint256 landId,
        uint256 amount,
        bytes memory signature
    )
    external
    returns (bool);

    function verifyWithdrawToken (
        bytes32 nonce,
        address receiver,
        uint256 amount,
        bytes memory signature
    )
    external
    returns (bool);

    function verifyWithdrawEnrich (
        bytes32 nonce,
        address receiver,
        uint256[] memory enrichIds,
        uint256[] memory amounts,
        bytes memory signature
    )
    external
    returns (bool);

    function verifyWithdrawResource (
        bytes32 nonce,
        address receiver,
        uint256[] memory resourceIds,
        uint256[] memory amounts,
        bytes memory signature
    )
    external
    returns (bool);

    function verifyClaimLand (
        bytes32 nonce,
        address receiver,
        uint256[] memory nekoId,
        bytes memory signature
    )
    external 
    returns (bool);
}