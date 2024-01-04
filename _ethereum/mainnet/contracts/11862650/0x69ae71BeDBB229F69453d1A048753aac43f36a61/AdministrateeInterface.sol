// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./FixedPoint.sol";

interface AdministrateeInterface {
  function emergencyShutdown() external;

  function remargin() external;

  function pfc() external view returns (FixedPoint.Unsigned memory);
}
