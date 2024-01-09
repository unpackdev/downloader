// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import "./IKeep3rJob.sol";

interface IKeep3rBondedJob is IKeep3rJob {
  // Events

  event Keep3rRequirementsSet(address _bond, uint256 _minBond, uint256 _earned, uint256 _age);

  // Variables

  function requiredBond() external view returns (address _requiredBond);

  function requiredMinBond() external view returns (uint256 _requiredMinBond);

  function requiredEarnings() external view returns (uint256 _requiredEarnings);

  function requiredAge() external view returns (uint256 _requiredAge);

  // Methods

  function setKeep3rRequirements(
    address _bond,
    uint256 _minBond,
    uint256 _earned,
    uint256 _age
  ) external;
}
