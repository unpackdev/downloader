// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.15;

import "./IRootManager.sol";

import "./FxBaseRootTunnel.sol";

import "./HubConnector.sol";

contract PolygonHubConnector is HubConnector, FxBaseRootTunnel {
  // ============ Constructor ============
  constructor(
    uint32 _domain,
    uint32 _mirrorDomain,
    address _amb,
    address _rootManager,
    address _mirrorConnector,
    uint256 _mirrorGas,
    address _checkPointManager
  )
    HubConnector(_domain, _mirrorDomain, _amb, _rootManager, _mirrorConnector, _mirrorGas)
    FxBaseRootTunnel(_checkPointManager, _amb)
  {}

  // ============ Private fns ============

  function _verifySender(address _expected) internal view override returns (bool) {
    // NOTE: always return false on polygon
    return false;
  }

  function _sendMessage(bytes memory _data) internal override {
    _sendMessageToChild(_data);
  }

  function _processMessageFromChild(bytes memory message) internal override {
    // NOTE: crosschain sender is not directly exposed by the child message

    // do not need any additional sender or origin checks here since the proof contains inclusion proofs of the snapshots

    // get the data (should be the aggregate root)
    require(message.length == 32, "!length");
    // update the root on the root manager
    IRootManager(ROOT_MANAGER).aggregate(MIRROR_DOMAIN, bytes32(message));

    emit MessageProcessed(message, msg.sender);
  }

  function _processMessage(bytes memory _data) internal override {}

  function _setMirrorConnector(address _mirrorConnector) internal override {
    super._setMirrorConnector(_mirrorConnector);

    setFxChildTunnel(_mirrorConnector);
  }
}
