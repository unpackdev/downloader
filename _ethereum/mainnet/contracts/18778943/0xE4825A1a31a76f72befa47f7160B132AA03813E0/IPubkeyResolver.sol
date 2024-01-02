// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IPubkeyResolver {
  event PubkeyChanged(bytes32 indexed node, bytes32 x, bytes32 y);

  function pubkey(bytes32 node) external view returns (bytes32 x, bytes32 y);
}
