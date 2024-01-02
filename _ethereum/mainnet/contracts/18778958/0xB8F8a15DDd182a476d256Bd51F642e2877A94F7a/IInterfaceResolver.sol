// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IInterfaceResolver {
  event InterfaceChanged(
    bytes32 indexed node,
    bytes4 indexed interfaceID,
    address implementer
  );

  function interfaceImplementer(
    bytes32 node,
    bytes4 interfaceID
  ) external view returns (address);
}
