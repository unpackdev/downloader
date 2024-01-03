//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

// Libraries
import "./Address.sol";
import "./AddressesLib.sol";
import "./RewardPeriodLib.sol";

// Contracts
import "./MigratorBase.sol";

// Interfaces
import "./IRewardPeriodsRegistry.sol";

contract RewardPeriodsRegistry is MigratorBase, IRewardPeriodsRegistry {
    using RewardPeriodLib for RewardPeriodLib.RewardPeriod;
    using AddressesLib for address[];
    using Address for address;

    /* State Variables */

    mapping(uint256 => RewardPeriodLib.RewardPeriod) internal periods;

    RewardPeriodLib.RewardPeriod[] public periodsList;

    /** Modifiers */

    /* Constructor */

    constructor(address settingsAddress) public MigratorBase(settingsAddress) {}

    function createRewardPeriod(
        uint256 startPeriodTimestamp,
        uint256 endPeriodTimestamp,
        uint256 endRedeemablePeriodTimestamp,
        uint256 availableRewards
    ) external override onlyOwner(msg.sender) {
        uint256 newPeriodId = 1;
        if (periodsList.length > 0) {
            RewardPeriodLib.RewardPeriod storage lastPeriod = _getLastRewardPeriod();
            require(!lastPeriod.isPending(), "ALREADY_PENDING_PERIOD_REWARD");

            if (lastPeriod.isInProgress()) {
                require(
                    lastPeriod.endsBefore(startPeriodTimestamp),
                    "IN_PROGRESS_PERIOD_OVERLAPPED"
                );
            }
            newPeriodId = lastPeriod.id + 1;
        }

        periods[newPeriodId].create(
            newPeriodId,
            startPeriodTimestamp,
            endPeriodTimestamp,
            endRedeemablePeriodTimestamp,
            availableRewards
        );
        periodsList.push(periods[newPeriodId]);

        emit RewardPeriodCreated(
            msg.sender,
            newPeriodId,
            startPeriodTimestamp,
            endPeriodTimestamp,
            endRedeemablePeriodTimestamp,
            availableRewards
        );
    }

    function notifyRewardsSent(uint256 period, uint256 totalRewardsSent)
        external
        override
        onlyMinter(msg.sender)
        returns (uint256 newTotalAvailableRewards)
    {
        periods[period].notifyRewardsSent(totalRewardsSent);
        return periods[period].availableRewards;
    }

    function getRewardPeriod(uint256 id)
        external
        view
        override
        returns (RewardPeriodLib.RewardPeriod memory)
    {
        return periods[id];
    }

    function getRewardPeriods()
        external
        view
        override
        returns (RewardPeriodLib.RewardPeriod[] memory)
    {
        return periodsList;
    }

    function getLastRewardPeriod()
        external
        view
        override
        returns (
            uint256 periodId,
            uint256 startPeriodTimestamp,
            uint256 endPeriodTimestamp,
            uint256 endRedeemablePeriodTimestamp,
            uint256 totalRewards,
            uint256 availableRewards,
            bool exists
        )
    {
        RewardPeriodLib.RewardPeriod memory rewardPeriod = _getLastRewardPeriod();
        return (
            rewardPeriod.id,
            rewardPeriod.startPeriodTimestamp,
            rewardPeriod.endPeriodTimestamp,
            rewardPeriod.endRedeemablePeriodTimestamp,
            rewardPeriod.totalRewards,
            rewardPeriod.availableRewards,
            rewardPeriod.exists
        );
    }

    function getRewardPeriodById(uint256 periodId)
        external
        view
        override
        returns (
            uint256 id,
            uint256 startPeriodTimestamp,
            uint256 endPeriodTimestamp,
            uint256 endRedeemablePeriodTimestamp,
            uint256 totalRewards,
            uint256 availableRewards,
            bool exists
        )
    {
        RewardPeriodLib.RewardPeriod memory rewardPeriod = _getRewardPeriodById(periodId);
        return (
            rewardPeriod.id,
            rewardPeriod.startPeriodTimestamp,
            rewardPeriod.endPeriodTimestamp,
            rewardPeriod.endRedeemablePeriodTimestamp,
            rewardPeriod.totalRewards,
            rewardPeriod.availableRewards,
            rewardPeriod.exists
        );
    }

    function settings() external view override returns (address) {
        return address(_settings());
    }

    /** Internal Functions */

    function _getLastRewardPeriod() internal view returns (RewardPeriodLib.RewardPeriod storage) {
        return periodsList.length > 0 ? periodsList[periodsList.length - 1] : periods[0];
    }

    function _getRewardPeriodById(uint256 periodId)
        internal
        view
        returns (RewardPeriodLib.RewardPeriod storage)
    {
        return periods[periodId];
    }
}
