// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IAddrResolver {
  event AddrChanged(bytes32 indexed node, address a);

  function addr(bytes32 node) external view returns (address payable);
}
