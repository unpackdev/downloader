//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.6.12;

// Contracts
import "./MigratorBase.sol";

// Interfaces
import "./IMintableERC20.sol";
import "./IRewardsCalculator.sol";
import "./IRewardsMinter.sol";
import "./IRewardPeriodsRegistry.sol";

// Libraries
import "./SafeMath.sol";
import "./RewardCalculatorLib.sol";
import "./AddressesLib.sol";

contract RewardsMinter is MigratorBase, IRewardsMinter {
    using RewardCalculatorLib for RewardCalculatorLib.RewardCalculator;
    using AddressesLib for address[];
    using SafeMath for uint256;

    /* Constant Variables */
    uint256 private constant MAX_PERCENTAGE = 10000;

    /* State Variables */

    IMintableERC20 public override token;

    mapping(address => RewardCalculatorLib.RewardCalculator) public calculators;

    uint256 public override currentPercentage;

    address[] public calculatorsList;

    address public override rewardPeriodsRegistry;

    /* Modifiers */

    /* Constructor */

    constructor(
        address rewardPeriodsRegistryAddress,
        address settingsAddress,
        address tokenAddress
    ) public MigratorBase(settingsAddress) {
        require(rewardPeriodsRegistryAddress.isContract(), "PERIODS_REG_MUST_BE_CONTRACT");
        require(tokenAddress.isContract(), "TOKEN_MUST_BE_CONTRACT");

        rewardPeriodsRegistry = rewardPeriodsRegistryAddress;
        token = IMintableERC20(tokenAddress);
    }

    function claimRewards(uint256 periodId) external override {
        _settings().requireIsNotPaused();
        require(currentPercentage == MAX_PERCENTAGE, "CURRENT_PERCENTAGE_INVALID");

        (
            uint256 id,
            ,
            uint256 endPeriodTimestamp,
            uint256 endRedeemablePeriodTimestamp,
            ,
            uint256 availableRewards,
            bool exists
        ) = _getRewardPeriod(periodId);
        require(exists, "PERIOD_ID_NOT_EXISTS");
        require(endPeriodTimestamp < block.timestamp, "REWARD_PERIOD_IN_PROGRESS");
        require(endRedeemablePeriodTimestamp > block.timestamp, "CLAIMABLE_PERIOD_FINISHED");

        address account = msg.sender;
        uint256 totalRewardsSent = 0;
        for (uint256 indexAt = 0; indexAt < calculatorsList.length; indexAt++) {
            IRewardsCalculator rewardsCalculator = IRewardsCalculator(calculatorsList[indexAt]);

            uint256 calculatorPercentage = calculators[calculatorsList[indexAt]].getPercentage();
            /*
                Available Rewards: 1000
                Calculator Percentage: 5000
                Calculator Available Rewards = 1000 * 5000 / 100
            */
            uint256 calculatorAvailableRewards =
                availableRewards.mul(calculatorPercentage).div(100);

            uint256 availableRewardsForAcount =
                rewardsCalculator.processRewards(
                    id,
                    account,
                    availableRewards,
                    calculatorAvailableRewards
                );
            totalRewardsSent = totalRewardsSent.add(availableRewardsForAcount);
            if (availableRewardsForAcount > 0) {
                token.mint(account, availableRewardsForAcount);
            }
        }
        if (totalRewardsSent > 0) {
            _notifyRewardsSent(id, totalRewardsSent);
            emit RewardsClaimed(account, id, totalRewardsSent);
        }
    }

    function updateCalculatorPercentage(address calculator, uint256 percentage)
        external
        override
        onlyOwner(msg.sender)
    {
        require(calculators[calculator].exists, "CALCULATOR_ISNT_ADDED");
        uint256 oldPercentage = calculators[calculator].percentage;

        uint256 newCurrentPercentage = currentPercentage.sub(oldPercentage).add(percentage);
        require(newCurrentPercentage <= MAX_PERCENTAGE, "ACCUM_PERCENTAGE_EXCEEDS_MAX");

        calculators[calculator].update(percentage);

        currentPercentage = newCurrentPercentage;

        emit CalculatorPercentageUpdated(msg.sender, calculator, percentage, currentPercentage);
    }

    function addCalculator(address newCalculator, uint256 percentage)
        external
        override
        onlyOwner(msg.sender)
    {
        require(newCalculator.isContract(), "NEW_CALCULATOR_MUST_BE_CONTRACT");
        require(!calculators[newCalculator].exists, "CALCULATOR_ALREADY_ADDED");
        uint256 newCurrentPercentage = currentPercentage.add(percentage);
        require(newCurrentPercentage <= MAX_PERCENTAGE, "ACCUM_PERCENTAGE_EXCEEDS_MAX");

        calculators[newCalculator].create(percentage);
        calculatorsList.add(newCalculator);

        currentPercentage = newCurrentPercentage;

        emit NewCalculatorAdded(msg.sender, newCalculator, percentage, currentPercentage);
    }

    function removeCalculator(address calculator) external override onlyOwner(msg.sender) {
        require(calculators[calculator].exists, "CALCULATOR_DOESNT_EXIST");
        uint256 percentage = calculators[calculator].percentage;

        calculatorsList.remove(calculator);
        calculators[calculator].remove();

        currentPercentage = currentPercentage.sub(percentage);

        emit CalculatorRemoved(msg.sender, calculator, percentage, currentPercentage);
    }

    /** View Functions */

    function settings() external view override returns (address) {
        return address(_settings());
    }

    function getAvailableRewards(uint256 periodId, address account)
        external
        view
        override
        returns (uint256)
    {
        if (currentPercentage != MAX_PERCENTAGE) {
            return 0;
        }
        (
            uint256 id,
            uint256 startPeriodTimestamp,
            ,
            uint256 endRedeemablePeriodTimestamp,
            ,
            uint256 availableRewards,
            bool exists
        ) = _getRewardPeriod(periodId);
        if (
            !exists ||
            startPeriodTimestamp > block.timestamp ||
            endRedeemablePeriodTimestamp < block.timestamp
        ) {
            return 0;
        }

        uint256 rewardsForAccount = 0;
        for (uint256 indexAt = 0; indexAt < calculatorsList.length; indexAt++) {
            IRewardsCalculator rewardsCalculator = IRewardsCalculator(calculatorsList[indexAt]);

            uint256 calculatorPercentage = calculators[calculatorsList[indexAt]].getPercentage();
            /*
                Available Rewards: 1000
                Calculator Percentage: 5000
                Calculator Available Rewards = 1000 * 5000 / 100
            */
            uint256 calculatorAvailableRewards =
                availableRewards.mul(calculatorPercentage).div(100);

            uint256 availableRewardsForAcount =
                rewardsCalculator.getRewards(
                    id,
                    account,
                    availableRewards,
                    calculatorAvailableRewards
                );
            rewardsForAccount = rewardsForAccount.add(availableRewardsForAcount);
        }
        return rewardsForAccount;
    }

    function getCalculators() external view override returns (address[] memory) {
        return calculatorsList;
    }

    function hasCalculator(address calculator) external view override returns (bool) {
        return calculators[calculator].exists;
    }

    /* Internal Functions */

    function _notifyRewardsSent(uint256 period, uint256 totalRewardsSent) internal {
        IRewardPeriodsRegistry rewardsRegistry = IRewardPeriodsRegistry(rewardPeriodsRegistry);
        rewardsRegistry.notifyRewardsSent(period, totalRewardsSent);
    }

    function _getRewardPeriod(uint256 periodId)
        internal
        view
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
        IRewardPeriodsRegistry rewardsRegistry = IRewardPeriodsRegistry(rewardPeriodsRegistry);
        (
            id,
            startPeriodTimestamp,
            endPeriodTimestamp,
            endRedeemablePeriodTimestamp,
            totalRewards,
            availableRewards,
            exists
        ) = rewardsRegistry.getRewardPeriodById(periodId);
    }
}
