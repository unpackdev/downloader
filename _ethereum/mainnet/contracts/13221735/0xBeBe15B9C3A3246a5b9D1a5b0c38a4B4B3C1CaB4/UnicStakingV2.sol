pragma solidity 0.6.12;

import "./PausableUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./Initializable.sol";
import "./IMintableCollection.sol";
import "./IRewardable.sol";
import "./EmergencyWithdrawable.sol";
import "./UnicStakingERC721.sol";
import "./IUnicFactory.sol";

// This upgraded version makes the adding of reward pools permissionless (for UNIC and uTokens)
contract UnicStakingV2 is Initializable, EmergencyWithdrawable, IRewardable, PausableUpgradeable {
    using SafeMath for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct StakerInfo {
        uint256 nftId;
        uint256 amount;
        uint256 stakeStartTime;
        uint256 lockDays;
        uint256 rewardDebt;
        address rewardToken;
        uint16 multiplier;
    }

    struct LockMultiplier {
        uint16 multiplier;
        bool exists;
    }

    struct RewardPool {
        IERC20Upgradeable rewardToken;
        uint256 stakedAmount;
        uint256 stakedAmountWithMultipliers;
        uint256 totalRewardAmount;
        uint256 accRewardPerShare;
        uint256 lastRewardAmount;
    }

    IERC20Upgradeable private stakingToken;
    IMintableCollection private nftCollection;
    uint256 public minStakeAmount;
    uint256 private nftStartId;

    // NFT ID to staker info
    mapping(uint256 => StakerInfo) public stakes;

    // Each uToken should have its own poolcontracts/UnicStaking.sol:115:9
    mapping(address => RewardPool) public pools;

    // Mapping from days => multiplier for timelock
    mapping(uint256 => LockMultiplier) public lockMultipliers;

    uint256 private constant DIV_PRECISION = 1e18;

    event AddRewards(address indexed rewardToken, uint256 amount);
    event Staked(
        address indexed account,
        address indexed rewardToken,
        uint256 nftId,
        uint256 amount,
        uint256 lockDays
    );
    event Harvest(address indexed staker, address indexed rewardToken, uint256 nftId, uint256 amount);
    event Withdraw(address indexed staker, address indexed rewardToken, uint256 nftId, uint256 amount);
    event LogUpdateRewards(address indexed rewardToken, uint256 totalRewards, uint256 accRewardPerShare);

    modifier poolExists(address rewardToken) {
        require(address(pools[rewardToken].rewardToken) != address(0), "UnicStaking: Pool does not exist");
        _;
    }

    modifier poolNotExists(address rewardToken) {
        require(address(pools[rewardToken].rewardToken) == address(0), "UnicStaking: Pool does already exist");
        _;
    }

    IUnicFactory private factory;

    function initialize(
        IERC20Upgradeable _stakingToken,
        IMintableCollection _nftCollection,
        uint256 _nftStartId,
        uint256 _minStakeAmount
    ) public initializer {
        __Ownable_init();
        stakingToken = _stakingToken;
        nftCollection = _nftCollection;
        nftStartId = _nftStartId;
        minStakeAmount = _minStakeAmount;
    }

    function setUnicFactory(IUnicFactory _factory) external onlyOwner {
        factory = _factory;
    }

    // lockdays are passed as seconds, multiplier in percentage from 100 (e.g. 170 for 70% on top)
    function setLockMultiplier(uint256 lockDays, uint16 multiplier) external onlyOwner {
        require(multiplier >= 100, "Minimum multiplier = 100");
        lockMultipliers[lockDays] = LockMultiplier({
        multiplier: multiplier,
        exists: true
        });
    }

    function setMinStakeAmount(uint256 _minStakeAmount) external onlyOwner {
        minStakeAmount = _minStakeAmount;
    }

    /**
     * @param amount Amount of staking tokens
     * @param lockDays How many days the staker wants to lock
     * @param rewardToken The desired reward token to stake the tokens for (most likely a certain uToken)
     */
    function stake(uint256 amount, uint256 lockDays, address rewardToken)
    external
    whenNotPaused
    poolExists(rewardToken)
    {
        require(
            amount >= minStakeAmount,
            "UnicStaking: Amount must be greater than or equal to min stake amount"
        );
        require(
            lockMultipliers[lockDays].exists,
            "UnicStaking: Invalid number of lock days specified"
        );

        updateRewards(rewardToken);

        // transfer the staking tokens into the staking pool
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);

        // now the data of the staker is persisted
        StakerInfo storage staker = stakes[nftStartId];
        staker.stakeStartTime = block.timestamp;
        staker.amount = amount;
        staker.lockDays = lockDays;
        staker.multiplier = lockMultipliers[lockDays].multiplier;
        staker.nftId = nftStartId;
        staker.rewardToken = rewardToken;

        RewardPool storage pool = pools[rewardToken];

        // the amount with lock multiplier applied
        uint256 virtualAmount = virtualAmount(staker.amount, staker.multiplier);
        staker.rewardDebt = virtualAmount.mul(pool.accRewardPerShare).div(DIV_PRECISION);

        pool.stakedAmount = pool.stakedAmount.add(amount);
        pool.stakedAmountWithMultipliers = pool.stakedAmountWithMultipliers.add(virtualAmount);

        nftStartId = nftStartId.add(1);
        nftCollection.mint(msg.sender, nftStartId - 1);

        emit Staked(msg.sender, rewardToken, nftStartId - 1, amount, lockDays);
    }

    function withdraw(uint256 nftId) external whenNotPaused {
        StakerInfo storage staker = stakes[nftId];
        require(address(staker.rewardToken) != address(0), "UnicStaking: No staker exists");
        require(
            nftCollection.ownerOf(nftId) == msg.sender,
            "UnicStaking: Only the owner may withdraw"
        );
        require(
            (staker.stakeStartTime.add(staker.lockDays)) < block.timestamp,
            "UnicStaking: Lock time not expired"
        );
        updateRewards(staker.rewardToken);

        RewardPool storage pool = pools[address(staker.rewardToken)];
        require(address(pool.rewardToken) != address(0), "UnicStaking: Pool gone");

        // lets burn the NFT first
        nftCollection.burn(nftId);

        uint256 virtualAmount = virtualAmount(staker.amount, staker.multiplier);

        uint256 accumulated = virtualAmount.mul(pool.accRewardPerShare).div(DIV_PRECISION);
        uint256 reward = accumulated.sub(staker.rewardDebt);

        // reset the pool props
        pool.stakedAmount = pool.stakedAmount.sub(staker.amount);
        pool.stakedAmountWithMultipliers = pool.stakedAmountWithMultipliers.sub(virtualAmount);

        uint256 staked = staker.amount;

        // reset all staker props
        staker.rewardDebt = 0;
        staker.amount = 0;
        staker.stakeStartTime = 0;
        staker.lockDays = 0;
        staker.nftId = 0;
        staker.rewardToken = address(0);

        stakingToken.safeTransfer(msg.sender, reward.add(staked));

        emit Harvest(msg.sender, address(staker.rewardToken), nftId, reward);
        emit Withdraw(msg.sender, address(staker.rewardToken), nftId, staked);
    }

    function updateRewards(address rewardToken) private poolExists(rewardToken) {
        RewardPool storage pool = pools[rewardToken];
        require(address(pool.rewardToken) != address(0), "UnicStaking: Pool gone");

        if (pool.totalRewardAmount > pool.lastRewardAmount) {
            if (pool.stakedAmountWithMultipliers > 0) {
                uint256 reward = pool.totalRewardAmount.sub(pool.lastRewardAmount);
                pool.accRewardPerShare = pool.accRewardPerShare.add(reward.mul(DIV_PRECISION).div(pool.stakedAmountWithMultipliers));
            }
            pool.lastRewardAmount = pool.totalRewardAmount;
            emit LogUpdateRewards(rewardToken, pool.lastRewardAmount, pool.accRewardPerShare);
        }
    }

    function createPool(address rewardToken) external poolNotExists(rewardToken) {
        require(
            rewardToken == 0x94E0BAb2F6Ab1F19F4750E42d7349f2740513aD5 || // UNIC
            rewardToken == 0x3d9233F15BB93C78a4f07B5C5F7A018630217cB3 || // first uToken (Unicly Genesis uUNICLY)
            factory.getUToken(rewardToken) > 0,
            "UnicStakingV2: rewardToken must be UNIC or uToken"
        );
        RewardPool memory pool = RewardPool({
            rewardToken: IERC20Upgradeable(rewardToken),
            stakedAmount: 0,
            stakedAmountWithMultipliers: 0,
            totalRewardAmount: 0,
            accRewardPerShare: 0,
            lastRewardAmount: 0
        });
        pools[rewardToken] = pool;
    }

    function addRewards(address rewardToken, uint256 amount) override external poolExists(rewardToken) {
        require(amount > 0, "UnicStaking: Amount must be greater than zero");
        IERC20Upgradeable(rewardToken).safeTransferFrom(msg.sender, address(this), amount);
        RewardPool storage pool = pools[rewardToken];
        pool.totalRewardAmount = pool.totalRewardAmount.add(amount);
        emit AddRewards(rewardToken, amount);
    }

    function harvest(uint256 nftId) external whenNotPaused {
        StakerInfo storage staker = stakes[nftId];
        require(staker.nftId > 0, "UnicStaking: No staker exists");
        require(
            nftCollection.ownerOf(nftId) == msg.sender,
            "UnicStaking: Only the owner may harvest"
        );

        updateRewards(address(staker.rewardToken));

        RewardPool memory pool = pools[address(staker.rewardToken)];
        uint256 accumulated = virtualAmount(staker.amount, staker.multiplier).mul(pool.accRewardPerShare).div(DIV_PRECISION);

        uint256 reward;
        // this needs to be considered due to roundings in reward calculation
        if (accumulated > staker.rewardDebt) {
            reward = accumulated.sub(staker.rewardDebt);
        }

        staker.rewardDebt = accumulated;

        pool.rewardToken.safeTransfer(msg.sender, reward);
        emit Harvest(msg.sender, address(staker.rewardToken), nftId, reward);
    }

    function pendingReward(uint256 nftId) external view returns (uint256) {
        StakerInfo memory staker = stakes[nftId];
        require(staker.nftId > 0, "StakingPool: No staker exists");

        RewardPool memory pool = pools[address(staker.rewardToken)];
        require(address(pool.rewardToken) != address(0), "UnicStaking: Pool gone");

        uint256 accRewardPerShare = 0;
        // run a part from the updateRewards logic but don't persist anything
        if (pool.totalRewardAmount > pool.lastRewardAmount) {
            if (pool.stakedAmountWithMultipliers > 0) {
                uint256 reward = pool.totalRewardAmount.sub(pool.lastRewardAmount);
                accRewardPerShare = pool.accRewardPerShare.add(reward.mul(DIV_PRECISION).div(pool.stakedAmountWithMultipliers));
            }
        }

        uint256 accumulated = virtualAmount(staker.amount, staker.multiplier).mul(accRewardPerShare).div(DIV_PRECISION);

        // this can happen due to roundings in the reward calculation
        if (staker.rewardDebt > accumulated) {
            return 0;
        }
        return accumulated.sub(staker.rewardDebt);
    }

    // returns the virtual amount after having a multiplier applied
    function virtualAmount(uint256 amount, uint256 multiplier) private view returns (uint256) {
        return amount.mul(multiplier.mul(DIV_PRECISION).div(100)).div(DIV_PRECISION);
    }

    // returns the stake with multiplier for an nftId
    function getStakeWithMultiplier(uint256 nftId) external view returns (uint256 stakeWithMultiplier){
        StakerInfo memory staker = stakes[nftId];
        stakeWithMultiplier = virtualAmount(staker.amount, staker.multiplier);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}
