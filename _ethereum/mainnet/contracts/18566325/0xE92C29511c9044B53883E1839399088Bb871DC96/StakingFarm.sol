/* 
           _   _______ ______ _____    _____ _______       _  _______ _   _  _____ 
     /\   | | |__   __|  ____|_   _|  / ____|__   __|/\   | |/ /_   _| \ | |/ ____|
    /  \  | |    | |  | |__    | |   | (___    | |  /  \  | ' /  | | |  \| | |  __ 
   / /\ \ | |    | |  |  __|   | |    \___ \   | | / /\ \ |  <   | | | . ` | | |_ |
  / ____ \| |____| |  | |     _| |_   ____) |  | |/ ____ \| . \ _| |_| |\  | |__| |
 /_/    \_\______|_|  |_|    |_____| |_____/   |_/_/    \_\_|\_\_____|_| \_|\_____|                                                                                        
*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract ReentrancyGuard {
    bool private _entered;

    modifier nonReentrant() {
        require(!_entered, "ReentrancyGuard: reentrant call");
        _entered = true;
        _;
        _entered = false;
    }
}

contract StakingFarm is ReentrancyGuard {
    address public owner;
    IERC20 public stakingToken;
    uint256 public totalRewards;

    struct Stake {
        uint256 amount;
        uint256 startTime;
        uint256 lockPeriod;
        bool claimed;
    }

    mapping(address => Stake) public stakes;
    mapping(uint256 => uint256) public rewardMultipliers;

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    event StakingTokenSet(address indexed stakingTokenAddress);
    event Staked(address indexed user, uint256 amount, uint256 lockPeriod);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardsAdded(uint256 amount);

    constructor() {
        owner = msg.sender;
        rewardMultipliers[1 weeks] = 10;
        rewardMultipliers[4 weeks] = 50;
        rewardMultipliers[12 weeks] = 120;
    }

    function setStakingToken(address _stakingToken) external onlyOwner {
        require(address(stakingToken) == address(0), "Staking token already set");
        stakingToken = IERC20(_stakingToken);
        emit StakingTokenSet(_stakingToken);
    }

    function addRewards(uint256 _amount) external onlyOwner {
        require(address(stakingToken) != address(0), "Staking token not set");
        stakingToken.transferFrom(msg.sender, address(this), _amount);
        totalRewards += _amount;
        emit RewardsAdded(_amount);
    }

    function stake(uint256 _amount, uint256 _lockPeriod) external nonReentrant {
        require(address(stakingToken) != address(0), "Staking token not set");
        require(_amount > 0, "Cannot stake 0 tokens");
        require(rewardMultipliers[_lockPeriod] > 0, "Invalid lock period");
        
        stakingToken.transferFrom(msg.sender, address(this), _amount);

        stakes[msg.sender] = Stake({
            amount: _amount,
            startTime: block.timestamp,
            lockPeriod: _lockPeriod,
            claimed: false
        });

        emit Staked(msg.sender, _amount, _lockPeriod);
    }

    function withdraw() external nonReentrant {
        require(address(stakingToken) != address(0), "Staking token not set");
        Stake storage userStake = stakes[msg.sender];
        require(userStake.amount > 0, "No staked amount to withdraw");
        require(block.timestamp >= userStake.startTime + userStake.lockPeriod, "Stake is still locked");
        require(!userStake.claimed, "Rewards already claimed");

        uint256 reward = calculateReward(msg.sender);
        require(totalRewards >= reward, "Not enough rewards");

        userStake.claimed = true;
        totalRewards -= reward;

        stakingToken.transfer(msg.sender, userStake.amount + reward);

        emit Withdrawn(msg.sender, userStake.amount);
        emit RewardPaid(msg.sender, reward);
    }

    function calculateReward(address _user) public view returns(uint256) {
        Stake memory userStake = stakes[_user];
        uint256 multiplier = rewardMultipliers[userStake.lockPeriod];
        uint256 reward = (userStake.amount * multiplier) / 1000;
        return reward;
    }
}