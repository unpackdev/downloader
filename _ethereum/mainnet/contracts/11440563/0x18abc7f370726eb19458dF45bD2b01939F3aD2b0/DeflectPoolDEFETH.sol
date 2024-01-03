pragma solidity ^0.6.0;

/*
    ▓█████▄ ▓█████   █████▒██▓    ▓█████  ▄████▄  ▄▄▄█████▓   ██▓███   ▒█████   ▒█████   ██▓
    ▒██▀ ██▌▓█   ▀ ▓██   ▒▓██▒    ▓█   ▀ ▒██▀ ▀█  ▓  ██▒ ▓▒   ▓██░  ██▒▒██▒  ██▒▒██▒  ██▒ ▓██▒
    ░██   █▌▒███   ▒████ ░▒██░    ▒███   ▒▓█    ▄    ██░ ▒    ▓██░ ██▓▒▒██░  ██▒▒██░  ██▒ ▒██░
    ░▓█▄   ▌▒▓█  ▄ ░▓█▒  ░▒██░    ▒▓█  ▄ ▒▓▓▄ ▄██▒░ ▓██▓ ░    ▒██▄█▓▒ ▒▒██   ██░▒██   ██░ ▒██░
    ░▒████▓ ░▒████▒░▒█░   ░██████▒░▒████▒▒ ▓███▀ ░  ▒██▒     ▒██▒ ░  ░░ ████▓▒░░ ████▓▒░░██████▒
     ▒▒▓  ▒ ░░ ▒░ ░ ▒ ░   ░ ▒░▓  ░░░ ▒░ ░░ ░▒ ▒  ░  ▒ ░░        ▒▓▒░ ░  ░░ ▒░▒░▒░ ░ ▒░▒░▒░ ░ ▒░▓  ░
     ░ ▒  ▒  ░ ░  ░ ░     ░ ░ ▒  ░ ░ ░  ░  ░  ▒       ░          ░▒ ░       ░ ▒ ▒░   ░ ▒ ▒░ ░ ░ ▒  ░
     ░ ░  ░    ░    ░ ░     ░ ░      ░   ░          ░             ░░         ░ ░ ░ ▒  ░ ░ ░ ▒    ░ ░
       ░       ░  ░           ░  ░   ░  ░░ ░                               ░ ░      ░ ░      ░  ░
     ░                                   ░
*/

import "./SafeERC20.sol";
import "./Ownable.sol";
import "./Math.sol";
import "./IDeflector.sol";


contract LPTokenWrapper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public stakingToken;
    address public devFund;
    uint256 public devFee;
    uint256 public _totalSupply;
    uint256 public _totalSupplyAccounting;
    uint256 public startTime;
    mapping(address => uint256) public _balances;
    mapping(address => uint256) public _balancesAccounting;

    // Returns the total staked tokens within the contract
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    // Returns staking balance of the account
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    // Set the staking token for the contract
    function setStakingToken(address stakingTokenAddress) internal {
        stakingToken = IERC20(stakingTokenAddress);
    }

    // Stake funds into the pool
    function stake(uint256 amount) public virtual {
        // Increment sender's balances and total supply
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        _totalSupply = _totalSupply.add(amount);

        // Transfer funds
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
    }

    // Align balances for the user
    function withdraw(uint256 amount) public virtual {
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
    }
}

contract DeflectPoolDEFETH is LPTokenWrapper, OwnableUpgradeSafe {
    using SafeERC20 for IERC20;

    IERC20 public rewardToken;
    IDeflector deflector;
    uint256 public DURATION;
    uint256 public periodFinish;
    uint256 public rewardRate;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    uint256 public deployedTime;

    mapping(address => uint256) public rewards;
    mapping(address => uint256) public userRewardPerTokenPaid;

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event Boost(address _token, uint256 level);

    constructor(
        uint256 _duration,
        address _stakingToken,
        address _rewardToken,
        address _deflector,
        address _devFund
    ) public LPTokenWrapper() {
        __Ownable_init();
        setStakingToken(_stakingToken);
        deflector = IDeflector(_deflector);
        devFund = _devFund;
        devFee = 15; // 1.5%
        rewardToken = IERC20(_rewardToken);
        deployedTime = block.timestamp;
        DURATION = _duration;
    }

    function setDevFund(address _newFund) external onlyOwner {
        devFund = _newFund;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    // Returns the current rate of rewards per token (doh)
    function rewardPerToken() public view returns (uint256) {
        // Do not distribute rewards before games begin
        if (block.timestamp < startTime) {
            return 0;
        }
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        // Effective total supply takes into account all the multipliers bought.
        uint256 effectiveTotalSupply = _totalSupply.add(_totalSupplyAccounting);
        return rewardPerTokenStored.add(lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(effectiveTotalSupply));
    }

    // Returns the current reward tokens that the user can claim.
    function earned(address account) public view returns (uint256) {
        // Each user has it's own effective balance which is just the staked balance multiplied by boost level multiplier.
        uint256 effectiveBalance = _balances[account].add(_balancesAccounting[account]);
        return effectiveBalance.mul(rewardPerToken().sub(userRewardPerTokenPaid[account])).div(1e18).add(rewards[account]);
    }

    // Staking function which updates the user balances in the parent contract
    function stake(uint256 amount) public override {
        updateReward(msg.sender);
        require(amount > 0, "Cannot stake 0");
        super.stake(amount);

        uint256 userTotalMultiplier = deflector.getTotalValueForUser(address(this), msg.sender);
        adjustEffectiveStake(msg.sender, userTotalMultiplier, false);
        emit Staked(msg.sender, amount);
    }

    // Withdraw function to remove stake from the pool
    function withdraw(uint256 amount) public override {
        require(amount > 0, "Cannot withdraw 0");
        updateReward(msg.sender);

        uint256 tax = amount.mul(devFee).div(1000);
        stakingToken.safeTransfer(devFund, tax);
        stakingToken.safeTransfer(msg.sender, amount.sub(tax));

        super.withdraw(amount);
        uint256 userTotalMultiplier = deflector.getTotalValueForUser(address(this), msg.sender);
        adjustEffectiveStake(msg.sender, userTotalMultiplier, true);
        emit Withdrawn(msg.sender, amount);
    }

    function adjustEffectiveStake(
        address self,
        uint256 _totalMultiplier,
        bool _isWithdraw
    ) private {
        if (_totalMultiplier > 0) {
            uint256 prevBalancesAccounting = _balancesAccounting[self];
            // Calculate and set self's new accounting balance
            uint256 newBalancesAccounting = _balances[self].mul(_totalMultiplier).div(1000);

            // Adjust total accounting supply accordingly - Subtracting on withdraws
            if (_isWithdraw) {
                uint256 diffBalancesAccounting = prevBalancesAccounting.sub(newBalancesAccounting);
                _balancesAccounting[self] = _balancesAccounting[self].sub(diffBalancesAccounting);
                _totalSupplyAccounting = _totalSupplyAccounting.sub(diffBalancesAccounting);
            } else {
                uint256 diffBalancesAccounting = newBalancesAccounting.sub(prevBalancesAccounting);
                _balancesAccounting[self] = _balancesAccounting[self].add(diffBalancesAccounting);
                _totalSupplyAccounting = _totalSupplyAccounting.add(diffBalancesAccounting);
            }
        }
    }

    // Get the earned rewards and withdraw staked tokens
    function exit() external {
        getReward();
        withdraw(balanceOf(msg.sender));
    }

    // Sends out the reward tokens to the user.
    function getReward() public {
        updateReward(msg.sender);
        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardToken.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    // Called to start the pool with the reward amount it should distribute
    // The reward period will be the duration of the pool.
    function notifyRewardAmount(uint256 reward) external onlyOwner {
        rewardToken.safeTransferFrom(msg.sender, address(this), reward);
        updateRewardPerTokenStored();
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(DURATION);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(DURATION);
        }
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(DURATION);
        emit RewardAdded(reward);
    }

    // Notify the reward amount without updating time;
    function notifyRewardAmountWithoutUpdateTime(uint256 reward) external onlyOwner {
        updateRewardPerTokenStored();
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(DURATION);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(DURATION);
        }
        emit RewardAdded(reward);
    }

    // Returns the users current multiplier level
    function getTotalLevel(address _user) external view returns (uint256) {
        return deflector.getTotalLevel(address(this), _user);
    }

    // Return the amount spent on multipliers, used for subtracting for future purchases.
    function getSpent(address _token, address _user) external view returns (uint256) {
        return deflector.getTokensSpentPerContract(address(this), _token, _user);
    }

    // Calculate the cost for purchasing a boost.
    function calculateCost(
        address _user,
        address _token,
        uint256 _level
    ) public view returns (uint256) {
        uint256 lastLevel = deflector.getLastTokenLevelForUser(address(this), _token, _user);
        if (lastLevel > _level) return 0;
        return deflector.getSpendableCostPerTokenForUser(address(this), _user, _token, _level);
    }

    // Purchase a multiplier level, same level cannot be purchased twice.
    function purchase(address _token, uint256 _level) external {
        require(deflector.isSpendableTokenInContract(address(this), _token), "Not a multiplier token");
        uint256 lastLevel = deflector.getLastTokenLevelForUser(address(this), msg.sender, _token);
        require(lastLevel < _level, "Cannot downgrade level or same level");
        uint256 cost = calculateCost(msg.sender, _token, _level);

        IERC20(_token).safeTransferFrom(msg.sender, devFund, cost);

        // Update balances and level in the multiplier contarct
        deflector.purchase(address(this), msg.sender, _token, _level);

        // Adjust new level
        uint256 userTotalMultiplier = deflector.getTotalValueForUser(address(this), msg.sender);
        adjustEffectiveStake(msg.sender, userTotalMultiplier, false);

        emit Boost(_token, _level);
    }

    // Returns the multiplier for user.
    function getTotalMultiplier(address _account) public view returns (uint256) {
        return deflector.getTotalValueForUser(address(this), _account);
    }

    // Ejects any remaining tokens from the pool.
    // Callable only after the pool has started and the pools reward distribution period has finished.
    function eject() external onlyOwner {
        require(startTime < block.timestamp && block.timestamp >= periodFinish, "Cannot eject before period finishes or pool has started");
        uint256 currBalance = rewardToken.balanceOf(address(this));
        rewardToken.safeTransfer(msg.sender, currBalance);
    }

    // Forcefully retire a pool
    // Only sets the period finish to 0
    // This will prevent more rewards from being disbursed
    function kill() external onlyOwner {
        periodFinish = block.timestamp;
    }

    function updateRewardPerTokenStored() internal {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
    }

    function updateReward(address account) internal {
        updateRewardPerTokenStored();
        rewards[account] = earned(account);
        userRewardPerTokenPaid[account] = rewardPerTokenStored;
    }
}
