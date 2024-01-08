//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./AllocationPool.sol";
import "./LinearPool.sol";

contract StakingPool is
    Initializable,
    OwnableUpgradeable,
    LinearPool,
    AllocationPool
{
    /**
     * @notice Initialize the contract, get called in the first time deploy
     * @param _rewardToken the reward token for the allocation pool and the accepted token for the linear pool
     * @param _rewardPerBlock the number of reward tokens that got unlocked each block
     * @param _startBlock the number of block when farming start
     */
    function __StakingPool_init(
        IERC20 _rewardToken,
        uint128 _rewardPerBlock,
        uint64 _startBlock
    ) external initializer {
        __Ownable_init();

        __AllocationPool_init(_rewardToken, _rewardPerBlock, _startBlock);
        __LinearPool_init(_rewardToken);
    }

    /**
     * @notice Withdraw from allocation pool and deposit to linear pool
     * @param _allocPoolId id of the allocation pool
     * @param _linearPoolId id of the linear pool
     * @param _amount amount to convert
     * @param _harvestAllocReward whether the user want to claim the rewards from the allocation pool or not
     */
    function fromAllocToLinear(
        uint256 _allocPoolId,
        uint256 _linearPoolId,
        uint128 _amount,
        bool _harvestAllocReward
    )
        external
        allocValidatePoolById(_allocPoolId)
        linearValidatePoolById(_linearPoolId)
    {
        address account = msg.sender;
        AllocPoolInfo storage allocPool = allocPoolInfo[_allocPoolId];

        require(
            allocPool.lpToken == linearAcceptedToken,
            "AllocStakingPool: invalid allocation pool"
        );

        _allocWithdraw(_allocPoolId, _amount, _harvestAllocReward);
        emit AllocWithdraw(account, _allocPoolId, _amount);

        _linearDeposit(_linearPoolId, _amount, account);
        emit LinearDeposit(_linearPoolId, account, _amount);
    }
}
