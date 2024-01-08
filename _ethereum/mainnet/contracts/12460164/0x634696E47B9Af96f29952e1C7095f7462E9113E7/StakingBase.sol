//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.6.12;

// Libraries
import "./SafeMath.sol";
import "./UserInfoLib.sol";
import "./PoolInfoLib.sol";
import "./Address.sol";

// Contracts
import "./Base.sol";

// Interfaces
import "./IStaking.sol";
import "./ITokenValuator.sol";

abstract contract StakingBase is Base, IStaking {
    using Address for address;
    using SafeMath for uint256;
    using UserInfoLib for UserInfoLib.UserInfo;
    using PoolInfoLib for PoolInfoLib.PoolInfo;

    uint256 public constant AMOUNT_SCALE = 1e12;

    uint256 public constant PERCENTAGE_100 = 100;

    uint256 public constant DEFAULT_FEE = 10;

    address public immutable output;

    address public tokenValuator;

    address public feeReceiver;

    uint256 public outputPerBlock;

    uint256 public startBlock;

    // Block number where the bonus rewards end.
    uint256 public bonusEndBlock;

    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint;

    // Info of each pool.
    PoolInfoLib.PoolInfo[] public poolInfo;

    // Info of each user that stakes tokens.
    mapping(uint256 => mapping(address => UserInfoLib.UserInfo)) internal userInfo;

    mapping(address => bool) public existsPool;

    constructor(
        address settingsAddress,
        address outputAddress,
        address feeReceiverAddress,
        address tokenValuatorAddress,
        uint256 outputAmountPerBlock,
        uint256 startBlockNumber,
        uint256 bonusEndBlockNumber
    ) public Base(settingsAddress) {
        require(outputAddress.isContract(), "OUTPUT_TOKEN_MUST_BE_CONTRACT");
        require(feeReceiverAddress != address(0x0), "FEE_RECEIVER_IS_REQUIRED");
        require(tokenValuatorAddress.isContract(), "VALUATOR_MUST_BE_CONTRACT");
        require(outputAmountPerBlock > 0, "OUTPUT_AMOUNT_GT_ZERO");
        require(startBlockNumber > 0, "START_BLOCK_GT_ZERO");
        require(startBlockNumber <= bonusEndBlockNumber, "START_LTE_BONUS_END");

        output = outputAddress;
        feeReceiver = feeReceiverAddress;
        tokenValuator = tokenValuatorAddress;
        outputPerBlock = outputAmountPerBlock;
        startBlock = startBlockNumber;
        bonusEndBlock = bonusEndBlockNumber;
    }

    // Add a new token to the pool. Can only be called by the owner.
    // @dev DO NOT add the same token more than once. Rewards will be messed up if you do. A validation was added to verify it.
    function addPool(
        uint256 allocationPoints,
        address token,
        bool withUpdate
    ) external override onlyConfigurator(msg.sender) {
        require(token.isContract(), "TOKEN_MUST_BE_CONTRACT");
        require(!existsPool[token], "POOL_FOR_TOKEN_ALREADY_EXISTS");
        ITokenValuator(tokenValuator).requireIsConfigured(token);
        if (withUpdate) {
            _massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(allocationPoints);
        poolInfo.push(
            PoolInfoLib.PoolInfo({
                totalDeposit: 0,
                token: token,
                allocPoint: allocationPoints,
                lastRewardBlock: lastRewardBlock,
                accTokenPerShare: 0,
                isPaused: false
            })
        );
        existsPool[token] = true;
        emit NewPoolAdded(token, poolInfo.length - 1, allocationPoints, totalAllocPoint);
    }

    function pausePool(uint256 pid) external override existPool(pid) onlyPauser(msg.sender) {
        PoolInfoLib.PoolInfo storage pool = poolInfo[pid];
        pool.requireIsNotPaused();
        pool.setIsPaused(true);

        emit PoolPauseSet(pid, true);
    }

    function unpausePool(uint256 pid) external override existPool(pid) onlyPauser(msg.sender) {
        PoolInfoLib.PoolInfo storage pool = poolInfo[pid];
        pool.requireIsPaused();
        pool.setIsPaused(false);

        emit PoolPauseSet(pid, false);
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() external override {
        _massUpdatePools();
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyUnstakeAll(uint256 pid)
        external
        override
        existPool(pid)
        onlyEOAIfSet(msg.sender)
    {
        PoolInfoLib.PoolInfo storage pool = poolInfo[pid];
        UserInfoLib.UserInfo storage user = userInfo[pid][msg.sender];

        _emergencyUnstakeAll(msg.sender, pid, pool, user);

        emit EmergencyUnstake(msg.sender, pid);
    }

    function setOutputPerBlock(uint256 newOutputPerBlock)
        external
        override
        onlyConfigurator(msg.sender)
    {
        require(
            newOutputPerBlock > 0 && outputPerBlock != newOutputPerBlock,
            "NEW_OUTPUT_PER_BLOCK_INVALID"
        );
        uint256 oldOutputPerBlock = outputPerBlock;
        outputPerBlock = newOutputPerBlock;
        emit OutputPerBlockUpdated(oldOutputPerBlock, newOutputPerBlock);
    }

    function setFeeReceiver(address newFeeReceiver) external override onlyConfigurator(msg.sender) {
        require(
            newFeeReceiver != address(0x0) && newFeeReceiver != feeReceiver,
            "NEW_FEE_RECEIVER_INVALID"
        );
        address oldFeeReceiver = feeReceiver;
        feeReceiver = newFeeReceiver;
        emit FeeReceiverUpdated(oldFeeReceiver, newFeeReceiver);
    }

    function setTokenValuator(address newTokenValuator)
        external
        override
        onlyConfigurator(msg.sender)
    {
        require(newTokenValuator.isContract(), "TOKEN_VALUATOR_MUST_BE_CONTRACT");
        require(newTokenValuator != tokenValuator, "TOKEN_VALUATOR_MUST_BE_NEW");
        address oldTokenValutor = tokenValuator;
        tokenValuator = newTokenValuator;
        emit TokenValuatorUpdated(oldTokenValutor, newTokenValuator);
    }

    // Update the given pool's token allocation point. Can only be called by the owner.
    function setAllocPoint(
        uint256 pid,
        uint256 newAllocPoint,
        bool withUpdate
    ) external override onlyConfigurator(msg.sender) existPool(pid) {
        if (withUpdate) {
            _massUpdatePools();
        }
        uint256 oldAllocPoint = poolInfo[pid].allocPoint;
        totalAllocPoint = totalAllocPoint.sub(poolInfo[pid].allocPoint).add(newAllocPoint);
        poolInfo[pid].allocPoint = newAllocPoint;

        emit AllocPointsUpdated(pid, oldAllocPoint, newAllocPoint);
    }

    /* View Functions */
    function getTotalPools() external view override returns (uint256) {
        return poolInfo.length;
    }

    function getInfo()
        external
        view
        override
        returns (
            uint256 totalPools,
            uint256 outputPerBlockNumber,
            uint256 startBlockNumber,
            uint256 bonusEndBlockNumber,
            bool bonusFinished,
            uint256 totalAllocPoints
        )
    {
        return (
            poolInfo.length,
            outputPerBlock,
            startBlock,
            bonusEndBlock,
            bonusEndBlock < block.number,
            totalAllocPoint
        );
    }

    function getUserInfoForPool(uint256 pid, address account)
        external
        view
        override
        returns (
            uint256 amount,
            uint256 rewardDebt,
            uint256[] memory tokenIDs
        )
    {
        amount = userInfo[pid][account].amount;
        rewardDebt = userInfo[pid][account].rewardDebt;
        tokenIDs = userInfo[pid][account].getTokenIds();
    }

    function getPoolInfoFor(uint256 pid)
        external
        view
        override
        returns (
            uint256 totalDeposit,
            address token,
            uint256 allocPoint,
            uint256 lastRewardBlock,
            uint256 accTokenPerShare,
            bool isPaused
        )
    {
        if (pid >= poolInfo.length) {
            return (0, address(0x0), 0, 0, 0, false);
        }
        totalDeposit = poolInfo[pid].totalDeposit;
        token = poolInfo[pid].token;
        allocPoint = poolInfo[pid].allocPoint;
        lastRewardBlock = poolInfo[pid].lastRewardBlock;
        accTokenPerShare = poolInfo[pid].accTokenPerShare;
        isPaused = poolInfo[pid].isPaused;
    }

    // Return reward multiplier over the given fromBlock to toBlock block.
    function getMultiplier(uint256 fromBlock, uint256 toBlock)
        external
        view
        override
        returns (uint256)
    {
        return _getMultiplier(fromBlock, toBlock);
    }

    function getPendingTokens(uint256 pid, address account)
        external
        view
        override
        returns (uint256)
    {
        return _getPendingTokens(pid, account);
    }

    function getAllPendingTokens(address account) external view override returns (uint256) {
        uint256 allPendingTokens = 0;
        for (uint256 index = 0; index < poolInfo.length; index += 1) {
            allPendingTokens = allPendingTokens.add(_getPendingTokens(index, account));
        }
        return allPendingTokens;
    }

    function getPools()
        external
        view
        override
        returns (
            address[] memory tokens,
            uint256[] memory totalDeposit,
            uint256[] memory allocPoints,
            uint256[] memory lastRewardBlocks,
            uint256[] memory accTokenPerShares,
            bool[] memory isPaused,
            uint256 totalPools
        )
    {
        totalPools = poolInfo.length;
        tokens = new address[](totalPools);
        totalDeposit = new uint256[](totalPools);
        allocPoints = new uint256[](totalPools);
        lastRewardBlocks = new uint256[](totalPools);
        accTokenPerShares = new uint256[](totalPools);
        isPaused = new bool[](totalPools);
        for (uint256 indexAt = 0; indexAt < totalPools; indexAt++) {
            tokens[indexAt] = poolInfo[indexAt].token;
            totalDeposit[indexAt] = poolInfo[indexAt].totalDeposit;
            allocPoints[indexAt] = poolInfo[indexAt].allocPoint;
            lastRewardBlocks[indexAt] = poolInfo[indexAt].lastRewardBlock;
            accTokenPerShares[indexAt] = poolInfo[indexAt].accTokenPerShare;
            isPaused[indexAt] = poolInfo[indexAt].isPaused;
        }
    }

    function sweep(address token, uint256 amountOrId) external override onlyOwner(msg.sender) {
        require(!existsPool[token], "TOKEN_POOL_EXIST");
        uint256 amountOrIdSweeped = _sweep(token, amountOrId, msg.sender);

        emit TokenSweeped(token, amountOrIdSweeped);
    }

    /* Internal Funcctions  */

    // Staking tokens for token allocation.
    function _stake(uint256 pid, uint256 amountOrId) internal {
        PoolInfoLib.PoolInfo storage pool = poolInfo[pid];
        UserInfoLib.UserInfo storage user = userInfo[pid][msg.sender];
        uint256 valuedAmountOrId =
            ITokenValuator(tokenValuator).valuate(pool.token, msg.sender, pid, amountOrId);

        _beforeUserStake(msg.sender, amountOrId, valuedAmountOrId, pool, user);
        _updatePool(pid);
        if (user.amount > 0) {
            uint256 pending =
                user.amount.mul(pool.accTokenPerShare).div(AMOUNT_SCALE).sub(user.rewardDebt);
            _safeOutputTokenTransfer(address(this), msg.sender, pid, pending);
        }

        _safePoolTokenTransferFrom(pool.token, msg.sender, address(this), pid, amountOrId);

        user.stake(valuedAmountOrId, pool.accTokenPerShare);
        pool.stake(valuedAmountOrId);

        _afterUserStake(amountOrId, valuedAmountOrId, pool, user);
        emit Staked(msg.sender, pid, amountOrId, valuedAmountOrId);
    }

    // Unstake tokens from this contract.
    function _unstake(uint256 pid, uint256 amountOrId) internal {
        PoolInfoLib.PoolInfo storage pool = poolInfo[pid];
        UserInfoLib.UserInfo storage user = userInfo[pid][msg.sender];

        uint256 valuedAmountOrId =
            ITokenValuator(tokenValuator).valuate(pool.token, msg.sender, pid, amountOrId);
        _beforeUserUnstake(msg.sender, amountOrId, valuedAmountOrId, pool, user);
        require(user.amount >= valuedAmountOrId, "VALUED_AMOUNT_EXCEEDS_STAKED");
        _updatePool(pid);
        uint256 pending =
            user.amount.mul(pool.accTokenPerShare).div(AMOUNT_SCALE).sub(user.rewardDebt);
        _safeOutputTokenTransfer(address(this), msg.sender, pid, pending);

        user.unstake(valuedAmountOrId, pool.accTokenPerShare);
        pool.unstake(valuedAmountOrId);
        _afterUserUnstake(amountOrId, valuedAmountOrId, pool, user);

        _safePoolTokenTransfer(pool.token, address(this), msg.sender, pid, amountOrId);

        emit Unstaked(msg.sender, pid, amountOrId, valuedAmountOrId);
    }

    function _beforeUserStake(
        address account,
        uint256 amountOrId,
        uint256 valuedAmountOrId,
        PoolInfoLib.PoolInfo storage pool,
        UserInfoLib.UserInfo storage user
    ) internal view virtual {}

    function _afterUserStake(
        uint256 amountOrId,
        uint256 valuedAmountOrId,
        PoolInfoLib.PoolInfo storage pool,
        UserInfoLib.UserInfo storage user
    ) internal virtual {}

    function _afterUserUnstake(
        uint256 amountOrId,
        uint256 valuedAmountOrId,
        PoolInfoLib.PoolInfo storage pool,
        UserInfoLib.UserInfo storage user
    ) internal virtual {}

    function _beforeUserUnstake(
        address account,
        uint256 amountOrId,
        uint256 valuedAmountOrId,
        PoolInfoLib.PoolInfo storage pool,
        UserInfoLib.UserInfo storage user
    ) internal view virtual {}

    function _emergencyUnstakeAll(
        address userAccount,
        uint256 pid,
        PoolInfoLib.PoolInfo storage pool,
        UserInfoLib.UserInfo storage user
    ) internal virtual {}

    function _safePoolTokenTransferFrom(
        address poolToken,
        address from,
        address to,
        uint256 pid,
        uint256 amountOrIId
    ) internal virtual;

    function _safePoolTokenTransfer(
        address poolToken,
        address from,
        address to,
        uint256 pid,
        uint256 amountOrIId
    ) internal virtual;

    function _getPoolTokenBalance(
        address poolToken,
        address account,
        uint256 pid
    ) internal view virtual returns (uint256);

    function _safeOutputTokenTransfer(
        address from,
        address to,
        uint256 pid,
        uint256 amount
    ) internal virtual;

    function _safeOutputTokenMint(
        address from,
        address to,
        uint256 pid,
        uint256 amount
    ) internal virtual;

    function _sweep(
        address token,
        uint256 amountOrId,
        address to
    ) internal virtual returns (uint256);

    // Update reward variables of the given pool to be up-to-date.
    function _updatePool(uint256 pid) internal {
        PoolInfoLib.PoolInfo storage pool = poolInfo[pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }

        uint256 tokenSupply = _getPoolTokenBalance(pool.token, address(this), pid);
        if (tokenSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = _getMultiplier(pool.lastRewardBlock, block.number);
        uint256 tokenReward =
            multiplier.mul(outputPerBlock).mul(pool.allocPoint).div(totalAllocPoint);

        _safeOutputTokenMint(
            address(this),
            feeReceiver,
            pid,
            tokenReward.mul(_getFee()).div(PERCENTAGE_100)
        );
        _safeOutputTokenMint(address(this), address(this), pid, tokenReward);

        pool.accTokenPerShare = pool.accTokenPerShare.add(
            tokenReward.mul(AMOUNT_SCALE).div(tokenSupply)
        );
        pool.lastRewardBlock = block.number;
    }

    function _massUpdatePools() internal {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            _updatePool(pid);
        }
    }

    function _getFee() internal view returns (uint256) {
        uint256 fee = _getPlatformSettingsValue(_settingsConsts().FEE());
        return fee == 0 ? DEFAULT_FEE : fee;
    }

    /**
        @return The bonus muliplier for early stakers.
     */
    function _getBonusMultiplier() internal view returns (uint256) {
        uint256 bonusMultiplier = _getPlatformSettingsValue(_settingsConsts().BONUS_MULTIPLIER());
        return bonusMultiplier == 0 ? 1 : bonusMultiplier;
    }

    // Return reward multiplier over the given fromBlock to toBlock block.
    function _getMultiplier(uint256 fromBlock, uint256 toBlock) internal view returns (uint256) {
        uint256 bonusMultiplier = _getBonusMultiplier();

        if (toBlock <= bonusEndBlock) {
            return toBlock.sub(fromBlock).mul(bonusMultiplier);
        } else if (fromBlock >= bonusEndBlock) {
            return toBlock.sub(fromBlock);
        } else {
            return
                bonusEndBlock.sub(fromBlock).mul(bonusMultiplier).add(toBlock.sub(bonusEndBlock));
        }
    }

    function _getPendingTokens(uint256 pid, address account) internal view returns (uint256) {
        if (pid >= poolInfo.length) {
            return 0;
        }
        PoolInfoLib.PoolInfo storage pool = poolInfo[pid];
        UserInfoLib.UserInfo storage user = userInfo[pid][account];
        uint256 accTokenPerShare = pool.accTokenPerShare;
        uint256 tokenSupply = _getPoolTokenBalance(pool.token, address(this), pid);

        if (block.number > pool.lastRewardBlock && tokenSupply != 0) {
            uint256 multiplier = _getMultiplier(pool.lastRewardBlock, block.number);
            uint256 tokenReward =
                multiplier.mul(outputPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accTokenPerShare = accTokenPerShare.add(tokenReward.mul(AMOUNT_SCALE).div(tokenSupply));
        }
        return user.amount.mul(accTokenPerShare).div(AMOUNT_SCALE).sub(user.rewardDebt);
    }

    /** Modifiers */

    modifier onlyEOAIfSet(address account) {
        uint256 allowOnlyEOA = _getPlatformSettingsValue(_settingsConsts().ALLOW_ONLY_EOA());
        if (account.isContract()) {
            // allowOnlyEOA = 0 => Contracts and External Owned Accounts
            // allowOnlyEOA = 1 => Only External Owned Accounts (not contracts).
            require(allowOnlyEOA == 0, "ONLY_EOA_ALLOWED");
        }
        _;
    }

    modifier existPool(uint256 pid) {
        require(poolInfo.length > pid, "POOL_ID_DOESNT_EXIST");
        _;
    }

    modifier whenPoolIsNotPaused(uint256 pid) {
        PoolInfoLib.PoolInfo storage pool = poolInfo[pid];
        require(!pool.isPaused, "POOL_IS_PAUSED");
        _;
    }

    modifier whenPoolIsPaused(uint256 pid) {
        PoolInfoLib.PoolInfo storage pool = poolInfo[pid];
        require(pool.isPaused, "POOL_ISNT_PAUSED");
        _;
    }
}
