// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import "./Governable.sol";
import "./IKeep3rJob.sol";
import "./IKeep3rV2.sol";

abstract contract Keep3rJob is IKeep3rJob, Governable {
  address public override keep3r = 0x4A6cFf9E1456eAa3b6f37572395C6fa0c959edAB;

  function setKeep3r(address _keep3r) public override onlyGovernor {
    keep3r = _keep3r;
    emit Keep3rSet(_keep3r);
  }

  function _isValidKeeper(address _keeper) internal virtual {
    if (!IKeep3rV2(keep3r).isKeeper(_keeper)) revert KeeperNotValid();
  }

  modifier upkeep() {
    _isValidKeeper(msg.sender);
    _;
    IKeep3rV2(keep3r).worked(msg.sender);
  }
}
