// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import "./IGovernable.sol";

interface IKeep3rJob is IGovernable {
  // events
  event Keep3rSet(address _keep3r);

  // errors
  error KeeperNotValid();

  // variables
  function keep3r() external view returns (address _keep3r);

  // methods
  function setKeep3r(address _keep3r) external;
}
