// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";
import "./UsersStorage.sol";
import "./StagesStorage.sol";

abstract contract AbstractFarm is UsersStorage, StagesStorage {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    constructor(IERC20 pact_, uint256 totalRewardAmount_) LpTokensStorage(pact_) StagesStorage(totalRewardAmount_) public {}

////////////////////////////////////////////////////////////

    struct PoolInfoInFarmStage {
        uint256 lastRewardBlock;    // Last block number that ERC20s distribution occurs.
        uint256 accERC20PerShare;   // Accumulated ERC20s per share, times 1e36.
    }
    // stageId => poolId => PoolInfoInFarmStage
    mapping (uint256 => mapping (uint256 => PoolInfoInFarmStage)) public _poolInfoInFarmStages;

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        for (uint256 poolId = 0; poolId < _poolInfoCount; ++poolId) {
            updatePool(poolId);
        }
    }

    // poolId => firstNotFinishedStage
    mapping (uint256 => uint256) _firstNotFinishedStages;

    function updatePool(uint256 poolId) public {
        require(poolId < _poolInfoCount, "updatePool: Pool is not exists");
        PoolInfo storage pool = _poolInfo[poolId];
        _updatePool(pool);
    }
    function _updatePool(PoolInfo storage pool) internal {
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));

        StageInfo storage stage;
        for (uint256 stageId = _firstNotFinishedStages[pool.id]; stageId < _stageInfoCount; ++stageId) {
            stage = _stageInfo[stageId];

            if (stage.startBlock > block.number) {
                return;
            }

            if (_updatePoolInfoInFarmStage(stage, pool, lpSupply)) {
                _firstNotFinishedStages[pool.id] = stageId.add(1);
            }
        }
    }
    function _updatePoolInfoInFarmStage(
        StageInfo storage stage,
        PoolInfo storage pool,
        uint256 lpSupply
    ) internal returns (bool) {
        uint256 lastBlock = block.number < stage.endBlock ? block.number : stage.endBlock;

        PoolInfoInFarmStage storage poolInFarmStage = _poolInfoInFarmStages[stage.id][pool.id];
        if (poolInFarmStage.lastRewardBlock < stage.startBlock) {
            poolInFarmStage.lastRewardBlock = stage.startBlock;
        }

        if (lastBlock <= poolInFarmStage.lastRewardBlock) {
            return true;
        }

        if (lpSupply == 0) {
            poolInFarmStage.lastRewardBlock = lastBlock;
            return false;
        }

        uint256 nrOfBlocks = lastBlock.sub(poolInFarmStage.lastRewardBlock);
        uint256 erc20Reward = nrOfBlocks.mul(stage.rewardPerBlock).mul(pool.allocPoint).div(_totalAllocPoint);

        poolInFarmStage.accERC20PerShare = poolInFarmStage.accERC20PerShare.add(erc20Reward.mul(1e36).div(lpSupply));
        poolInFarmStage.lastRewardBlock = block.number;
        return false;
    }

////////////////////////////////////////////////////////////

    function pending(uint256 poolId, address account) external view returns (uint256) {
        require(poolId < _poolInfoCount, "pending: Pool is not exists");
        PoolInfo storage pool = _poolInfo[poolId];
        UserInfo storage user = _userInfo[poolId][account];
        uint256 rewardPending = user.rewardPending;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));

        for (uint256 stageId = 0; stageId < _stageInfoCount; ++stageId) {
            StageInfo storage stage = _stageInfo[stageId];

            if (stage.startBlock > block.number) {
                break;
            }

            PoolInfoInFarmStage storage poolInFarmStage = _poolInfoInFarmStages[stageId][poolId];

            uint256 accERC20PerShare = poolInFarmStage.accERC20PerShare;
            uint256 lastBlock = block.number < stage.endBlock ? block.number : stage.endBlock;

            if (lastBlock > poolInFarmStage.lastRewardBlock && lpSupply != 0) {
                uint256 startBlock = poolInFarmStage.lastRewardBlock < stage.startBlock ? stage.startBlock : poolInFarmStage.lastRewardBlock;

                uint256 nrOfBlocks = lastBlock.sub(startBlock);
                uint256 erc20Reward = nrOfBlocks.mul(stage.rewardPerBlock).mul(pool.allocPoint).div(_totalAllocPoint);

                accERC20PerShare = accERC20PerShare.add(erc20Reward.mul(1e36).div(lpSupply));
            }

            uint256 pendingAmount = user.amount.mul(accERC20PerShare).div(1e36).sub(_userRewardDebt[stageId][poolId][account]);
            rewardPending = rewardPending.add(pendingAmount);
        }

        return rewardPending;
    }

////////////////////////////////////////////////////////////

    function _addLpToken(uint256 allocPoint, IUniswapV2Pair lpToken, bool withUpdate) internal {
        if (withUpdate) {
            massUpdatePools();
        }
        _addLpToken(allocPoint, lpToken);
    }

    function _updateLpToken(uint256 poolId, uint256 allocPoint, bool withUpdate) internal {
        if (withUpdate) {
            massUpdatePools();
        }
        _updateLpToken(poolId, allocPoint);
    }

////////////////////////////////////////////////////////////

    uint256 _totalRewardPending;

    // stageId => poolId => account => userRewardDebt
    mapping (uint256 => mapping (uint256 => mapping (address => uint256))) public _userRewardDebt;

    function _beforeBalanceChange(PoolInfo storage pool, address account) internal virtual override {
        _updatePool(pool);
        UserInfo storage user = _userInfo[pool.id][account];

        StageInfo storage stage;
        for (uint256 stageId = 0; stageId < _stageInfoCount; ++stageId) {
            stage = _stageInfo[stageId];
            if (stage.startBlock > block.number) {
                return;
            }
            PoolInfoInFarmStage storage poolInFarmStage = _poolInfoInFarmStages[stage.id][pool.id];

            uint256 pendingAmount = user.amount
                .mul(poolInFarmStage.accERC20PerShare)
                .div(1e36)
                .sub(_userRewardDebt[stage.id][pool.id][account]);

            user.rewardPending = user.rewardPending.add(pendingAmount);
            _totalRewardPending = _totalRewardPending.add(pendingAmount);
        }
    }
    function _afterBalanceChange(PoolInfo storage pool, address account) internal virtual override {
        UserInfo storage user = _userInfo[pool.id][account];

        StageInfo storage stage;
        for (uint256 stageId = 0; stageId < _stageInfoCount; ++stageId) {
            stage = _stageInfo[stageId];
            if (stage.startBlock > block.number) {
                return;
            }

            PoolInfoInFarmStage storage poolInFarmStage = _poolInfoInFarmStages[stage.id][pool.id];
            _userRewardDebt[stage.id][pool.id][account] = user.amount.mul(poolInFarmStage.accERC20PerShare).div(1e36);
        }
    }

    function _updateUserRewardDebtAndPending(PoolInfo storage pool, address account) internal {
        _updatePool(pool);
        UserInfo storage user = _userInfo[pool.id][account];

        StageInfo storage stage;
        for (uint256 stageId = 0; stageId < _stageInfoCount; ++stageId) {
            stage = _stageInfo[stageId];
            if (stage.startBlock > block.number) {
                return;
            }
            PoolInfoInFarmStage storage poolInFarmStage = _poolInfoInFarmStages[stage.id][pool.id];

            uint256 pendingAmount = user.amount
                .mul(poolInFarmStage.accERC20PerShare)
                .div(1e36)
                .sub(_userRewardDebt[stage.id][pool.id][account])
            ;

            user.rewardPending = user.rewardPending.add(pendingAmount);
            _totalRewardPending = _totalRewardPending.add(pendingAmount);
            _userRewardDebt[stage.id][pool.id][account] = user.amount.mul(poolInFarmStage.accERC20PerShare).div(1e36);
        }
    }

////////////////////////////////////////////////////////////

    event Harvest(address indexed user, uint256 indexed poolId, uint256 amount);
    // Withdraw LP tokens from Farm.
    function withdrawAndHarvest(uint256 poolId, uint256 amount) public {
        require(poolId < _poolInfoCount, "withdrawAndHarvest: Pool is not exists");
        PoolInfo storage pool = _poolInfo[poolId];
        require(amount > 0, "withdrawAndHarvest: can't withdraw zero amount");
        UserInfo storage user = _userInfo[poolId][msg.sender];
        require(user.amount >= amount, "withdrawAndHarvest: can't withdraw more than deposit");

        _beforeBalanceChange(pool, msg.sender);

        user.amount = user.amount.sub(amount);
        pool.lpToken.safeTransfer(address(msg.sender), amount);
        emit Withdraw(msg.sender, poolId, amount);

        _pact.transfer(msg.sender, user.rewardPending);
        _totalRewardPending = _totalRewardPending.sub(user.rewardPending);

        emit Harvest(msg.sender, poolId, user.rewardPending);
        user.rewardPending = 0;

        _afterBalanceChange(pool, msg.sender);
    }
    // Harvest PACTs from Farm.
    function harvest(uint256 poolId) public {
        require(poolId < _poolInfoCount, "harvest: Pool is not exists");
        PoolInfo storage pool = _poolInfo[poolId];
        UserInfo storage user = _userInfo[poolId][msg.sender];
        require(user.userExists, "harvest: can't harvest from new user");

        _updateUserRewardDebtAndPending(pool, msg.sender);

        _pact.transfer(msg.sender, user.rewardPending);
        _totalRewardPending = _totalRewardPending.sub(user.rewardPending);

        emit Harvest(msg.sender, poolId, user.rewardPending);
        user.rewardPending = 0;
    }

}