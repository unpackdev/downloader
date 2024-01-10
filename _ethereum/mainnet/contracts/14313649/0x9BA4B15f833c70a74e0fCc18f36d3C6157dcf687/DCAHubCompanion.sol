// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

import "./DCAHubCompanionParameters.sol";
import "./DCAHubCompanionSwapHandler.sol";
import "./DCAHubCompanionWTokenPositionHandler.sol";
import "./DCAHubCompanionDustHandler.sol";
import "./DCAHubCompanionLibrariesHandler.sol";
import "./DCAHubCompanionMulticallHandler.sol";

contract DCAHubCompanion is
  DCAHubCompanionParameters,
  DCAHubCompanionSwapHandler,
  DCAHubCompanionWTokenPositionHandler,
  DCAHubCompanionDustHandler,
  DCAHubCompanionLibrariesHandler,
  DCAHubCompanionMulticallHandler,
  IDCAHubCompanion
{
  constructor(
    IDCAHub _hub,
    IWrappedProtocolToken _wToken,
    address _governor
  ) DCAHubCompanionParameters(_hub, _hub.permissionManager(), _wToken, _governor) {}
}
