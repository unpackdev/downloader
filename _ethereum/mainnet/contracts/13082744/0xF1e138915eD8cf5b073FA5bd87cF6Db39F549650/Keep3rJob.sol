// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4 <0.9.0;

import "./Governable.sol";
import "./IKeep3rJob.sol";
import "./IKeep3rV1.sol";

abstract contract Keep3rJob is IKeep3rJob, Governable {
  address public override keep3r;
  address public override requiredBond;
  uint256 public override requiredMinBond;
  uint256 public override requiredEarnings;
  uint256 public override requiredAge;
  bool public override requiredEOA;

  constructor(
    address _keep3r,
    address _bond,
    uint256 _minBond,
    uint256 _earned,
    uint256 _age,
    bool _onlyEOA
  ) {
    keep3r = _keep3r;
    requiredBond = _bond;
    requiredMinBond = _minBond;
    requiredEarnings = _earned;
    requiredAge = _age;
    requiredEOA = _onlyEOA;
  }

  function setKeep3r(address _keep3r) public override onlyGovernor {
    keep3r = _keep3r;
    emit Keep3rSet(_keep3r);
  }

  function setKeep3rRequirements(
    address _bond,
    uint256 _minBond,
    uint256 _earned,
    uint256 _age,
    bool _onlyEOA
  ) public override onlyGovernor {
    requiredBond = _bond;
    requiredMinBond = _minBond;
    requiredEarnings = _earned;
    requiredAge = _age;
    requiredEOA = _onlyEOA;
    emit Keep3rRequirementsSet(_bond, _minBond, _earned, _age, _onlyEOA);
  }

  modifier validateAndPayKeeper(address _keeper) {
    _isValidKeeper(_keeper);
    _;
    IKeep3rV1(keep3r).worked(_keeper);
  }

  function _isValidKeeper(address _keeper) internal {
    // solhint-disable-next-line avoid-tx-origin
    if (requiredEOA && _keeper != tx.origin) revert KeeperNotEOA();

    if (requiredMinBond == 0 && requiredEarnings == 0 && requiredAge == 0) {
      if (!IKeep3rV1(keep3r).isKeeper(_keeper)) revert KeeperNotRegistered();
    } else {
      if (requiredBond == address(0)) {
        if (!IKeep3rV1(keep3r).isMinKeeper(_keeper, requiredMinBond, requiredEarnings, requiredAge)) revert KeeperNotValid();
      } else {
        if (!IKeep3rV1(keep3r).isBondedKeeper(_keeper, requiredBond, requiredMinBond, requiredEarnings, requiredAge)) revert KeeperNotValid();
      }
    }
  }
}
