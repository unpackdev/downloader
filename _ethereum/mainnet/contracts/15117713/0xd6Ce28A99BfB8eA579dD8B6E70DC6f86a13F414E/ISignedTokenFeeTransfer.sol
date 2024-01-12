// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

interface ISignedTokenFeeTransfer {
    function transferPreSigned(address to, uint256 value, uint256 gasPrice, uint256 nonce, bytes calldata signature) external returns (bool);

    function transferPreSignedPayloadHash(address token, address to, uint256 value, uint256 gasPrice, uint256 nonce) external returns (bytes32);

    event HashRedeemed(bytes32 indexed txHash, address indexed from);
}
