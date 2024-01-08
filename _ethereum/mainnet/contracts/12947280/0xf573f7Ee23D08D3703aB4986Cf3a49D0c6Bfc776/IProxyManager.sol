// SPDX-License-Identifier: MIT
pragma solidity >=0.5.10;


interface IProxyManager {
  function deployProxyManyToOne(
    bytes32 implementationID,
    bytes32 suppliedSalt
  ) external returns(address proxyAddress);

  function computeProxyAddressManyToOne(
    address originator,
    bytes32 implementationID,
    bytes32 suppliedSalt
  ) external view returns (address);
}