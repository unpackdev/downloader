//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

// Contracts
import "./Base.sol";
import "./RewardsCalculatorBase.sol";

// Libraries
import "./AccountRewardsLib.sol";

// Interfaces
import "./IRewardsCalculator.sol";

contract ManualPGURewardsCalculator is Base, RewardsCalculatorBase, IRewardsCalculator {
    using AccountRewardsLib for AccountRewardsLib.AccountRewards;

    /* Events */

    event ManualRewardsUpdated(
        address indexed updater,
        uint256 period,
        address account,
        uint256 amount
    );

    /* State Variables */
    mapping(uint256 => mapping(address => AccountRewardsLib.AccountRewards)) private rewards;

    /* Constructor */

    constructor(address settingsAddress, address rewardsMinterAddress)
        public
        Base(settingsAddress)
    {
        _setRewardsMinter(rewardsMinterAddress);
    }

    function setMultiRewardsForPeriod(
        uint256 rewardsPeriod,
        address[] calldata accounts,
        uint256[] calldata amounts
    ) external onlyOwner(msg.sender) {
        require(accounts.length == amounts.length, "ARRAY_LENGTHS_NOT_EQUAL");
        for (uint256 i = 0; i < accounts.length; i++) {
            _setRewardsForPeriod(rewardsPeriod, accounts[i], amounts[i]);
        }
    }

    function removeMultiRewardsForPeriod(uint256 rewardsPeriod, address[] calldata accounts)
        external
        onlyOwner(msg.sender)
    {
        for (uint256 i = 0; i < accounts.length; i++) {
            _removeRewardsForPeriod(rewardsPeriod, accounts[i]);
        }
    }

    function processRewards(
        uint256 period,
        address account,
        uint256 totalRewards,
        uint256 totalAvailableRewards
    ) external override onlyRewardsMinter(msg.sender) returns (uint256 rewardsForAccount) {
        rewardsForAccount = _getRewards(period, account, totalRewards, totalAvailableRewards);
        if (rewardsForAccount > 0) {
            rewards[period][account].claimRewards(rewardsForAccount);
        }
    }

    /* View Functions */

    function getRewards(
        uint256 period,
        address account,
        uint256 totalRewards,
        uint256 totalAvailableRewards
    ) external view override returns (uint256) {
        return _getRewards(period, account, totalRewards, totalAvailableRewards);
    }

    function getAccountRewardsFor(uint256 period, address account)
        external
        view
        returns (AccountRewardsLib.AccountRewards memory)
    {
        return rewards[period][account];
    }

    /* Internal Functions */

    function _getRewards(
        uint256 period,
        address account,
        uint256,
        uint256 totalAvailableRewards
    ) internal view returns (uint256 rewardsForAccount) {
        rewardsForAccount = rewards[period][account].available;
        require(totalAvailableRewards >= rewardsForAccount, "NOT_ENOUGH_TOTAL_AVAILAB_REWARDS");
    }

    function _setRewardsForPeriod(
        uint256 rewardsPeriod,
        address account,
        uint256 amount
    ) internal {
        rewards[rewardsPeriod][account].create(account, amount);

        emit ManualRewardsUpdated(msg.sender, rewardsPeriod, account, amount);
    }

    function _removeRewardsForPeriod(uint256 rewardsPeriod, address account) internal {
        rewards[rewardsPeriod][account].remove();

        emit ManualRewardsUpdated(msg.sender, rewardsPeriod, account, 0);
    }
}
