// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;


interface IProxyManagerAccessControl {
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  function transferManagerOwnership(address newOwner) external;

  function transferOwnership(address newOwner) external;

  function setImplementationAddressManyToOne(
    bytes32 implementationID,
    address implementation
  ) external;

  function setImplementationAddressOneToOne(
    address proxyAddress,
    address implementation
  ) external;
}