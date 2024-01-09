// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
import "flatHelper.sol";

contract StakingPools is AccessControlUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /**********
     * DATA INTERFACE
     **********/

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many ASSET tokensens the user has provided.
        uint256 depositTimeStamp;
        uint256[] rewardsDebts; // Order like in AssetInfo rewardsTokens
        // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of rewards
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * asset.accumulatedPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws ASSET tokensens to a asset. Here's what happens:
        //   1. The assets `accumulatedPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to the address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }
    // Info of each asset.
    struct PoolInfo {
        address assetToken; // Address of LP token contract.
        uint256 lastRewardBlock; // Last block number that AQRU distribution occurs.
        uint256[] accumulatedPerShare; // Accumulated token per share, times token decimals. See below.
        address[] rewardsTokens; // Must be constant.
        uint256[] rewardsPerBlock; // Tokens to distribute per block.
        uint256[] accuracy; // Tokens accuracy.
        uint256 poolSupply; // Total amount of deposits by users.
        uint256 lockTime;
        bool paused;
    }

    /**********
     * STORAGE
     **********/

    /// @notice pid => pool info
    mapping(uint256 => PoolInfo) public poolInfo;
    /// @notice pid => user address => UserInfo
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    event Deposit(address indexed user, uint256 indexed poolId, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed poolId, uint256 amount);
    event ClaimRewards(address indexed user, uint256 indexed poolId, address[] tokens, uint256[] amounts);

    /**********
     * MODIFIERS
     **********/

    modifier hasPool(uint256 _pid) {
        require(poolExist(_pid), "Pool not exist");
        _;
    }

    modifier poolRunning(uint256 _pid) {
        require(!poolInfo[_pid].paused, "Pool on pause");
        _;
    }

    /**********
     * ADMIN INTERFACE
     **********/

    function initialize() public virtual initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        __ReentrancyGuard_init();
    }

    /// @notice Add staking pool to the chief contract
    /// @param _pid New pool id.
    /// @param _assetAddress Staked token
    /// @param _rewardsTokens Addresses of the reward tokens
    /// @param _rewardsPerBlock Amount of rewards distributed to the pool every block
    function addPool(
        uint256 _pid,
        uint256 _lockTime,
        address _assetAddress,
        address[] calldata _rewardsTokens,
        uint256[] calldata _rewardsPerBlock
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(!poolExist(_pid), "Pool exist");
        require(_assetAddress != address(0), "Wrong asset address");
        require(_rewardsTokens.length == _rewardsPerBlock.length, "Wrong rewards tokens");

        poolInfo[_pid] = PoolInfo({
            assetToken: _assetAddress,
            lastRewardBlock: block.number,
            accumulatedPerShare: new uint256[](_rewardsTokens.length),
            rewardsTokens: _rewardsTokens,
            accuracy: new uint256[](_rewardsTokens.length),
            rewardsPerBlock: _rewardsPerBlock,
            poolSupply: 0,
            lockTime: _lockTime,
            paused: false
        });
        for (uint256 i = 0; i < _rewardsTokens.length; i++) {
            poolInfo[_pid].accuracy[i] = 10**IERC20MetadataUpgradeable(_rewardsTokens[i]).decimals();
        }
    }

    /// @notice Update rewards distribution speed
    /// @param _pid New pool id.
    /// @param _rewardsPerBlock Amount of rewards distributed to the pool every block
    /// @param _withUpdate Update current rewards before changing the coefficients
    function updatePoolSettings(
        uint256 _pid,
        uint256[] calldata _rewardsPerBlock,
        bool _withUpdate
    ) external onlyRole(DEFAULT_ADMIN_ROLE) hasPool(_pid) {
        if (_withUpdate) {
            updatePool(_pid);
        }
        require(poolInfo[_pid].rewardsTokens.length == _rewardsPerBlock.length, "Wrong rewards tokens");
        poolInfo[_pid].rewardsPerBlock = _rewardsPerBlock;
    }

    /// @notice Pauses/unpauses the pool
    /// @param _pid Pool's id
    /// @param _paused True to pause, False to unpause
    function setOnPause(uint256 _pid, bool _paused) external hasPool(_pid) onlyRole(DEFAULT_ADMIN_ROLE) {
        poolInfo[_pid].paused = _paused;
    }

    /**********
     * USER INTERFACE
     **********/

    /// @notice Update reward variables of the given asset to be up-to-date.
    /// @param _pid Pool's id
    function updatePool(uint256 _pid) public hasPool(_pid) {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        if (pool.poolSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 blocks = block.number - pool.lastRewardBlock;
        for (uint256 i = 0; i < pool.rewardsTokens.length; i++) {
            uint256 unaccountedReward = pool.rewardsPerBlock[i] * blocks;
            pool.accumulatedPerShare[i] = pool.accumulatedPerShare[i] + (unaccountedReward * pool.accuracy[i]) / pool.poolSupply;
        }
        pool.lastRewardBlock = block.number;
    }

    /// @notice Deposit (stake) ASSET tokens
    /// @param _pid Pool's id
    /// @param _amount Amount to stake
    function deposit(uint256 _pid, uint256 _amount) public virtual nonReentrant hasPool(_pid) poolRunning(_pid) {
        updatePool(_pid);
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_msgSender()];

        if (user.rewardsDebts.length == 0 && pool.rewardsTokens.length > 0) {
            user.rewardsDebts = new uint256[](pool.rewardsTokens.length);
        }

        uint256 poolAmountBefore = user.amount;
        user.amount += _amount;

        for (uint256 i = 0; i < pool.rewardsTokens.length; i++) {
            _updateUserInfo(pool, user, i, poolAmountBefore, _msgSender());
        }
        poolInfo[_pid].poolSupply += _amount;

        IERC20Upgradeable(pool.assetToken).safeTransferFrom(_msgSender(), address(this), _amount);
        user.depositTimeStamp = block.timestamp;
        emit Deposit(_msgSender(), _pid, _amount);
    }

    /// @notice Deposit (stake) ASSET tokens
    /// @param _pid Pool's id
    /// @param _amount Amount to stake
    /// @param _user User to stake for
    function depositFor(
        uint256 _pid,
        uint256 _amount,
        address _user
    ) public virtual nonReentrant hasPool(_pid) poolRunning(_pid) {
        updatePool(_pid);
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];

        if (user.rewardsDebts.length == 0 && pool.rewardsTokens.length > 0) {
            user.rewardsDebts = new uint256[](pool.rewardsTokens.length);
        }

        uint256 poolAmountBefore = user.amount;
        user.amount += _amount;

        for (uint256 i = 0; i < pool.rewardsTokens.length; i++) {
            _updateUserInfo(pool, user, i, poolAmountBefore, _user);
        }
        poolInfo[_pid].poolSupply += _amount;

        IERC20Upgradeable(pool.assetToken).safeTransferFrom(_msgSender(), address(this), _amount);
        user.depositTimeStamp = block.timestamp;

        emit Deposit(_user, _pid, _amount);
    }

    /// @notice Withdraw (unstake) ASSET tokens
    /// @param _pid Pool's id
    /// @param _amount Amount to stake
    function withdraw(uint256 _pid, uint256 _amount) public virtual nonReentrant poolRunning(_pid) hasPool(_pid) {
        updatePool(_pid);
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_msgSender()];

        require(user.amount > 0 && user.amount >= _amount, "withdraw: wrong amount");
        require(user.depositTimeStamp + pool.lockTime <= block.timestamp, "withdraw: wait locktime before withdraw");
        uint256 poolAmountBefore = user.amount;
        user.amount -= _amount;

        for (uint256 i = 0; i < pool.rewardsTokens.length; i++) {
            _updateUserInfo(pool, user, i, poolAmountBefore, _msgSender());
        }
        poolInfo[_pid].poolSupply -= _amount;
        IERC20Upgradeable(pool.assetToken).safeTransfer(_msgSender(), _amount);
        emit Withdraw(_msgSender(), _pid, _amount);
    }

    /// @notice Update pool and claim pending rewards for the user
    /// @param _pid Pool's id
    function claimRewards(uint256 _pid) external nonReentrant poolRunning(_pid) {
        _claimRewards(_pid, _msgSender());
    }

    function _updateUserInfo(
        PoolInfo memory pool,
        UserInfo storage user,
        uint256 _tokenNum,
        uint256 _amount,
        address _user
    ) internal returns (uint256 pending) {
        uint256 accumulatedPerShare = pool.accumulatedPerShare[_tokenNum];

        if (_amount > 0) {
            pending = (_amount * accumulatedPerShare) / pool.accuracy[_tokenNum] - user.rewardsDebts[_tokenNum];
            if (pending > 0) {
                IERC20Upgradeable(pool.rewardsTokens[_tokenNum]).safeTransfer(_user, pending);
            }
        }
        user.rewardsDebts[_tokenNum] = (user.amount * accumulatedPerShare) / pool.accuracy[_tokenNum];
    }

    /**********
     * VIEW INTERFACE
     **********/

    /// @notice View function to see pending AQRU on frontend.
    /// @param _pid Pool's id
    /// @param _user Address to check
    /// @return amounts Amounts of reward tokens available to claim
    function pendingRewards(uint256 _pid, address _user) external view hasPool(_pid) returns (uint256[] memory amounts) {
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo memory user = userInfo[_pid][_user];
        amounts = new uint256[](pool.rewardsTokens.length);
        for (uint256 i = 0; i < pool.rewardsTokens.length; i++) {
            uint256 accumulatedPerShare = pool.accumulatedPerShare[i];
            if (block.number > pool.lastRewardBlock && pool.poolSupply != 0) {
                uint256 blocks = block.number - pool.lastRewardBlock;
                uint256 unaccountedReward = pool.rewardsPerBlock[i] * blocks;
                accumulatedPerShare = accumulatedPerShare + (unaccountedReward * pool.accuracy[i]) / pool.poolSupply;
            }
            uint256 rewardsDebts = 0;
            if (user.rewardsDebts.length > 0) {
                rewardsDebts = user.rewardsDebts[i];
            }
            amounts[i] = (user.amount * accumulatedPerShare) / pool.accuracy[i] - rewardsDebts;
        }
    }

    /// @notice Check if pool exists
    /// @param _pid Pool's id
    /// @return true if pool exists
    function poolExist(uint256 _pid) public view returns (bool) {
        return poolInfo[_pid].assetToken != address(0);
    }

    /// @notice Getter for reward token address
    /// @param _pid Pool's id
    /// @param _index Index of the reward token
    /// @return reward token address
    function rewardToken(uint256 _pid, uint256 _index) external view returns (address) {
        PoolInfo memory pool = poolInfo[_pid];
        return pool.rewardsTokens[_index];
    }

    /// @notice Getter for reward token rate
    /// @param _pid Pool's id
    /// @param _index Index of the reward token
    /// @return reward token rate
    function rewardTokenRate(uint256 _pid, uint256 _index) external view returns (uint256) {
        PoolInfo memory pool = poolInfo[_pid];
        return pool.rewardsPerBlock[_index];
    }

    /// @notice Check the user's staked amount in the pool
    /// @param _pid Pool's id
    /// @param _user Address to check
    /// @return Staked amount
    function userPoolAmount(uint256 _pid, address _user) external view returns (uint256) {
        return userInfo[_pid][_user].amount;
    }

    /**********
     * INTERNAL HELPERS
     **********/

    function _claimRewards(uint256 _pid, address _user) internal {
        updatePool(_pid);
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];

        uint256[] memory amounts = new uint256[](pool.rewardsTokens.length);
        for (uint256 i = 0; i < pool.rewardsTokens.length; i++) {
            amounts[i] = _updateUserInfo(pool, user, i, user.amount, _user);
        }
        emit ClaimRewards(_user, _pid, pool.rewardsTokens, amounts);
    }
}
