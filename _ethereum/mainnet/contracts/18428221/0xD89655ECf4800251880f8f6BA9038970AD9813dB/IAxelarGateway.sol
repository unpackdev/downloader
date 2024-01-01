// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IAxelarGateway {
  function callContract(
    string calldata destinationChain,
    string calldata contractAddress,
    bytes calldata payload
  ) external;

  function validateContractCall(
    bytes32 commandId,
    string calldata sourceChain,
    string calldata sourceAddress,
    bytes32 payloadHash
  ) external returns (bool);

  function validateContractCallAndMint(
    bytes32 commandId,
    string calldata sourceChain,
    string calldata sourceAddress,
    bytes32 payloadHash,
    string calldata symbol,
    uint256 amount
  ) external returns (bool);
}
