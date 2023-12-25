// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./SafeMath.sol";
// import "./ERC20Detailed.sol"; //TBAdded
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./MerkleProof.sol";

// Inheritance
import "./IStakingRewards.sol";
import "./Owned.sol";

// https://docs.synthetix.io/contracts/source/contracts/stakingrewards
contract StakingRewards is IStakingRewards, ReentrancyGuard, Pausable, Owned {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES STAKING ========== */

    IERC20 public stakingToken;

    /// @dev Timestamp of when the rewards finish
    uint256 public periodFinish;

    /// @dev Reward to be paid out per block
    uint256 public rewardRate;

    /// @dev Duration of rewards to be paid out (in seconds)
    uint256 public rewardsDuration = 180 days;

    /// @dev Minimum of last updated time and reward finish time
    uint256 public lastUpdateTime;

    /// @dev Sum of (reward rate * dt * 1e18 / total supply) over all updates since last update time
    uint256 public rewardPerTokenStored;

    /// @dev Number of tokens to be distributed with rewards
    uint256 public fixedRewardsAmount = 600000 * 10 ** 18;

    /// @dev User address => rewardPerTokenStored
    mapping(address => uint256) public userRewardPerTokenPaid;

    /// @dev User address => rewards to be claimed
    mapping(address => uint256) public rewards;

    uint256 private _totalSumStaked;
    mapping(address => uint256) private _balances;

    /// @dev Total stakers.
    uint256 public totalStakers;

    /// @dev Total amount of token claimed.
    uint256 private rewardTokenClaimed;

    /* ========== STATE VARIABLES PERMISSIONED ========== */

    /// @dev of URIs for all the Merkle trees added to the contract.
    string[] public rootURIs;

    /// @dev URI mapping to IPFS storing whitelist data root => URI (IPFS)
    mapping(bytes32 => string) public mapRootURIs;

    /// @dev Root hash record of valid vesting trees Root hash => valid
    mapping(bytes32 => bool) public rootWhitelist;

    mapping(address => bool) private _admins;

    /* ========== CONSTRUCTOR ========== */

    constructor(address _owner, address _stakingToken) Owned(_owner) {
        stakingToken = IERC20(_stakingToken);
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

    /**
     * @dev Throws if root no valid
     **/
    modifier validRoot(bytes32 _root) {
        require(rootWhitelist[_root], "Root no valid");
        _;
    }

    /* ========== VIEWS ========== */

    function totalStaked() external view returns (uint256) {
        return _totalSumStaked;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return block.timestamp < periodFinish ? block.timestamp : periodFinish;
    }

    function getRewardTokenClaimed() external view returns (uint256) {
        return rewardTokenClaimed;
    }

    function rewardPerToken() public view returns (uint256) {
        if (_totalSumStaked == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(rewardRate)
                    .mul(1e18)
                    .div(_totalSumStaked)
            );
    }

    function earned(address account) public view returns (uint256) {
        return
            _balances[account]
                .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
                .div(1e18)
                .add(rewards[account]);
    }

    function getRewardForDuration() external view returns (uint256) {
        return rewardRate.mul(rewardsDuration);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function stake(
        uint256 amount,
        bytes32 root_,
        bytes32[] calldata proof_
    ) external nonReentrant whenNotPaused updateReward(msg.sender) {
        require(verifyProof(msg.sender, root_, proof_), "Not whitelisted");
        require(amount > 0, "Cannot stake 0");
        if (_balances[msg.sender] == 0) {
            totalStakers = totalStakers.add(1);
        }
        _totalSumStaked = _totalSumStaked.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(
        uint256 amount
    ) public nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        require(
            amount <= _balances[msg.sender],
            "Cannot withdraw more than staked"
        );
        _totalSumStaked = _totalSumStaked.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        if (_balances[msg.sender] == 0) {
            totalStakers = totalStakers.sub(1);
        }
        stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    function exit() external {
        withdraw(_balances[msg.sender]);
        claimRewards();
    }

    function claimRewards() public nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardTokenClaimed.add(reward);
            stakingToken.safeTransferFrom(owner, msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function claimRewardsAndStake()
        public
        nonReentrant
        updateReward(msg.sender)
    {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            _totalSumStaked = _totalSumStaked.add(reward);
            _balances[msg.sender] = _balances[msg.sender].add(reward);
            rewardTokenClaimed.add(reward);
            stakingToken.safeTransferFrom(owner, address(this), reward);
            emit ClaimedAndStaked(msg.sender, reward);
        }
    }

    function verifyProof(
        address staker_,
        bytes32 root_,
        bytes32[] calldata proof_
    ) public view validRoot(root_) returns (bool) {
        bytes32 _leaf = keccak256(abi.encodePacked(staker_));
        return MerkleProof.verify(proof_, root_, _leaf);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function addAdmin(address admin_) external onlyOwner {
        require(admin_ != address(0), "zero address");
        _admins[admin_] = true;
    }

    function removeAdmin(address admin_) external onlyOwner {
        require(admin_ != address(0), "zero address");
        _admins[admin_] = false;
    }

    function addRoot(bytes32 root_, string memory uriIPFS_) external {
        require(_admins[msg.sender], "Caller is not an admin");
        require(!rootWhitelist[root_], "Root hash already exists");

        rootURIs.push(uriIPFS_);
        rootWhitelist[root_] = true;
        mapRootURIs[root_] = uriIPFS_;

        emit AddedRoot(root_);
    }

    function notifyRewardAmount() external onlyOwner updateReward(address(0)) {
        uint256 reward = fixedRewardsAmount;

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

        require(
            rewardRate <= reward.div(rewardsDuration),
            "Provided reward too high"
        );

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(rewardsDuration);
        emit RewardAdded(reward);
    }

    function setRewardsDuration(uint256 _rewardsDuration) external onlyOwner {
        require(
            block.timestamp > periodFinish,
            "Previous rewards period must be complete before changing the duration for the new period"
        );
        rewardsDuration = _rewardsDuration;
        emit RewardsDurationUpdated(rewardsDuration);
    }

    /* ========== EVENTS ========== */

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event ClaimedAndStaked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardsDurationUpdated(uint256 newDuration);
    event Recovered(address token, uint256 amount);
    event AddedRoot(bytes32 indexed root);
}
