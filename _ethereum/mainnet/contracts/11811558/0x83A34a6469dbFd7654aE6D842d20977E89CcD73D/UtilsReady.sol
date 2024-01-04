// SPDX-License-Identifier: MIT

pragma solidity >=0.6.8;

import "./Governable.sol";
import "./CollectableDust.sol";
import "./Pausable.sol";
import "./Migratable.sol";

abstract
contract UtilsReady is Governable, CollectableDust, Pausable, Migratable {

  constructor() public Governable(msg.sender) {
  }

  // Governable: restricted-access
  function setPendingGovernor(address _pendingGovernor) external override onlyGovernor {
    _setPendingGovernor(_pendingGovernor);
  }

  function acceptGovernor() external override onlyPendingGovernor {
    _acceptGovernor();
  }

  // Collectable Dust: restricted-access
  function sendDust(
    address _to,
    address _token,
    uint256 _amount
  ) external override virtual onlyGovernor {
    _sendDust(_to, _token, _amount);
  }

  // Pausable: restricted-access
  function pause(bool _paused) external override onlyGovernor {
    _pause(_paused);
  }

  // Migratable: restricted-access
  function migrate(address _to) external onlyGovernor {
      _migrated(_to);
  }

}
