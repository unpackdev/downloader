// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import "./Keep3rJob.sol";
import "./IKeep3rBondedJob.sol";

abstract contract Keep3rBondedJob is Keep3rJob, IKeep3rBondedJob {
  address public override requiredBond = 0x1cEB5cB57C4D4E2b2433641b95Dd330A33185A44;
  uint256 public override requiredMinBond = 50 ether;
  uint256 public override requiredEarnings;
  uint256 public override requiredAge;

  function setKeep3rRequirements(
    address _bond,
    uint256 _minBond,
    uint256 _earned,
    uint256 _age
  ) public override onlyGovernor {
    requiredBond = _bond;
    requiredMinBond = _minBond;
    requiredEarnings = _earned;
    requiredAge = _age;
    emit Keep3rRequirementsSet(_bond, _minBond, _earned, _age);
  }

  function _isValidKeeper(address _keeper) internal virtual override {
    if (!IKeep3rV2(keep3r).isBondedKeeper(_keeper, requiredBond, requiredMinBond, requiredEarnings, requiredAge)) revert KeeperNotValid();
  }
}
