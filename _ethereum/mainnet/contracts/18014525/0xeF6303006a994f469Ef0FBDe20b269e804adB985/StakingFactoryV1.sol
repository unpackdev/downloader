// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IStakingFactoryV1.sol";
import "./StakingV1.sol";
import "./StakingTokenV1.sol";
import "./Authorizable.sol";
import "./Pausable.sol";

// staking types:
// 0 - eth reflection
// 1 - token reflection

contract StakingFactoryV1 is IStakingFactoryV1, Authorizable, Pausable {
  constructor() Authorizable(_msgSender()) {}

  function createStaking(
    uint8 stakingType_,
    address tokenAddress_,
    uint16 lockDurationDays_,
    uint256[] memory typeData_
  ) external virtual override onlyAuthorized onlyNotPaused returns (address) {
    require(stakingType_ < 2, "Invalid staking type");

    StakingV1 stakingContract;

    if (stakingType_ == 0) {
      // eth reflection
      stakingContract = new StakingV1(
        _msgSender(),
        tokenAddress_,
        lockDurationDays_
      );
    } else if (stakingType_ == 1) {
      // token reflection
      stakingContract = new StakingTokenV1(
        _msgSender(),
        tokenAddress_,
        // typeData_[0] is the rewards token address
        address(uint160(typeData_[0])),
        lockDurationDays_
      );
    }

    // TODO implement release-over-time staking contracts,
    // or add that functionality to the existing contracts

    return address(stakingContract);
  }
}
