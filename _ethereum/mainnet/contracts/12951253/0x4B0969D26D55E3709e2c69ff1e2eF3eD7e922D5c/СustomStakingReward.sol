// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;

import "./IStakingRewards.sol";

import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

import "./ReentrancyGuardUpgradeable.sol";
import "./OwnableUpgradeable.sol";

contract CustomStakingReward is IStakingRewards, IStakingRewardsInitialize, ReentrancyGuardUpgradeable, OwnableUpgradeable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    ///////////////////////////////////////////////////
    //  Data fields
    //  NB: Only add new fields BELOW any fields in this section

    IERC20 public stakingToken;
    IERC20 public rewardsToken;

    uint256 public periodFinish ;
    uint256 public rewardRate;
    uint256 public rewardsDuration;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    uint256 private _totalSupply;
    mapping(address => uint256) public _balances;

    //  Add new data fields there....
    //      ...

    //  End of data fields
    /////////////////////////////////////////////////////

    /* ========== CONSTRUCTOR ========== */

    function initialize(
        address _stakingToken,
        address _rewardsToken,
        address _owner
    ) override external initializer {
        OwnableUpgradeable.__Ownable_init();
        OwnableUpgradeable.transferOwnership(_owner);
        stakingToken = IERC20(_stakingToken);
        rewardsToken = IERC20(_rewardsToken);
    }

    /* ========== VIEWS ========== */

    function totalSupply() override external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) override external view returns (uint256) {
        return _balances[account];
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        //  return Math.min(block.timestamp, periodFinish);
        return block.timestamp < periodFinish ? block.timestamp : periodFinish;
    }

    //  Actually it's thr reward per token
    //  i.e it's already have "time function" inside (grows with a time, if lastUpdateTime
    //  isn;'t changed
    function rewardPerToken() override public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }

        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(uint(_totalSupply))
            );
    }

    function earned(address account) override public view returns (uint256) {
        return _balances[account].mul(rewardPerToken().sub(userRewardPerTokenPaid[account])).div(1e18).add(rewards[account]);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function stakeWithPermit(uint256 amount, uint deadline, uint8 v, bytes32 r, bytes32 s) override external nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);

        // permit
        IUniswapV2ERC20(address(stakingToken)).permit(msg.sender, address(this), amount, deadline, v, r, s);

        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    function _stake(uint256 amount, address to) internal {
        require(amount > 0, "Cannot stake 0");
        _totalSupply = _totalSupply.add(amount);
        _balances[to] = _balances[to].add(amount);
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(to, amount);
    }

    function stake(uint256 amount) virtual override public nonReentrant updateReward(msg.sender) {
        _stake(amount, msg.sender);
    }

    function stakeTo(uint256 amount, address to) virtual override public nonReentrant updateReward(to) {
        _stake(amount, to);
    }

    function withdraw(uint256 amount) virtual override public nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    function getReward() virtual override public nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardsToken.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function exit() virtual override external {
        withdraw(_balances[msg.sender]);
        getReward();
    }

    /* ========== RESTRICTED FUNCTIONS ========== */
    function notifyRewardAmount(uint256 _reward, uint256 _rewardsDuration) override external onlyOwner updateReward(address(0)) {
        require((_rewardsDuration> 1 days) && (_rewardsDuration < 365 days), "Incorrect rewards duration");
        rewardsDuration = _rewardsDuration;
        if (block.timestamp >= periodFinish) {
            rewardRate = _reward.div(rewardsDuration);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = _reward.add(leftover).div(rewardsDuration);
        }

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint balance = rewardsToken.balanceOf(address(this));
        require(rewardRate <= balance.div(rewardsDuration), "Provided reward too high");

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(rewardsDuration);
        emit RewardAdded(_reward);
    }

    function emergencyAssetWithdrawal(address asset) external onlyOwner {
      IERC20 token = IERC20(asset);
      token.safeTransfer(OwnableUpgradeable.owner(), token.balanceOf(address(this)));
    }

    /* ========== MODIFIERS ========== */

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
}

