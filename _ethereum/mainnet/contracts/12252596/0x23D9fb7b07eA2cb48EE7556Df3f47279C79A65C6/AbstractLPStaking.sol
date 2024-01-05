// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./LowGasSafeMath.sol";
import "./FullMath.sol";
import "./UnsafeMath.sol";
import "./Math.sol";
import "./IERC20.sol";

abstract contract AbstractLPStaking is Ownable, ReentrancyGuard {
    using LowGasSafeMath for uint;

    mapping(uint => uint) public stakedPerTerm; // how much staked per term
    uint public totalStaked = 0; // total staked

    // Stakeholders info
    mapping(address => uint) internal staking_amount; // staking amounts
    mapping(address => uint) internal staking_rewards; // rewards
    mapping(address => uint) internal staking_stakedAt; // timestamp of staking
    mapping(address => uint) internal staking_length; // staking term

    mapping(address => uint) internal rewards_paid; // paid rewards
    mapping(address => uint) internal streaming_rewards; // streaming rewards
    mapping(address => uint) internal streaming_rewards_calculated; // when streaming calculated last time
    mapping(address => uint) internal streaming_rewards_per_block; // how much to stream per block
    mapping(address => uint) internal unlocked_rewards; // rewards ready to be claimed

    mapping(address => uint) internal paid_rewardPerToken; // previous rewards per stake
    mapping(address => uint) internal paid_term2AdditionalRewardPerToken; // previous rewards per stake for additional term2

    address[] stake_holders; // array of stakeholders

    uint constant totalRewardPool = 410400 ether; // total rewards
    uint constant dailyRewardPool = 9120 ether; // total daily rewards
    uint constant hourlyRewardPool = 380 ether; // hourly rewards
    uint internal limitDays = 45 days; // how much days to pay rewards

    uint internal rewardsPerStakeCalculated; // last timestamp rewards per stake calculated
    uint internal term2AdditionalRewardsPerStakeStored; // rewards per stake for additional term2
    uint internal rewardsPerStakeStored; // rewards per stake
    uint internal createdAtSeconds; // when staking was created/initialized

    uint internal toStopAtSeconds = 0; // when will be stopped

    uint internal stoppedAtSeconds; // when staking was stopped
    bool internal isEnded = false; // was staking ended

    bool internal unlocked = false; // are all stakes are unlocked now

    uint constant estBlocksPerDay = 5_760; // estimated number of blocks per day
    uint constant estBlocksPerStreamingPeriod = 7 * estBlocksPerDay; // estimated number of blocks per streaming period

    IERC20 stakingToken; // staking ERC20 token
    IERC20 rewardsToken; // rewards ERC20 token

    modifier isNotLocked() {
        require(unlocked || staking_stakedAt[msg.sender] + staking_length[msg.sender] <= block.timestamp, "Stake is Locked");

        _;
    }

    modifier streaming(bool active) {
        if (active) {
            require(streaming_rewards[msg.sender] > 0, "Not streaming yet");
        } else {
            require(streaming_rewards[msg.sender] == 0, "Already streaming");
        }

        _;
    }

    modifier correctTerm(uint8 term) {
        require(term >= 0 && term <= 2, "Incorrect term specified");
        require(staking_length[msg.sender] == 0 || terms(term) == staking_length[msg.sender], "Cannot change term while stake is locked");

        _;
    }

    modifier stakingAllowed() {
        require(createdAtSeconds > 0, "Staking not started yet");
        require(block.timestamp > createdAtSeconds, "Staking not started yet");
        require(block.timestamp < toStopAtSeconds, "Staking is over");

        _;
    }

    uint constant term_0 = 15 days; // term 0 with 70% rewards
    uint constant term_1 = 30 days; // term 1 with 100% rewards
    uint constant term_2 = 45 days; // term 2 with additional rewards

    // term idx to time
    function terms(uint8 term) internal pure returns (uint) {
        if (term == 0) {
            return term_0;
        }
        if (term == 1) {
            return term_1;
        }
        if (term == 2) {
            return term_2;
        }

        return 0;
    }

    bool initialized = false;

    // initial contract initialization
    function initialize(
        address _stakingToken,
        address _rewardsToken
    ) external onlyOwner {
        require(!initialized, "Already initialized!");
        initialized = true;

        stakingToken = IERC20(_stakingToken);
        rewardsToken = IERC20(_rewardsToken);

        createdAtSeconds = block.timestamp;
        toStopAtSeconds = createdAtSeconds + limitDays * (1 days);
    }

    // --=[ calculation methods ]=--
    function _calcRewardsPerStake(uint staked, uint rewardsPool, uint __default) private view returns (uint) {
        if (staked == 0 || rewardsPerStakeCalculated >= block.timestamp) {
            return __default;
        }

        uint _hoursPassed = _calcHoursPassed(rewardsPerStakeCalculated);
        uint _totalRewards = _hoursPassed.mul(rewardsPool);

        return __default.add(
            FullMath.mulDiv(_totalRewards, 1e24, staked)
        );
    }

    function _calcRewardsPerStake() internal view returns (uint) {
        return _calcRewardsPerStake(totalStaked, hourlyRewardPool, rewardsPerStakeStored);
    }

    function _calcTerm2AdditionalRewardsPerStake() internal view returns (uint) {
        uint totalStaked_0 = stakedPerTerm[term_0];
        (,uint nonTakenRewards) = _calcTerm0Rewards(totalStaked_0.mul(_calcRewardsPerStake().sub(paid_rewardPerToken[address(0)])));

        return _calcRewardsPerStake(totalStaked_0, nonTakenRewards, term2AdditionalRewardsPerStakeStored);
    }

    function _calcTerm0Rewards(uint reward) internal pure returns (uint _earned, uint _non_taken) {
        uint a = FullMath.mulDiv(reward, 70, 100);
        // Staking term_0 earns 70% of the rewards
        _non_taken = reward.sub(a);
        // Keep the rest to spare with term_2 stakeholders
        _earned = a;
    }

    function _calcHoursPassed(uint _lastRewardsTime) internal view returns (uint hoursPassed) {
        if (isEnded) {
            hoursPassed = stoppedAtSeconds.sub(_lastRewardsTime) / (1 hours);
        } else if (limitDaysGone()) {
            hoursPassed = toStopAtSeconds.sub(_lastRewardsTime) / (1 hours);
        } else if (limitRewardsGone()) {
            hoursPassed = allowedRewardHrsFrom(_lastRewardsTime);
        } else {
            hoursPassed = block.timestamp.sub(_lastRewardsTime) / (1 hours);
        }
    }

    function lastCallForRewards() internal view returns (uint) {
        if (isEnded) {
            return stoppedAtSeconds;
        } else if (limitDaysGone()) {
            return toStopAtSeconds;
        } else if (limitRewardsGone()) {
            return createdAtSeconds.add(allowedRewardHrsFrom(rewardsPerStakeCalculated));
        } else {
            return block.timestamp;
        }
    }

    function limitDaysGone() internal view returns (bool) {
        return limitDays > 0 && block.timestamp >= toStopAtSeconds;
    }

    function limitRewardsGone() internal view returns (bool) {
        return totalRewardPool > 0 && totalRewards() >= totalRewardPool;
    }

    function allowedRewardHrsFrom(uint _from) internal view returns (uint) {
        uint timePassed = _from.sub(createdAtSeconds) / 1 hours;
        uint paidRewards = FullMath.mulDiv(FullMath.mulDiv(dailyRewardPool, 1e24, 1 hours), timePassed, 1e24);

        return UnsafeMath.divRoundingUp(totalRewardPool.sub(paidRewards), hourlyRewardPool);
    }

    function _newEarned(address account) internal view returns (uint _earned) {
        uint _staked = staking_amount[account];
        _earned = _staked.mul(_calcRewardsPerStake().sub(paid_rewardPerToken[account]));

        if (staking_length[account] == term_0) {
            (_earned,) = _calcTerm0Rewards(_earned);
        } else if (staking_length[account] == term_2) {
            uint term2AdditionalRewardsPerStake = UnsafeMath.divRoundingUp(_calcTerm2AdditionalRewardsPerStake(), 1e24);

            _earned = _earned.add(_staked.mul(term2AdditionalRewardsPerStake.sub(paid_term2AdditionalRewardPerToken[account])));
        }
    }

    function _unlockedRewards(address stakeholder) internal view returns (uint) {
        uint _unlocked = 0;

        if (streaming_rewards[stakeholder] > 0) {
            uint blocksPassed = block.number.sub(streaming_rewards_calculated[stakeholder]);
            _unlocked = Math.min(blocksPassed.mul(streaming_rewards_per_block[stakeholder]), streaming_rewards[stakeholder]);
        }

        return _unlocked;
    }

    function updateRewards(address stakeholder) internal {
        rewardsPerStakeStored = _calcRewardsPerStake();
        term2AdditionalRewardsPerStakeStored = _calcTerm2AdditionalRewardsPerStake();
        rewardsPerStakeCalculated = lastCallForRewards();

        staking_rewards[stakeholder] = UnsafeMath.divRoundingUp(_newEarned(stakeholder), 1e24).add(staking_rewards[stakeholder]);

        paid_rewardPerToken[stakeholder] = rewardsPerStakeStored;
        paid_rewardPerToken[address(0)] = rewardsPerStakeStored;
        if (staking_length[stakeholder] == term_2) {
            paid_term2AdditionalRewardPerToken[stakeholder] = term2AdditionalRewardsPerStakeStored;
        }

        if (streaming_rewards[stakeholder] > 0) {
            uint blocksPassed = block.number.sub(streaming_rewards_calculated[stakeholder]);
            uint _unlocked = Math.min(blocksPassed.mul(streaming_rewards_per_block[stakeholder]), streaming_rewards[stakeholder]);
            unlocked_rewards[stakeholder] = unlocked_rewards[stakeholder].add(_unlocked);
            streaming_rewards[stakeholder] = streaming_rewards[stakeholder].sub(_unlocked);
            streaming_rewards_calculated[stakeholder] = block.number;
        }
    }

    // --=[ public methods ]=--
    function totalRewards() public view returns (uint256 total) {
        uint256 timeEnd = block.timestamp;
        if (isEnded) {
            timeEnd = stoppedAtSeconds;
        } else if (limitDays > 0 && block.timestamp > toStopAtSeconds) {
            timeEnd = toStopAtSeconds;
        }

        uint256 timePassed = timeEnd.sub(createdAtSeconds) / 1 hours;
        total = FullMath.mulDiv(FullMath.mulDiv(dailyRewardPool, 1e24, 1 hours), timePassed, 1e24);

        if (totalRewardPool > 0 && total > totalRewardPool) {
            total = totalRewardPool;
        }
    }

    function finalizeEmergency() external onlyOwner {
        // give out all stakes
        uint _stakeholders_length = stake_holders.length;
        for (uint s = 0; s < _stakeholders_length; s += 1) {
            address stakeholder = stake_holders[s];
            stakingToken.transfer(stakeholder, staking_amount[stakeholder]);
        }

        uint256 stakingTokenBalance = stakingToken.balanceOf(address(this));
        if (stakingTokenBalance > 0) {
            stakingToken.transfer(owner(), stakingTokenBalance);
        }

        uint256 rewardsTokenBalance = rewardsToken.balanceOf(address(this));
        if (rewardsTokenBalance > 0) {
            rewardsToken.transfer(owner(), rewardsTokenBalance);
        }

        selfdestruct(payable(owner()));
    }
}
