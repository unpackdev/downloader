// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4 <0.9.0;

import "./IGovernable.sol";

interface IKeep3rJob is IGovernable {
  // events
  event Keep3rSet(address _keep3r);
  event Keep3rRequirementsSet(address _bond, uint256 _minBond, uint256 _earned, uint256 _age, bool _onlyEOA);

  // errors
  error KeeperNotEOA();
  error KeeperNotRegistered();
  error KeeperNotValid();

  // variables
  function keep3r() external view returns (address _keep3r);

  function requiredBond() external view returns (address _requiredBond);

  function requiredMinBond() external view returns (uint256 _requiredMinBond);

  function requiredEarnings() external view returns (uint256 _requiredEarnings);

  function requiredAge() external view returns (uint256 _requiredAge);

  function requiredEOA() external view returns (bool _requiredEOA);

  // methods
  function setKeep3r(address _keep3r) external;

  function setKeep3rRequirements(
    address _bond,
    uint256 _minBond,
    uint256 _earned,
    uint256 _age,
    bool _onlyEOA
  ) external;
}
