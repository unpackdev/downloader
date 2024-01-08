pragma solidity 0.7.6;

import "./IERC20.sol";

contract StakingRewardsState {

    IERC20 public rewardsToken;
    IERC20 public stakingToken;
    uint256 public periodFinish ;
    uint256 public rewardRate;
    uint256 public rewardsDuration;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    uint256 _totalSupply;
    mapping(address => uint256) _balances;
    // Bonus data
    mapping( uint16 => mapping(address => uint256)) userLongTermStakeInPeriod;
    mapping(address => uint256) userLastLongTermBonusPaid;
    mapping( uint16 => uint256) longTermPoolSupply;
    mapping( uint16 => uint256) longTermPoolTokenSupply;
    mapping( uint16 => uint256) longTermPoolReward;
    mapping( uint16 => uint256) periodStarts;
    mapping( uint16 => uint256) periodEnds;
    mapping( uint16 => mapping(address => uint256)) userLastBalanceInPeriod;
    uint16 currentPeriod;

}
