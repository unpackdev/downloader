// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

/// @title TunnelEnd - A contract that contains base/common functionality for ZodiacPolygonTunnel pairs
/// @author Cristóvão Honorato - <cristovao.honorato@gnosis.pm>
contract TunnelEnd {
  bytes32 private latestSourceChainId;
  address private latestSourceChainSender;

  /// @dev Provides the end executor contract with the id of the network where the call originated
  function messageSourceChainId() public view returns (bytes32) {
    return latestSourceChainId;
  }

  /// @dev Provides the end executor contract with the address that triggered the call
  function messageSender() public view returns (address) {
    return latestSourceChainSender;
  }

  /// @dev Encodes a message to be delivered to FxRoot/FxChild
  /// @param target executor address on the other side
  /// @param data calldata passed to the executor on the other side
  /// @param gas gas limit used on the other side for executing
  function encodeIntoTunnel(
    address target,
    bytes memory data,
    uint256 gas
  ) internal view returns (bytes memory) {
    return abi.encode(getChainId(), msg.sender, target, data, gas);
  }

  /// @dev Decodes a message delivered by FxRoot/FxChild
  /// @param message encoded payload describing executor and parameters. Includes also original sender and origin network id
  function decodeFromTunnel(bytes memory message)
    internal
    pure
    returns (
      bytes32,
      address,
      address,
      bytes memory,
      uint256
    )
  {
    (
      bytes32 sourceChainId,
      address sourceChainSender,
      address target,
      bytes memory data,
      uint256 gas
    ) = abi.decode(message, (bytes32, address, address, bytes, uint256));

    return (sourceChainId, sourceChainSender, target, data, gas);
  }

  /// @dev Triggers the process of sending a message to the opposite network
  /// @param sourceChainId id of the network where the call was initiated
  /// @param sourceChainSender address that initiated the call
  /// @param target executor address on the other side
  /// @param data calldata passed to the executor on the other side
  /// @param gas gas limit used on the other side for executing
  function forwardToTarget(
    bytes32 sourceChainId,
    address sourceChainSender,
    address target,
    bytes memory data,
    uint256 gas
  ) internal {
    require(gas == 0xffffffff || (gasleft() * 63) / 64 > gas);

    latestSourceChainId = sourceChainId;
    latestSourceChainSender = sourceChainSender;
    (bool success, ) = target.call{gas: gas}(data);
    latestSourceChainSender = address(0);
    latestSourceChainId = bytes32("0x");
    require(success, "ForwardToTarget failed");
  }

  function getChainId() private pure returns (bytes32) {
    uint256 id;
    assembly {
      id := chainid()
    }
    return bytes32(id);
  }
}
