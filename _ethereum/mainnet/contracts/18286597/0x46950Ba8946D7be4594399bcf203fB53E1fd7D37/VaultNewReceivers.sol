// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "./ReceiverHub.sol";
import "./Permissions.sol";
import "./Pausable.sol";

abstract contract VaultNewReceivers is ReceiverHub, Permissions, Pausable {
  uint8 public immutable PERMISSION_DEPLOY_RECEIVER;

  constructor (uint8 _deployReceiverPermission) {
    PERMISSION_DEPLOY_RECEIVER = _deployReceiverPermission;

    _registerPermission(PERMISSION_DEPLOY_RECEIVER);
  }

  function deployReceivers(
    uint256[] calldata _receivers
  ) external notPaused onlyPermissioned(PERMISSION_DEPLOY_RECEIVER) {
    unchecked {
      uint256 receiversLength = _receivers.length;

      for (uint256 i = 0; i < receiversLength; ++i) {
        useReceiver(_receivers[i]);
      }
    }
  }

  function deployReceiversRange(
    uint256 _from,
    uint256 _to
  ) external notPaused onlyPermissioned(PERMISSION_DEPLOY_RECEIVER) {
    unchecked {
      for (uint256 i = _from; i < _to; ++i) {
        useReceiver(i);
      }
    }
  }
}
