// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

import "./FxBaseRootTunnel.sol";
import "./TunnelEnd.sol";

contract ZodiacPolygonRootTunnel is FxBaseRootTunnel, TunnelEnd {
  constructor(address _checkpointManager, address _fxRoot)
    FxBaseRootTunnel(_checkpointManager, _fxRoot)
  {}

  /// @dev Requests message relay to Child network
  /// @param target executor address on Child network
  /// @param data calldata passed to the executor on Child network
  /// @param gas gas limit used on Child Network for executing - 0xfffffff for unbound
  function sendMessage(
    address target,
    bytes memory data,
    uint256 gas
  ) public {
    bytes memory message = encodeIntoTunnel(target, data, gas);
    _sendMessageToChild(message);
  }

  function _processMessageFromChild(bytes memory message) internal override {
    (
      bytes32 sourceChainId,
      address sourceChainSender,
      address target,
      bytes memory data,
      uint256 gas
    ) = decodeFromTunnel(message);
    forwardToTarget(sourceChainId, sourceChainSender, target, data, gas);
  }
}
