// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IVerifier {
  function verifyProof(bytes calldata proof, uint[] calldata pubSignals) external view returns (bool);
}
