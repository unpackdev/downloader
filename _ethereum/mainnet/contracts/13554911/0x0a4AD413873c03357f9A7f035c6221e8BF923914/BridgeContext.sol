// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "./BridgeBeams.sol";
import "./Extractable.sol";

contract BridgeContext is Extractable {
  using BridgeBeams for BridgeBeams.Project;
  using BridgeBeams for BridgeBeams.ProjectState;
  using BridgeBeams for BridgeBeams.ReserveParameters;
}
