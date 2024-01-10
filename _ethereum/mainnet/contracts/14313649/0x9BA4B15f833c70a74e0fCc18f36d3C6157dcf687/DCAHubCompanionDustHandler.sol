// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

import "./DCAHubCompanionParameters.sol";
import "./CollectableDust.sol";

abstract contract DCAHubCompanionDustHandler is DCAHubCompanionParameters, CollectableDust, IDCAHubCompanionDustHandler {
  function sendDust(
    address _to,
    address _token,
    uint256 _amount
  ) external onlyGovernor {
    _sendDust(_to, _token, _amount);
  }
}
