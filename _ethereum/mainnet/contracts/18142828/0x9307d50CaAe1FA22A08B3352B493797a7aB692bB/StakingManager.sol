// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./Initializable.sol";
import "./OwnableUpgradeable.sol";

contract StakingManager is Initializable, OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    IERC20Upgradeable public stakeToken;
    address public presaleContract;
    uint256 public tokensStakedByPresale;
    uint256 public tokensStaked;

    uint256 private lastRewardedBlock;
    uint256 private accumulatedRewardsPerShare;
    uint256 public rewardTokensPerBlock;
    uint256 private constant REWARDS_PRECISION = 1e12;

    uint256 public lockTime;
    uint256 public endBlock;

    struct PoolStaker {
        uint256 amount;
        uint256 stakedTime;
        uint256 lastUpdatedBlock;
        uint256 harvestedRewards;
        uint256 rewardDebt;
    }

    mapping(address => PoolStaker) public poolStakers;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event HarvestRewards(address indexed user, uint256 amount);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _rewardTokenAddress,
        uint256 _rewardTokensPerBlock,
        uint256 _lockTime,
        uint256 _endBlock
    ) public initializer {
        __Ownable_init_unchained();
        stakeToken = IERC20Upgradeable(_rewardTokenAddress);
        rewardTokensPerBlock = _rewardTokensPerBlock;
        lockTime = _lockTime;
        endBlock = _endBlock;
    }

    modifier onlyPresale() {
        require(
            msg.sender == presaleContract,
            "This method is only for presale contract"
        );
        _;
    }

    /**
     * @dev Deposit tokens to the pool
     */
    function deposit(uint256 _amount) external {
        require(block.number < endBlock, "Staking has ended");
        require(_amount > 0, "Deposit amount can't be zero");

        PoolStaker storage staker = poolStakers[msg.sender];

        // Update pool stakers
        harvestRewards();

        // Update current staker
        staker.amount += _amount;
        staker.rewardDebt =
            (staker.amount * accumulatedRewardsPerShare) /
            REWARDS_PRECISION;
        staker.stakedTime = block.timestamp;
        staker.lastUpdatedBlock = block.number;

        // Update pool
        tokensStaked += _amount;

        // Deposit tokens
        emit Deposit(msg.sender, _amount);
        stakeToken.safeTransferFrom(msg.sender, address(this), _amount);
    }

    /**
     * @dev Deposit tokens to  pool by presale contract
     */
    function depositByPresale(
        address _user,
        uint256 _amount
    ) external onlyPresale {
        require(block.number < endBlock, "Staking has ended");
        require(_amount > 0, "Deposit amount can't be zero");

        PoolStaker storage staker = poolStakers[_user];

        // Update pool stakers
        _harvestRewards(_user);

        // Update current staker
        staker.amount += _amount;
        staker.rewardDebt =
            (staker.amount * accumulatedRewardsPerShare) /
            REWARDS_PRECISION;
        staker.stakedTime = block.timestamp;

        // Update pool
        tokensStaked += _amount;
        tokensStakedByPresale += _amount;

        // Deposit tokens
        emit Deposit(_user, _amount);
        stakeToken.safeTransferFrom(presaleContract, address(this), _amount);
    }

    /**
     * @dev Withdraw all tokens from existing pool
     */
    function withdraw() external {
        PoolStaker memory staker = poolStakers[msg.sender];
        uint256 amount = staker.amount;
        require(
            staker.stakedTime + lockTime <= block.timestamp,
            "You are not allowed to withdraw before locked time"
        );
        require(amount > 0, "Withdraw amount can't be zero");

        // Pay rewards
        harvestRewards();

        // Delete staker
        delete poolStakers[msg.sender];

        // Update pool
        tokensStaked -= amount;

        // Withdraw tokens
        emit Withdraw(msg.sender, amount);
        stakeToken.safeTransfer(msg.sender, amount);
    }

    /**
     * @dev Harvest user rewards
     */
    function harvestRewards() public {
        _harvestRewards(msg.sender);
    }

    /**
     * @dev Harvest user rewards
     */
    function _harvestRewards(address _user) private {
        updatePoolRewards();
        PoolStaker storage staker = poolStakers[_user];
        uint256 rewardsToHarvest = ((staker.amount *
            accumulatedRewardsPerShare) / REWARDS_PRECISION) -
            staker.rewardDebt;
        if (rewardsToHarvest == 0) {
            return;
        }

        staker.harvestedRewards += rewardsToHarvest;
        staker.rewardDebt =
            (staker.amount * accumulatedRewardsPerShare) /
            REWARDS_PRECISION;
        emit HarvestRewards(_user, rewardsToHarvest);
        stakeToken.safeTransfer(_user, rewardsToHarvest);
    }

    /**
     * @dev Update pool's accumulatedRewardsPerShare and lastRewardedBlock
     */
    function updatePoolRewards() private {
        if (tokensStaked == 0) {
            lastRewardedBlock = block.number;
            return;
        }
        uint256 blocksSinceLastReward = block.number > endBlock
            ? endBlock - lastRewardedBlock
            : block.number - lastRewardedBlock;
        uint256 rewards = blocksSinceLastReward * rewardTokensPerBlock;
        accumulatedRewardsPerShare =
            accumulatedRewardsPerShare +
            ((rewards * REWARDS_PRECISION) / tokensStaked);
        lastRewardedBlock = block.number > endBlock ? endBlock : block.number;
    }

    /**
     * @dev To get the number of rewards that user can get
     */
    function getRewards(address _user) public view returns (uint256) {
        if (tokensStaked == 0) {
            return 0;
        }
        uint256 blocksSinceLastReward = block.number > endBlock
            ? endBlock - lastRewardedBlock
            : block.number - lastRewardedBlock;
        uint256 rewards = blocksSinceLastReward * rewardTokensPerBlock;
        uint256 accCalc = accumulatedRewardsPerShare +
            ((rewards * REWARDS_PRECISION) / tokensStaked);
        PoolStaker memory staker = poolStakers[_user];
        return
            ((staker.amount * accCalc) / REWARDS_PRECISION) - staker.rewardDebt;
    }

    function setPresale(address _presale) public onlyOwner {
        presaleContract = _presale;
    }

    function setStakeToken(address _stakeToken) public onlyOwner {
        stakeToken = IERC20Upgradeable(_stakeToken);
    }

    function setLockTime(uint256 _lockTime) public onlyOwner {
        lockTime = _lockTime;
    }

    function setEndBlock(uint256 _endBlock) public onlyOwner {
        endBlock = _endBlock;
    }

    function setRewardsPerBlock(
        uint256 _rewardTokensPerBlock
    ) public onlyOwner {
        rewardTokensPerBlock = _rewardTokensPerBlock;
    }
}
