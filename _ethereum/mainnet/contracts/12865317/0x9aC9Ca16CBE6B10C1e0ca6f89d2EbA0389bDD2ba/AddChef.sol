// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./SafeERC20.sol";
import "./EnumerableSet.sol";
import "./SafeMath.sol";
import "./Ownable.sol";


contract AddChef is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
    }


    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 addPerBlock;
        uint256 lastRewardBlock; // Last block number that ADDs distribution occurs.
        uint256 accAddPerShare; // Accumulated ADD per share, times 1e12. See below.
        bool isStopped; // represent either pool is farming or not
        uint256 fromBlock; // fromBlock represent block number from which reward is going to be governed
        uint256 toBlock; // toBlock represent block number from which will staking will end
        uint256[]  epochMultiplersValue;
        uint256[]  epochMultiplers;
    }

    // The ADD TOKEN!
    IERC20 public addToken;

    // ADD tokens created per block.
    // uint256 public addPerBlock;

    // Info of each pool.
    PoolInfo[] public poolInfo;



    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.

    // Reward Multiplier for each of three pools

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(IERC20 _addToken) public {
        addToken = _addToken;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function poolBlocksLength(uint256 _pid) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        return pool.epochMultiplers.length;
    }

    function poolMultiplierLength(uint256 _pid) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        return pool.epochMultiplersValue.length;
    }

    function poolBlocksValue(uint256 _pid, uint256 index) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        return pool.epochMultiplers[index];
    }

    function poolMultiplierValue(uint256 _pid, uint256 index) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        return pool.epochMultiplersValue[index];
    }

    function setAddPerBlock(uint256 _pid, uint256 _addPerBlock) public onlyOwner {
        massUpdatePools();
        PoolInfo storage pool = poolInfo[_pid];
        pool.addPerBlock = _addPerBlock;
    }

    function stopPool(uint256 _pid) public onlyOwner{
        PoolInfo storage pool = poolInfo[_pid];
        pool.isStopped = true;
    }

    function restartPool(uint256 _pid) public onlyOwner{
        massUpdatePools();
        PoolInfo storage pool = poolInfo[_pid];
        pool.isStopped = false;
    }

    function addBlockAndMultiplier(uint256 _pid, uint256 _toBlock, uint256 _actualMultiplier) public onlyOwner{
        PoolInfo storage pool = poolInfo[_pid];
        pool.epochMultiplers.push(_toBlock);
        pool.epochMultiplersValue.push(_actualMultiplier);
    }

    function setFromBlock(uint256 _pid, uint256 _fromBlock) public onlyOwner{
        PoolInfo storage pool = poolInfo[_pid];
        pool.fromBlock = _fromBlock;
    }

    function setToBlock(uint256 _pid, uint256 _toBlock) public onlyOwner{
        PoolInfo storage pool = poolInfo[_pid];
        pool.toBlock = _toBlock;
    }


    function add(
        IERC20 _lpToken,
        uint256 _addPerBlock,
        uint256 _fromBlock,
        uint256[] memory _epochMultiplers,
        uint256[] memory _epochMultiplersValue,
        uint256 _toBlock
    ) public onlyOwner {
        require(address(_lpToken) != address(0), "MC: _lpToken should not be address zero");

        uint256 lastRewardBlock = block.number > _fromBlock ? block.number : _fromBlock;

        PoolInfo memory currentPool;

        currentPool.lpToken = _lpToken;
        currentPool.addPerBlock = _addPerBlock;
        currentPool.fromBlock = _fromBlock;
        currentPool.toBlock = _toBlock;
        currentPool.accAddPerShare = 0;
        currentPool.lastRewardBlock = lastRewardBlock;
        currentPool.isStopped = false;
        currentPool.epochMultiplers = _epochMultiplers;
        currentPool.epochMultiplersValue = _epochMultiplersValue;

        poolInfo.push(currentPool);

    }

    function updateMultiplierBlock(
         uint256 _pid,
         uint8 index,
        uint256 _toBlock
    ) public onlyOwner {
        PoolInfo storage pool = poolInfo[_pid];
        pool.epochMultiplers[index] = _toBlock;
    }

    function updateMultiplierValue(
         uint256 _pid,
         uint8 index,
        uint256 value
    ) public onlyOwner {
        PoolInfo storage pool = poolInfo[_pid];
        pool.epochMultiplersValue[index] = value;
    }


    function getMultiplier(
        uint256 _pid,
        uint256 _from,
        uint256 _to
    ) public view returns (uint256) {
/**
        if farming ends but pools still have blocks to farm tokens,
        we will allow pools to farm token until each pool tokens farmed
        Example
        
        Lets say Staking started at block 1 and will ends at block 200,000 and we have two Pools

        1st Pool Multiplier will run from block 1 to 200,000 with value 10x
        2nd Pool Multiplier will run from block 1 to 200,000 with value 30x

        After few days, the state of pools is as follows

        1 Pool Users have farmed tokens until block 150,000
        2 Pool Users have farmed tokens until block 175,000

        No body entere into pool from a long time and now the block over blockchain is 210,000
        but the blocks pool 1 and 2 have not processed completely

        so we will allow both pool users to farm tokens until faming end as per block 200,000
        however only one user can proceed with transaction as the last tranaction will fill up the pools

         */
        PoolInfo storage pool = poolInfo[_pid];

        // uint256 to = _to > pool.toBlock ? pool.toBlock : _to;


        uint256 poolMultiplierLength = poolInfo[_pid].epochMultiplers.length;

        uint256 sumOfMultiplier = 0;


        if ( _from >= pool.epochMultiplers[poolMultiplierLength-1]){
            return _to.sub(_from);
        }

        for (uint256 index = 0; index < poolMultiplierLength; index++) {
           
             if(pool.epochMultiplers[index] > _to){
                sumOfMultiplier = sumOfMultiplier.add(_to.sub(_from).mul(pool.epochMultiplersValue[index]));
                break;
            }
            else if ( _from < pool.epochMultiplers[index] && _to >= pool.epochMultiplers[index]){
              sumOfMultiplier = sumOfMultiplier.add(pool.epochMultiplers[index].sub(_from).mul(pool.epochMultiplersValue[index]));
              _from = pool.epochMultiplers[index];
            }
        }
        if ( _to > pool.epochMultiplers[poolMultiplierLength-1]){
              sumOfMultiplier = sumOfMultiplier.add(_to.sub(_from));
        }
        return sumOfMultiplier;
    }

    // View function to see pending ADDs on frontend.
    function pendingAdds(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accAddPerShare = pool.accAddPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(_pid, pool.lastRewardBlock, block.number);
            uint256 addReward = multiplier.mul(pool.addPerBlock);
            accAddPerShare = accAddPerShare.add(addReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accAddPerShare).div(1e12).sub(user.rewardDebt);
    }

    // Deposit LP tokens to YaxisChef for YAX allocation.
    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(pool.isStopped == false, "MC: Staking Ended, Please withdraw your tokens");
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accAddPerShare).div(1e12).sub(user.rewardDebt);
            if (pending > 0) {
                safeAddTransfer(msg.sender, pending);
            }
        }
        if (_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accAddPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from YaxisChef.
    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accAddPerShare).div(1e12).sub(user.rewardDebt);
        if (pending > 0) {
            safeAddTransfer(msg.sender, pending);
        }
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accAddPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock || pool.isStopped) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(_pid, pool.lastRewardBlock, block.number);

        uint256 addReward = multiplier.mul(pool.addPerBlock);
        // minting is not required as we already have coins in contract
        pool.accAddPerShare = pool.accAddPerShare.add(addReward.mul(1e12).div(lpSupply));
        if (block.number >= pool.toBlock) {
            pool.isStopped = true;
        }

        pool.lastRewardBlock = block.number;
    }

    // Safe add transfer function, just in case if rounding error causes pool to not have enough YAXs.
    function safeAddTransfer(address _to, uint256 _amount) internal {
        uint256 addBal = addToken.balanceOf(address(this));
        if (_amount > addBal) {
            addToken.transfer(_to, addBal);
        } else {
            addToken.transfer(_to, _amount);
        }
    }
}
