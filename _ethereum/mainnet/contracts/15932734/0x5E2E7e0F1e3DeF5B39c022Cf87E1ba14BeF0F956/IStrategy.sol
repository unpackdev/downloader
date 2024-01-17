// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import "./ZeroBTCStorage.sol";

interface IStrategy {
  function manage(GlobalState old) external returns (GlobalState state);
}
