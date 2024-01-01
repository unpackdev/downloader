// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./GluwacoinModels.sol";
import "./draft-ERC20PermitUpgradeable.sol";
import "./SafeCastUpgradeable.sol";
import "./IRewardToken.sol";
import "./ExtendedERC20.sol";
import "./StakeQueue.sol";
import "./IStakedVotesUpgradeable.sol";

contract ERC20Reward is ExtendedERC20, IRewardToken {
    using SafeCastUpgradeable for uint256;
    struct User {
        uint256 amountStaked;
        StakeQueue.QueueStorage queue;
        mapping(uint256 => uint256) pendingMinting;
        mapping(uint256 => uint256) debt;
        mapping(uint256 => uint256) debtBlock; // next block to calculate
        uint256 debtCount;
    }
    struct Pool {
        uint256 accGatePerShare;
        uint256 userDebtShare;
        uint256 lastUpdatedBlock;
        uint256 lastUserShareUpdatedBlock;
        uint256 totalStaked;
        uint256 totalStakeIncludePending;
        uint256 lastEmptyBlock;
        StakeQueue.QueueStorage queue;
    }

    modifier onlyGTD() {
        require(_msgSender() == address(GTD), 'Caller must be GTD contract');
        _;
    }
    mapping(uint32 => uint32) private _userQueueToPoolQueue; //key: userQueueToPoolQueueIndex, value: data position of pool queue
    uint32 private _userQueueToPoolQueueIndex;
    /** 
     * @dev - _userInfo store each individual users staked info. 
        {amountStaked} - the user staked amount that lockupPeriod is mature    
        {queue} - when user stake GTD, the amount and mature blockNum will add to this queue
        {pendingMinting} - when user stake/unstake that cause amountStaked change, the current mintableAllowance will add to pendingMinting  
        {debt} - once user stake, the debt is current accPerShare * amountStaked. It makes mintableAllowance at first lockupPeriod due be 0
        {debtBlock} - the blockNum that lockupPeriod mature
        {debtCount} - pointer of debt relating mapping
    */
    mapping(address => User) internal _userInfo;
    /** 
     * @dev - _poolInfo general pool info . 
        {accGatePerShare} - the value that shows each GTD token can earn how many Gates 
        {userDebtShare} - a future accGatePerShare use to calculate user.debt (can be removed)
        {lastUpdatedBlock} - update when update() is called
        {lastUserShareUpdatedBlock} - (can be removed)
        {totalStaked} - total GTD staked in pool that lockupPeriod is mature
        {totalStakeIncludePending} - totalStaked + unmatured amount in queue
        {lastEmptyBlock} - record the blockNum when pool becomes 0
        {queue} - the staked amout that still waiting for lockupPeriod, will add into totalStaked once lockupPeriod is mature
    */
    Pool internal _poolInfo;
    uint256 private _amountPerBlock;
    uint256 private _halveBlocks;
    uint256 private _initalBlock;
    uint256 private _lockUpPeriod;
    // most of time total GTD staked value is greater than reward. It will make this calculation (reward/totalStaked) be 0. ACC_ADJUST is default 10**25 that corrects the calculation
    uint256 private constant ACC_ADJUST = 1e25;
    IStakedVotesUpgradeable private GTD;
    mapping(uint16 => uint32) private blockToSub;

    function __ERC20Reward_init(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address GTDaddress_,
        uint256 halveBlocks_,
        uint256 initalReward_,
        uint256 lockUpPeriod_,
        uint256 initialBlock_
    ) internal onlyInitializing {
        __ExtendedERC20_init_unchained(name_, symbol_, decimals_);
        __ERC20Reward_init_unchained(GTDaddress_);
        _halveBlocks = halveBlocks_;
        _amountPerBlock = initalReward_;
        _lockUpPeriod = lockUpPeriod_;
        _initalBlock = initialBlock_;
    }

    function __ERC20Reward_init_unchained(address GTDaddress_) internal onlyInitializing {
        GTD = IStakedVotesUpgradeable(GTDaddress_);
        StakeQueue.initialize(_poolInfo.queue);
    }

    function settings()
        external
        view
        returns (
            uint256 halveBlocks,
            uint256 initialBlock,
            address governanceToken
        )
    {
        return (_halveBlocks, _initalBlock, address(GTD));
    }

    function _setLockupPeriodAndHalve(uint256 newLockupPeriod, uint256 newHalve) internal virtual {
        unchecked {
            _lockUpPeriod = newLockupPeriod;
            _halveBlocks = newHalve;
        }
    }

    function _setLastEmptyBlock(uint256 lastEmptyBlock) internal {
        unchecked {
            _poolInfo.lastEmptyBlock = lastEmptyBlock;
        }
    }
    function _setUserDebt(address account, uint256 position, uint256 amount)internal{
        _userInfo[account].debt[position] = amount;
    }
    function _fixPendingReward(address account, uint256 position, uint256 amount) internal {
        _userInfo[account].pendingMinting[position] = amount;
    }
    function getPoolInfo()
        external
        view
        returns (
            uint256 accGatePerShare,
            uint256 userDebtShare,
            uint256 lastUpdatedBlock,
            uint256 accAdjust,
            uint256 totalStaked,
            uint256 totalStakeIncludePending,
            uint256 lastEmptyBlock,
            uint256 poolQueueLength,
            uint32 poolQueueFirst,
            uint32 poolQueueLast
        )
    {
        return (
            _poolInfo.accGatePerShare,
            _poolInfo.userDebtShare,
            _poolInfo.lastUpdatedBlock,
            ACC_ADJUST,
            _poolInfo.totalStaked,
            _poolInfo.totalStakeIncludePending,
            _poolInfo.lastEmptyBlock,
            StakeQueue.length(_poolInfo.queue),
            _poolInfo.queue.first,
            _poolInfo.queue.last
        );
    }

    function getPoolQueue(uint256 index) external view returns (uint256 blockNum, uint256 amount) {
        require(_poolInfo.queue.data[index].blockNum > 0, 'index out of range');
        return (_poolInfo.queue.data[index].blockNum, _poolInfo.queue.data[index].amount);
    }

    function getUserQueue(address account, uint256 index) external view returns (uint256 blockNum, uint256 amount) {
        require(_userInfo[account].queue.data[index].blockNum > 0, 'index out of range');
        return (_userInfo[account].queue.data[index].blockNum, _userInfo[account].queue.data[index].amount);
    }

    function getUserInfo(address account)
        external
        view
        returns (
            uint256 amountStaked,
            uint256 debtCount,
            uint256 queueLength,
            uint32 first,
            uint32 last
        )
    {
        return (
            _userInfo[account].amountStaked,
            _userInfo[account].debtCount,
            StakeQueue.length(_userInfo[account].queue),
            _userInfo[account].queue.first,
            _userInfo[account].queue.last
        );
    }

    function getUserDebt(address account, uint256 index)
        external
        view
        returns (
            uint256 debt,
            uint256 debtBlock,
            uint256 pending
        )
    {
        require(_userInfo[account].debtCount > index, 'Index out of bound');
        return (
            _userInfo[account].debt[index],
            _userInfo[account].debtBlock[index],
            _userInfo[account].pendingMinting[index]
        );
    }

    /**
        @param account - user wallet address
        @dev in short, mintableAllowance = pendingMinting + (accGatePerShare * user.amountStaked) - user.debt
        the for-loop start with the latest item of debt and moving on if current blockNum not pass the lockupPeriod
        once looping to the item that debtBlock <= currentBlock, it will stop looping         
     */
    function _getMintableAllowance(address account) internal view returns (uint256 mintableAllowance) {
        uint256 debtCount = _userInfo[account].debtCount;
        for (uint256 i = debtCount; i > 0; ) {
            if (block.number > _userInfo[account].debtBlock[i - 1]) {
                mintableAllowance =
                    _userInfo[account].pendingMinting[i - 1] +
                    ((_poolInfo.accGatePerShare *
                        (_userInfo[account].amountStaked + _lookupLockupPeriodForUser(account, block.number))) /
                        ACC_ADJUST) -
                    _userInfo[account].debt[i - 1];
                break;
            }
            unchecked {
                --i;
            }
        }
    }

    function getUnclaimedReward(address account) external view returns (uint256 amount) {
        return _getFutureReward(account, block.number + 1);
    }

    /**
        @dev similar to getMintableAllowance, but needs to provide a future blockNum to predict the future total rewards
        this function is mean to calculate the pendingMinting value, we need to know the mintableAllowance in (block.number + lockupPeriod) at block.number
     */
    function _getFutureReward(address account, uint256 blockNum) internal view returns (uint256 amount) {
        (uint256 futureAcc, uint256 futureStaked, uint256 latsUpdate) = _getFutureAcc(blockNum);
        if (futureStaked > 0) {
            futureAcc += (_getRangeReward(latsUpdate, blockNum) * ACC_ADJUST) / futureStaked;
        }
        for (uint256 i = _userInfo[account].debtCount; i > 0; ) {
            if (blockNum > _userInfo[account].debtBlock[i - 1]) {
                amount =
                    _userInfo[account].pendingMinting[i - 1] +
                    ((futureAcc * (_userInfo[account].amountStaked + _lookupLockupPeriodForUser(account, blockNum))) /
                        ACC_ADJUST) -
                    _userInfo[account].debt[i - 1];
                break;
            }
            unchecked {
                --i;
            }
        }
    }

    function getRewardData(address account, uint256 blockNum)
        external
        view
        returns (
            uint256 futureAcc,
            uint256 futureStaked,
            uint256 lastUpdate,
            uint256 lockupPeriodForUser,
            uint256 rangeReward,
            uint256 debt
        )
    {
        (futureAcc, futureStaked, lastUpdate) = _getFutureAcc(blockNum);
        
        rangeReward = _getRangeReward(lastUpdate, blockNum);
        if (futureStaked > 0) {
            futureAcc += (rangeReward * ACC_ADJUST) / futureStaked;
        }
        lockupPeriodForUser = _lookupLockupPeriodForUser(account, blockNum);
        debt = lockupPeriodForUser * futureAcc / ACC_ADJUST;
    }

    function _getFutureAcc(uint256 blockNum)
        private
        view
        returns (
            uint256 futureAcc,
            uint256 futureStaked,
            uint256 lastBlock
        )
    {
        futureAcc = _poolInfo.accGatePerShare;
        futureStaked = _poolInfo.totalStaked;
        lastBlock = _poolInfo.lastUpdatedBlock;
        if (!StakeQueue.isEmpty(_poolInfo.queue)) {
            for (uint256 i = _poolInfo.queue.first; i <= _poolInfo.queue.last; ) {
                if(blockNum >= _poolInfo.queue.data[i].blockNum){
                    if (futureStaked > 0) {
                        futureAcc +=
                            (_getRangeReward(lastBlock, _poolInfo.queue.data[i].blockNum) * ACC_ADJUST) /
                            futureStaked;
                    }
                    unchecked {
                        lastBlock = _poolInfo.queue.data[i].blockNum;
                        futureStaked += _poolInfo.queue.data[i].amount;
                    }
                }else{
                    break;
                }
                unchecked {
                    ++i;
                }
            }
        }
    }

    /**
        @dev the next halve change block base on current blockNum
     */
    function getNextRewardChangeBlock() public view virtual returns (uint256 nextBlock) {
        return _initalBlock + _halveBlocks * ((block.number + _halveBlocks - _initalBlock) / _halveBlocks);
    }

    /**
        @dev the next halve change block base on provided blockNum
     */
    function getNextRewardChangeBlock(uint256 blockNum) public view returns (uint256 nextBlock) {
        return _initalBlock + _halveBlocks * ((blockNum + _halveBlocks - _initalBlock) / _halveBlocks);
    }

    /**
        @dev Gate reward amount per block base on current blockNum
     */
    function getCurrentReward() public view virtual returns (uint256 currentReward) {
        require(block.number > _initalBlock, 'ERC20Reward: no reward before initial block');

        return _amountPerBlock / 2**((block.number - _initalBlock) / _halveBlocks);
    }

    /**
        @dev Gate reward amount per block base on provided blockNum
     */
    function getCurrentReward(uint256 blockNum) public view returns (uint256 currentReward) {
        require(blockNum > _initalBlock, 'ERC20Reward: no reward before initial block');

        return _amountPerBlock / 2**((blockNum - _initalBlock) / _halveBlocks);
    }

    function getLockupPeriod() external view virtual returns (uint256 lockupPeriod) {
        return _lockUpPeriod;
    }

    function getRangeReward(uint256 start, uint256 end) external view returns (uint256 totalReward) {
        return _getRangeReward(start, end);
    }

    /**
        @param start - start blockNum
        @param end - end blockNum
        @dev returns total Gate reward from start to range, this will consider the halving 
     */
    function _getRangeReward(uint256 start, uint256 end) internal view returns (uint256 totalReward) {
        uint256 nextHalveBlock = getNextRewardChangeBlock(start);
        if (start <= _poolInfo.lastEmptyBlock + _lockUpPeriod) {
            if (end > _poolInfo.lastEmptyBlock + _lockUpPeriod) {
                start = _poolInfo.lastEmptyBlock + _lockUpPeriod;
            } else {
                return 0;
            }
        }
        if (start <= end) {
            if (end < nextHalveBlock) {
                totalReward = (end - start) * getCurrentReward(start);
            } else {
                while (end >= nextHalveBlock) {
                    totalReward = totalReward + (nextHalveBlock - start) * getCurrentReward(start);
                    unchecked {
                        start = nextHalveBlock;
                    }
                    nextHalveBlock = getNextRewardChangeBlock(nextHalveBlock);
                }
                totalReward = totalReward + (end - start) * getCurrentReward(end);
            }
        }
        return totalReward;
    }

    /**
        @dev check if user.queue is matured at blockNum, return total matured value
        this function is view because individual user.amountStake can only be changed when updateAccumulatedPerShare() is called and getMintableAllowance is a view function     
    */
    function _lookupLockupPeriodForUser(address account, uint256 blockNum) private view returns (uint256 pending) {
        uint32 last = _userInfo[account].queue.last;
        for (uint256 i = _userInfo[account].queue.first; i <= last; ) {
            if (blockNum > _userInfo[account].queue.data[i].blockNum) {
                pending += _userInfo[account].queue.data[i].amount;
            } else break;
            unchecked {
                ++i;
            }
        }
        return pending;
    }

    /**
        @dev check if user.queue is matured at blockNum, return total matured value
        this function is view because individual user.amountStake can only be changed when updateAccumulatedPerShare() is called and getMintableAllowance is a view function     
    */
    function _proccessLockupPeriodForUser(address account, uint256 blockNum) private returns (uint256 pending) {
        uint32 last = _userInfo[account].queue.last;
        for (uint256 i = _userInfo[account].queue.first; i <= last; ) {
            if (blockNum > _userInfo[account].queue.data[i].blockNum) {
                StakeQueue.StakeInfo memory data = StakeQueue.dequeue(_userInfo[account].queue);
                pending += data.amount;
            } else break;
            unchecked {
                ++i;
            }
        }
        return pending;
    }

    /**
        @param account - user wallet address
        @param amount - amount change from stake
        @dev - be called from GTD stake, it will do the following:
        1. Proccess user queue, this will add pending amount to user.amountStaked if lockupPeriod is ended
        2. push {amount, lockup ended block} to user.queue and pool.queue
        3. updateAccumulatedAmountPerShare()
        4. if user has already stake before and there's pending reward to mint, add the current mintableAllowance to pendingMinting
        5. store the user.debt values
     */
    function updateAccumulatedWhenStake(address account, uint256 amount) external virtual onlyGTD returns (bool) {
        require(amount > 0, 'ERC20Reward: amount must be greater than 0');
        if (_userInfo[account].queue.first == 0) {
            StakeQueue.initialize(_userInfo[account].queue);
        }

        _userInfo[account].amountStaked += _proccessLockupPeriodForUser(account, block.number);

        uint32 _blockPlusLockupPeriod = (block.number + _lockUpPeriod).toUint32();
        if (_userInfo[account].debtCount > 0) {
            require(
                _blockPlusLockupPeriod > _userInfo[account].debtBlock[_userInfo[account].debtCount - 1],
                'ERC20Reward: already stake in the same block'
            );
        }
        uint96 amountToAdd = amount.toUint96();
        StakeQueue.enqueue(_poolInfo.queue, _blockPlusLockupPeriod, amountToAdd, _userQueueToPoolQueueIndex);
        StakeQueue.enqueue(_userInfo[account].queue, _blockPlusLockupPeriod, amountToAdd, _userQueueToPoolQueueIndex);
        unchecked {
            _userQueueToPoolQueue[_userQueueToPoolQueueIndex++] = _poolInfo.queue.last;
            if (StakeQueue.isEmpty(_poolInfo.queue) && _poolInfo.totalStaked == 0) {
                _poolInfo.lastEmptyBlock = block.number;
                _poolInfo.accGatePerShare = 0;
            }
        }
        updateAccumulatedAmountPerShare();
        unchecked {
            _poolInfo.totalStakeIncludePending += amount;
            _userInfo[account].pendingMinting[_userInfo[account].debtCount] = _getFutureReward(
                account,
                _blockPlusLockupPeriod
            );
        }

        _userInfo[account].debt[_userInfo[account].debtCount] =
            (GTD.stakeOf(account) * _poolInfo.userDebtShare) /
            ACC_ADJUST;
        unchecked {
            _userInfo[account].debtBlock[_userInfo[account].debtCount] = _blockPlusLockupPeriod;
            _userInfo[account].debtCount++;
        }
        return true;
    }

    /**
        @param account - user wallet address
        @param amount - amount change from unstake
        @dev - be called from GTD stake/unstake, it will do the following:
        1. Proccess user queue, this will add pending amount to user.amountStaked if lockupPeriod is ended
        2. totalStakeIncludePending subtract the amount directly
        3. save the pendingMinting amount
        4. for-loop will run through the userInfo queue. unstake amount will subtract the pending amount from user.queue and pool.queue
        5. if there still amountToSub after for-loop, the remaining amount will subtract the totalStaked and user.amountStaked
        6. if totalStaked becomes 0 after unstake, set lastEmptyBlock to this block and set accGatePerShare, userDebtShare to 0
        7. update userDebt
     */
    function updateAccumulatedWhenUnstake(address account, uint256 amount) external virtual onlyGTD returns (bool) {
        require(amount > 0, 'ERC20Reward: amount must be greater than 0');
        _userInfo[account].amountStaked += _proccessLockupPeriodForUser(account, block.number);

        updateAccumulatedAmountPerShare();
        unchecked {
            _poolInfo.totalStakeIncludePending -= amount;
            _userInfo[account].pendingMinting[_userInfo[account].debtCount] = _getMintableAllowance(account);
        }

        uint96 amountToSub = amount.toUint96();
        uint16 tmpIndex;
        uint32 first = _userInfo[account].queue.first;
        for (uint256 i = _userInfo[account].queue.last; i >= first; ) {
            unchecked {
                blockToSub[tmpIndex++] = _userInfo[account].queue.data[i].blockNum;
            }
            if (_userInfo[account].queue.data[i].amount >= amountToSub) {
                _userInfo[account].queue.data[i].amount -= amountToSub;
                _userQueueToPoolQueue[_userQueueToPoolQueueIndex++];
                _poolInfo
                    .queue
                    .data[_userQueueToPoolQueue[_userInfo[account].queue.data[i].keyPosition]]
                    .amount -= amountToSub;
                unchecked {
                    amountToSub = 0;
                }
                break;
            } else {
                amountToSub -= _userInfo[account].queue.data[i].amount;
                unchecked {
                    _userInfo[account].queue.data[i].amount = 0;
                    _poolInfo
                        .queue
                        .data[_userQueueToPoolQueue[_userInfo[account].queue.data[i].keyPosition]]
                        .amount = 0;
                }
            }
            --i;
        }
        if (amountToSub > 0) {
            _userInfo[account].amountStaked -= amountToSub;
            _poolInfo.totalStaked -= amountToSub;
        }

        unchecked {
            if (_poolInfo.totalStakeIncludePending == 0) {
                _poolInfo.lastEmptyBlock = block.number;
                _poolInfo.accGatePerShare = 0;
                _poolInfo.userDebtShare = 0;
            }
        }

        if (_userInfo[account].amountStaked == 0 && GTD.stakeOf(account) > 0) {
            _userInfo[account].debt[_userInfo[account].debtCount - 1] =
                (GTD.stakeOf(account) * _poolInfo.userDebtShare) / ACC_ADJUST;
            unchecked {
                _userInfo[account].debtBlock[_userInfo[account].debtCount - 1] = block.number - 1;
            }
        } else {
            _userInfo[account].debt[_userInfo[account].debtCount] =
                (_userInfo[account].amountStaked * _poolInfo.accGatePerShare) / ACC_ADJUST;
            unchecked {
                _userInfo[account].debtBlock[_userInfo[account].debtCount] = block.number - 1;
                _userInfo[account].debtCount++;
            }
        }
        return true;
    }

    /**
        @dev can be called anytime by anyone.
        This function will 
        1. check _poolInfo.queue array see if lockupPeriod matured then add into totalStaked value
        2. calculates the accGatePerShare value base on the latest totalStaked value
        3. update _poolInfo.lastUpdatedBlock value
    */
    function updateAccumulatedAmountPerShare() public virtual {
        if (_poolInfo.lastUpdatedBlock > 0 && _poolInfo.lastUpdatedBlock < block.number) {
            (_poolInfo.userDebtShare, , ) = _getFutureAcc(block.number + _lockUpPeriod);

            while (
                !StakeQueue.isEmpty(_poolInfo.queue) &&
                block.number > _poolInfo.queue.data[_poolInfo.queue.first].blockNum
            ) {
                if (_poolInfo.totalStaked > 0) {
                    _poolInfo.accGatePerShare =
                        _poolInfo.accGatePerShare +
                        (_getRangeReward(
                            _poolInfo.lastUpdatedBlock,
                            _poolInfo.queue.data[_poolInfo.queue.first].blockNum
                        ) * ACC_ADJUST) /
                        _poolInfo.totalStaked;
                }
                unchecked {
                    _poolInfo.lastUpdatedBlock = _poolInfo.queue.data[_poolInfo.queue.first].blockNum;
                    _poolInfo.totalStaked += _poolInfo.queue.data[_poolInfo.queue.first].amount;
                }
                StakeQueue.dequeue(_poolInfo.queue);
            }
            _poolInfo.accGatePerShare = _poolInfo.totalStaked > 0
                ? _poolInfo.accGatePerShare +
                    (_getRangeReward(_poolInfo.lastUpdatedBlock, block.number) * ACC_ADJUST) /
                    _poolInfo.totalStaked
                : 0;
        }
        unchecked {
            _poolInfo.lastUpdatedBlock = block.number;
        }
    }

    uint256[50] private __gap;
}
