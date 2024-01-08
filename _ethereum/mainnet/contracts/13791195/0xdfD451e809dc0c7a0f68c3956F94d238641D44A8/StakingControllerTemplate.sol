// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
import "./StakingControllerLib.sol";
import "./SafeMathUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ViewExecutor.sol";

contract StakingControllerTemplate is OwnableUpgradeable {
    using SafeMathUpgradeable for *;
    StakingControllerLib.Isolate isolate;

    function currentCycle() public view returns (uint256 cycle) {
        cycle = isolate.currentCycle;
    }

    function commitmentViolationPenalty()
        public
        view
        returns (uint256 penalty)
    {
        penalty = isolate.commitmentViolationPenalty;
    }

    function dailyBonusesAccrued(address user)
        public
        view
        returns (uint256 amount)
    {
        amount = isolate.dailyBonusesAccrued[user];
    }
}
