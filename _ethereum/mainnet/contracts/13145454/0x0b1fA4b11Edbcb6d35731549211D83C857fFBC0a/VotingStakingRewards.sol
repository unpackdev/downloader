pragma solidity ^0.4.24;

import "./SafeMath.sol";
import "./SafeMath64.sol";
import "./Math.sol";

import "./IVeXBE.sol";
import "./IERC20.sol";
import "./IBoostLogicProvider.sol";

import "./VotingPausable.sol";
import "./VotingNonReentrant.sol";
import "./VotingOwnable.sol";
import "./VotingInitializable.sol";

contract VotingStakingRewards is
    VotingPausable,
    VotingNonReentrant,
    VotingOwnable,
    VotingInitializable
{
    using SafeMath for uint256;

    /* ========== EVENTS ========== */

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);

    uint256 public constant PCT_BASE = 10**18; // 0% = 0; 1% = 10^16; 100% = 10^18
    uint256 internal constant MAX_BOOST_LEVEL = PCT_BASE;

    address public treasury;

    struct BondedReward {
        uint256 amount;
        uint256 unlockTime;
    }

    mapping(address => bool) public allowance;
    mapping(address => BondedReward) public bondedRewardLocks;

    uint256 public penaltyPct = PCT_BASE / 2; // PCT_BASE is 10^18

    uint256 public inverseMaxBoostCoefficient = 40; // 1 / inverseMaxBoostCoefficient = max boost coef. (ex. if 40 then 1 / (40 / 100) = 2.5)

    IERC20 public rewardsToken;
    IERC20 public stakingToken;
    uint256 public periodFinish;
    uint256 public rewardRate;
    uint256 public rewardsDuration;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    address public rewardsDistribution;
    uint256 public bondedLockDuration;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    uint256 public totalSupply;
    mapping(address => uint256) internal _balances;

    IVeXBE public token;
    IBoostLogicProvider public boostLogicProvider;

    function configure(
        address _rewardsDistribution,
        IERC20 _rewardsToken,
        IERC20 _stakingToken,
        uint256 _rewardsDuration,
        IVeXBE _token,
        IBoostLogicProvider _boostLogicProvider,
        address _treasury,
        uint256 _bondedLockDuration,
        address[] memory _allowance
    ) public initializer {
        rewardsToken = _rewardsToken;
        stakingToken = _stakingToken;
        rewardsDistribution = _rewardsDistribution;
        rewardsDuration = _rewardsDuration;
        token = _token;
        boostLogicProvider = _boostLogicProvider;
        treasury = _treasury;
        require(_bondedLockDuration > 0, "badBondDuration");
        bondedLockDuration = _bondedLockDuration;
        for (uint256 i = 0; i < _allowance.length; i++) {
            allowance[_allowance[i]] = true;
        }
    }

    /* ========== MODIFIERS ========== */

    modifier updateReward(address account) {
        uint256 _lastTimeReward = lastTimeRewardApplicable();
        uint256 _duration = _lastTimeReward.sub(lastUpdateTime);
        rewardPerTokenStored = _rewardPerToken(_duration);
        lastUpdateTime = _lastTimeReward;
        if (account != address(0)) {
            (uint256 userEarned, uint256 toTreasury) = potentialXbeReturns(
                0,
                account
            );
            rewards[account] = userEarned;
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
            // transfer remaining reward share to treasury
            if (toTreasury > 0) {
                require(
                    stakingToken.transfer(treasury, toTreasury),
                    "!boostDelta"
                );
            }
        }
        _;
    }

    modifier onlyRewardsDistribution() {
        require(
            msg.sender == rewardsDistribution,
            "Caller is not RewardsDistribution contract"
        );
        _;
    }

    /* ========== OWNERS FUNCTIONS ========== */

    function setRewardsDistribution(address _rewardsDistribution)
        external
        onlyOwner
    {
        rewardsDistribution = _rewardsDistribution;
    }

    function setInverseMaxBoostCoefficient(uint256 _inverseMaxBoostCoefficient)
        external
        onlyOwner
    {
        inverseMaxBoostCoefficient = _inverseMaxBoostCoefficient;
        require(
            _inverseMaxBoostCoefficient > 0 &&
                _inverseMaxBoostCoefficient < 100,
            "invalidInverseMaxBoostCoefficient"
        );
    }

    function setPenaltyPct(uint256 _penaltyPct) external onlyOwner {
        penaltyPct = _penaltyPct;
        require(_penaltyPct < PCT_BASE, "tooHighPct");
    }

    function setBondedLockDuration(uint256 _bondedLockDuration)
        external
        onlyOwner
    {
        bondedLockDuration = _bondedLockDuration;
    }

    function setBoostLogicProvider(address _boostLogicProvider)
        external
        onlyOwner
    {
        boostLogicProvider = IBoostLogicProvider(_boostLogicProvider);
    }

    function setAddressWhoCanAutoStake(address _addr, bool _flag)
        external
        onlyOwner
    {
        allowance[_addr] = _flag;
    }

    /* ========== VIEWS ========== */

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min256(block.timestamp, periodFinish);
    }

    function rewardPerToken() external view returns (uint256) {
        return _rewardPerToken(lastTimeRewardApplicable().sub(lastUpdateTime));
    }

    function _rewardPerToken(uint256 duration) internal view returns (uint256) {
        if (totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                duration.mul(rewardRate).mul(PCT_BASE).div(totalSupply)
            );
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function notifyRewardAmount(uint256 reward)
        external
        onlyRewardsDistribution
        updateReward(address(0))
    {
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(rewardsDuration);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(rewardsDuration);
        }

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint256 balance = rewardsToken.balanceOf(address(this));
        require(
            rewardRate <= balance.div(rewardsDuration),
            "Provided reward too high"
        );

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(rewardsDuration);
        emit RewardAdded(reward);
    }

    function _stake(address _for, uint256 _amount) internal {
        require(_amount > 0, "Cannot stake 0");
        totalSupply = totalSupply.add(_amount);
        _balances[_for] = _balances[_for].add(_amount);

        require(
            stakingToken.transferFrom(msg.sender, address(this), _amount),
            "!t"
        );
        emit Staked(_for, _amount);
    }

    function stakeFor(address _for, uint256 amount)
        external
        nonReentrant
        whenNotPaused
        updateReward(_for)
    {
        require(allowance[msg.sender], "stakeNotApproved");

        _stake(_for, amount);

        BondedReward memory rewardLock = bondedRewardLocks[_for];
        if (block.timestamp >= rewardLock.unlockTime) {
            bondedRewardLocks[_for].amount = amount;
        } else {
            bondedRewardLocks[_for].amount = rewardLock.amount.add(amount);
        }
        bondedRewardLocks[_for].unlockTime = block.timestamp.add(
            bondedLockDuration
        );
    }

    function stake(uint256 amount)
        external
        nonReentrant
        whenNotPaused
        updateReward(msg.sender)
    {
        _stake(msg.sender, amount);
    }

    function withdrawBondedOrWithPenalty()
        external
        nonReentrant
        updateReward(msg.sender)
    {
        uint256 amount = bondedRewardLocks[msg.sender].amount;
        uint256 escrowed = token.lockedAmount(msg.sender);
        amount = Math.min256(amount, _balances[msg.sender].sub(escrowed));

        totalSupply = totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        if (block.timestamp >= bondedRewardLocks[msg.sender].unlockTime) {
            require(stakingToken.transfer(msg.sender, amount), "!tBonded");
        } else {
            uint256 penalty = amount.mul(penaltyPct).div(PCT_BASE);
            uint256 toTransfer = amount.sub(penalty);
            require(
                stakingToken.transfer(msg.sender, toTransfer),
                "!tBondedWithPenalty"
            );
            require(stakingToken.transfer(treasury, penalty), "!tPenalty");
        }
        delete bondedRewardLocks[msg.sender];
        emit Withdrawn(msg.sender, amount);
    }

    function withdrawUnbonded(uint256 amount)
        external
        nonReentrant
        updateReward(msg.sender)
    {
        require(amount > 0, "!withdraw0");

        uint256 escrowed = token.lockedAmount(msg.sender);
        require(
            _balances[msg.sender].sub(escrowed).sub(
                bondedRewardLocks[msg.sender].amount
            ) >= amount,
            "escrow amount failure"
        );

        totalSupply = totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);

        require(stakingToken.transfer(msg.sender, amount), "!t");

        emit Withdrawn(msg.sender, amount);
    }

    function _baseBoostLevel() internal view returns (uint256) {
        return PCT_BASE.mul(inverseMaxBoostCoefficient).div(100);
    }

    function _lockedBoostLevel(address account)
        internal
        view
        returns (uint256)
    {
        IVeXBE veXBE = token;
        uint256 votingBalance = veXBE.balanceOf(account);
        uint256 votingTotal = veXBE.totalSupply();
        uint256 lockedAmount = veXBE.lockedAmount(account);
        if (votingTotal == 0 || votingBalance == 0) {
            return _baseBoostLevel();
        }

        uint256 res = PCT_BASE
            .mul(inverseMaxBoostCoefficient)
            .add(
                uint256(100)
                    .sub(inverseMaxBoostCoefficient)
                    .mul(PCT_BASE)
                    .mul(veXBE.lockedSupply())
                    .div(votingTotal)
                    .mul(votingBalance)
                    .div(lockedAmount)
            )
            .div(100);

        return res < MAX_BOOST_LEVEL ? res : MAX_BOOST_LEVEL;
    }

    function calculateBoostLevel(address account)
        public
        view
        returns (uint256)
    {
        IVeXBE veXBE = token;
        uint256 lockedAmount = veXBE.lockedAmount(account);

        uint256 stakedAmount = _balances[account];
        if (stakedAmount == 0 || lockedAmount == 0) {
            return _baseBoostLevel();
        }

        uint256 lockedBoost = boostLogicProvider.hasMaxBoostLevel(account)
            ? MAX_BOOST_LEVEL
            : _lockedBoostLevel(account);

        return
            lockedBoost
                .mul(lockedAmount)
                .add(_baseBoostLevel().mul(stakedAmount.sub(lockedAmount)))
                .div(stakedAmount);
    }

    function earned(address account)
        external
        view
        returns (
            uint256 // userEarned
        )
    {
        uint256 duration = lastTimeRewardApplicable().sub(lastUpdateTime);
        (uint256 userEarned, ) = potentialXbeReturns(duration, account);
        return userEarned;
    }

    function potentialXbeReturns(uint256 duration, address account)
        public
        view
        returns (
            uint256,
            uint256 // userEarned, toTreasury
        )
    {
        uint256 boostLevel = calculateBoostLevel(account);
        require(boostLevel <= MAX_BOOST_LEVEL, "badBoostLevel");

        uint256 maxBoostedReward = _balances[account]
            .mul(_rewardPerToken(duration).sub(userRewardPerTokenPaid[account]))
            .div(PCT_BASE);

        uint256 toUser = maxBoostedReward.mul(boostLevel).div(PCT_BASE);
        uint256 toTreasury = maxBoostedReward.sub(toUser);

        return (toUser.add(rewards[account]), toTreasury);
    }

    function getReward() external nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            require(rewardsToken.transfer(msg.sender, reward), "!t");
            emit RewardPaid(msg.sender, reward);
        }
    }
}
