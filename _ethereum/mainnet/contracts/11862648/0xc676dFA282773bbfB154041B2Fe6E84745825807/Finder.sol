// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

import "./Ownable.sol";
import "./FinderInterface.sol";

contract Finder is FinderInterface, Ownable {
  mapping(bytes32 => address) public interfacesImplemented;

  event InterfaceImplementationChanged(
    bytes32 indexed interfaceName,
    address indexed newImplementationAddress
  );

  function changeImplementationAddress(
    bytes32 interfaceName,
    address implementationAddress
  ) external override onlyOwner {
    interfacesImplemented[interfaceName] = implementationAddress;

    emit InterfaceImplementationChanged(interfaceName, implementationAddress);
  }

  function getImplementationAddress(bytes32 interfaceName)
    external
    view
    override
    returns (address)
  {
    address implementationAddress = interfacesImplemented[interfaceName];
    require(implementationAddress != address(0x0), 'Implementation not found');
    return implementationAddress;
  }
}
