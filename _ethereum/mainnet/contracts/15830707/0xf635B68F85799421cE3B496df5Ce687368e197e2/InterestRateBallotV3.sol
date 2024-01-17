// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";

import "./VotingEscrowCheckpoint.sol";
import "./CoreUtility.sol";
import "./SafeDecimalMath.sol";

import "./IBallot.sol";
import "./IFundV4.sol";
import "./ITwapOracleV2.sol";
import "./IVotingEscrow.sol";

contract InterestRateBallotV3 is IBallot, CoreUtility, VotingEscrowCheckpoint {
    using SafeMath for uint256;
    using SafeDecimalMath for uint256;

    event Voted(
        address indexed account,
        uint256 oldAmount,
        uint256 oldUnlockTime,
        uint256 oldWeight,
        uint256 amount,
        uint256 indexed unlockTime,
        uint256 indexed weight
    );

    IVotingEscrow public immutable votingEscrow;

    mapping(address => Voter) public voters;

    // unlockTime => amount that will be unlocked at unlockTime
    mapping(uint256 => uint256) public scheduledUnlock;
    mapping(uint256 => uint256) public veSupplyPerWeek;
    uint256 public totalLocked;
    uint256 public nextWeekSupply;

    mapping(uint256 => uint256) public weightedScheduledUnlock;
    mapping(uint256 => uint256) public weightedVeSupplyPerWeek;
    uint256 public weightedTotalLocked;
    uint256 public weightedNextWeekSupply;

    uint256 public checkpointWeek;

    constructor(address votingEscrow_)
        public
        VotingEscrowCheckpoint(IVotingEscrow(votingEscrow_).maxTime())
    {
        votingEscrow = IVotingEscrow(votingEscrow_);
        checkpointWeek = _endOfWeek(block.timestamp) - 1 weeks;
    }

    function getReceipt(address account) external view returns (Voter memory) {
        return voters[account];
    }

    function totalSupplyAtWeek(uint256 week) external view returns (uint256) {
        return _totalSupplyAtWeek(week);
    }

    function weightedTotalSupplyAtWeek(uint256 week) external view returns (uint256) {
        return _weightedTotalSupplyAtWeek(week);
    }

    function averageAtWeek(uint256 week) external view returns (uint256) {
        return _averageAtWeek(week);
    }

    /// @notice Return a fund's relative income since the last settlement. Note that denominators
    ///         of the returned ratios are the latest value instead of that at the last settlement.
    ///         If the amount of underlying token increases from 100 to 110 and assume that there's
    ///         no creation/redemption or underlying price change, return value `incomeOverQ` will
    ///         be 1/11 rather than 1/10.
    /// @param fund Address of the fund
    /// @param day End timestamp of a trading day
    /// @return incomeOverQ The ratio of income to the fund's total value
    /// @return incomeOverB The ratio of income to equivalent BISHOP total value if all QUEEN are split
    function getFundRelativeIncome(address fund, uint256 day)
        public
        view
        returns (uint256 incomeOverQ, uint256 incomeOverB)
    {
        (bool success, bytes memory encodedDay) =
            address(fund).staticcall(
                abi.encodeWithSelector(IFundV4.getRelativeIncome.selector, day)
            );
        if (!success || encodedDay.length != 0x40) {
            return (0, 0);
        } else {
            return abi.decode(encodedDay, (uint256, uint256));
        }
    }

    /// @notice Return the fraction of annualized relative income of the calling fund that should
    ///         be added to BISHOP NAV. Zero is returned when this function is not called by
    ///         an `IFundV3` contract or the fund is just rebalanced in the same block.
    function count(uint256 timestamp) external view override returns (uint256) {
        (, uint256 incomeOverB) = getFundRelativeIncome(msg.sender, timestamp);
        if (incomeOverB == 0) {
            return 0;
        } else {
            return
                incomeOverB.multiplyDecimal(_averageAtWeek(_endOfWeek(timestamp) - 1 weeks) * 365);
        }
    }

    function cast(uint256 weight) external {
        require(weight <= 1e18, "Invalid weight");

        IVotingEscrow.LockedBalance memory lockedBalance =
            votingEscrow.getLockedBalance(msg.sender);
        Voter memory voter = voters[msg.sender];
        require(
            lockedBalance.amount > 0 && lockedBalance.unlockTime > block.timestamp,
            "No veCHESS"
        );

        _checkpointAndUpdateLock(
            voter.amount,
            voter.unlockTime,
            voter.weight,
            lockedBalance.amount,
            lockedBalance.unlockTime,
            weight
        );

        emit Voted(
            msg.sender,
            voter.amount,
            voter.unlockTime,
            voter.weight,
            lockedBalance.amount,
            lockedBalance.unlockTime,
            weight
        );

        // update voter amount per account
        voters[msg.sender] = Voter({
            amount: lockedBalance.amount,
            unlockTime: lockedBalance.unlockTime,
            weight: weight
        });
    }

    function syncWithVotingEscrow(address account) external override {
        Voter memory voter = voters[account];
        if (voter.amount == 0) {
            return; // The account did not voted before
        }

        IVotingEscrow.LockedBalance memory lockedBalance = votingEscrow.getLockedBalance(account);
        if (lockedBalance.unlockTime <= block.timestamp) {
            return;
        }

        _checkpointAndUpdateLock(
            voter.amount,
            voter.unlockTime,
            voter.weight,
            lockedBalance.amount,
            lockedBalance.unlockTime,
            voter.weight
        );

        emit Voted(
            account,
            voter.amount,
            voter.unlockTime,
            voter.weight,
            lockedBalance.amount,
            lockedBalance.unlockTime,
            voter.weight
        );

        // update voter amount per account
        voters[account].amount = lockedBalance.amount;
        voters[account].unlockTime = lockedBalance.unlockTime;
    }

    function _totalSupplyAtWeek(uint256 week) private view returns (uint256) {
        return
            week <= checkpointWeek
                ? veSupplyPerWeek[week]
                : _veTotalSupplyAtWeek(
                    week,
                    scheduledUnlock,
                    checkpointWeek,
                    nextWeekSupply,
                    totalLocked
                );
    }

    function _weightedTotalSupplyAtWeek(uint256 week) private view returns (uint256) {
        return
            week <= checkpointWeek
                ? weightedVeSupplyPerWeek[week]
                : _veTotalSupplyAtWeek(
                    week,
                    weightedScheduledUnlock,
                    checkpointWeek,
                    weightedNextWeekSupply,
                    weightedTotalLocked
                );
    }

    function _averageAtWeek(uint256 week) private view returns (uint256) {
        uint256 total = _totalSupplyAtWeek(week);
        if (total == 0) {
            return 0.5e18;
        }
        return _weightedTotalSupplyAtWeek(week) / total;
    }

    function _checkpointAndUpdateLock(
        uint256 oldAmount,
        uint256 oldUnlockTime,
        uint256 oldWeight,
        uint256 newAmount,
        uint256 newUnlockTime,
        uint256 newWeight
    ) private {
        uint256 oldCheckpointWeek = checkpointWeek;
        (, uint256 newNextWeekSupply, uint256 newTotalLocked) =
            _veCheckpoint(
                scheduledUnlock,
                oldCheckpointWeek,
                nextWeekSupply,
                totalLocked,
                veSupplyPerWeek
            );
        (nextWeekSupply, totalLocked) = _veUpdateLock(
            newNextWeekSupply,
            newTotalLocked,
            oldAmount,
            oldUnlockTime,
            newAmount,
            newUnlockTime,
            scheduledUnlock
        );
        uint256 newWeightedNextWeekSupply;
        uint256 newWeightedTotalLocked;
        (checkpointWeek, newWeightedNextWeekSupply, newWeightedTotalLocked) = _veCheckpoint(
            weightedScheduledUnlock,
            oldCheckpointWeek,
            weightedNextWeekSupply,
            weightedTotalLocked,
            weightedVeSupplyPerWeek
        );
        (weightedNextWeekSupply, weightedTotalLocked) = _veUpdateLock(
            newWeightedNextWeekSupply,
            newWeightedTotalLocked,
            oldAmount * oldWeight,
            oldUnlockTime,
            newAmount * newWeight,
            newUnlockTime,
            weightedScheduledUnlock
        );
    }
}
