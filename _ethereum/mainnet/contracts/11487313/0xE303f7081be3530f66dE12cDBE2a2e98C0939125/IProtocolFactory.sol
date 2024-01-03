// SPDX-License-Identifier: No License

pragma solidity ^0.7.3;

/**
 * @dev ProtocolFactory contract interface. See {ProtocolFactory}.
 * @author crypto-pumpkin@github
 */
interface IProtocolFactory {
  function getCoverAddress(bytes32 _protocolName, uint48 _timestamp, address _collateral, uint256 _claimNonce) external view returns (address);
  function getProtocolAddress(bytes32 _name) external view returns (address);
}  