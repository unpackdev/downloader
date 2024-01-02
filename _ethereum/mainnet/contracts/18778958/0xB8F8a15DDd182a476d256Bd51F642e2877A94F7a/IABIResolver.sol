// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IABIResolver {
  event ABIChanged(bytes32 indexed node, uint256 indexed contentType);

  function ABI(
    bytes32 node,
    uint256 contentTypes
  ) external view returns (uint256, bytes memory);
}
