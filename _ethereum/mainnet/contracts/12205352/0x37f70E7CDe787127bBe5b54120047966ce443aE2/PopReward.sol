// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.6;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./EnumerableSet.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./PopToken.sol";
import "./IRewardManager.sol";

// stolen from Sushiswap MasterChef: https://github.com/sushiswap/sushiswap/blob/master/contracts/MasterChef.sol
contract PopReward is Ownable, IRewardManager {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt
    }

    // Info of each pool.
    struct PoolInfo {
        uint256 allocPoint; // How many allocation points assigned to this pool. POPs to distribute per block.
        uint256 lastRewardBlock; // Last block number that POPs distribution occurs.
        uint256 accPopPerShare; // Accumulated POPs per share, times 1e12. See below.
        uint256 lpSupply; // Total amount of lp token staked
    }

    PopToken private immutable pop;
    // Block number when bonus POP period ends.
    uint256 public bonusEndBlock;
    // POP tokens created per block.
    uint256 public popPerBlock;
    // Bonus multiplier for early pop makers.
    uint256 public constant BONUS_MULTIPLIER = 10;
    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when POP mining starts.
    uint256 public startBlock;
    // authorized MLPs
    mapping(address => uint256) public pidByAddress;
    address popMarketplace;
    mapping(address => bool) public authorizedMlp;

    PoolInfo public popVault;
    mapping(address => UserInfo) public popStaker;

    event PopDeposit(address indexed user, uint256 amount);
    event PopWithdraw(address indexed user, uint256 amount);

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event RewardPaid(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(
        PopToken _pop,
        uint256 _popPerBlock,
        uint256 _startBlock,
        uint256 _bonusEndBlock,
        uint256 _popAllocPoint,
        uint256 _popVaultStarts
    ) public {
        pop = _pop;
        popPerBlock = _popPerBlock;
        bonusEndBlock = _bonusEndBlock;
        startBlock = _startBlock;
        popVault = PoolInfo({
            allocPoint: _popAllocPoint,
            lastRewardBlock: _popVaultStarts,
            accPopPerShare: 0,
            lpSupply: 0
        });
        totalAllocPoint = _popAllocPoint;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function getPoolSupply(address pool)
        public
        view
        override
        returns (uint256)
    {
        return poolInfo[pidByAddress[pool]].lpSupply;
    }

    function getUserAmount(address pool, address user)
        public
        view
        override
        returns (uint256)
    {
        return userInfo[pidByAddress[pool]][user].amount;
    }

    function setPopMarketplace(address _newMarketplace) public onlyOwner {
        require(_newMarketplace != address(0), "Address can not be 0");
        popMarketplace = _newMarketplace;
    }

    // Add a new pool. Can only be called by the PopMarketplace.
    function add(uint256 _allocPoint, address _newMlp) public override {
        require(
            msg.sender == popMarketplace,
            "only the marketplace can add a pool"
        );
        uint256 lastRewardBlock =
            block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(
            PoolInfo({
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accPopPerShare: 0,
                lpSupply: 0
            })
        );
        pidByAddress[_newMlp] = poolInfo.length - 1;
        authorizedMlp[_newMlp] = true;
    }

    // Update the given pool's POP allocation point. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) public onlyOwner {
        PoolInfo storage pool = poolInfo[_pid];
        _set(pool, _allocPoint, _withUpdate);
    }

    function _set(
        PoolInfo storage pool,
        uint256 _allocPoint,
        bool _withUpdate
    ) private {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(pool.allocPoint).add(_allocPoint);
        pool.allocPoint = _allocPoint;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to)
        public
        view
        returns (uint256)
    {
        if (_to <= bonusEndBlock) {
            return _to.sub(_from).mul(BONUS_MULTIPLIER);
        } else if (_from >= bonusEndBlock) {
            return _to.sub(_from);
        } else {
            return
                bonusEndBlock.sub(_from).mul(BONUS_MULTIPLIER).add(
                    _to.sub(bonusEndBlock)
                );
        }
    }

    // View function to see pending POPs on frontend.
    function pendingPop(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        return _pendingPop(pool, user);
    }

    function _pendingPop(PoolInfo storage pool, UserInfo storage user)
        private
        view
        returns (uint256)
    {
        uint256 accPopPerShare = pool.accPopPerShare;
        uint256 lpSupply = pool.lpSupply;
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier =
                getMultiplier(pool.lastRewardBlock, block.number);
            uint256 popReward =
                multiplier.mul(popPerBlock).mul(pool.allocPoint).div(
                    totalAllocPoint
                );
            accPopPerShare = accPopPerShare.add(
                popReward.mul(1e12).div(lpSupply)
            );
        }
        return user.amount.mul(accPopPerShare).div(1e12).sub(user.rewardDebt);
    }

    function vaultPendingPop(address _account) external view returns (uint256) {
        UserInfo storage user = popStaker[_account];
        return _pendingPop(popVault, user);
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
        return _updatePool(pool);
    }

    function _updatePool(PoolInfo storage pool) private {
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpSupply;
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 popReward =
            multiplier.mul(popPerBlock).mul(pool.allocPoint).div(
                totalAllocPoint
            );
        pop.mintTo(address(this), popReward);
        pool.accPopPerShare = pool.accPopPerShare.add(
            popReward.mul(1e12).div(lpSupply)
        );
        pool.lastRewardBlock = block.number;
    }

    // Notify the amount of LP tokens staked in the PopVault.
    function notifyDeposit(address _account, uint256 _amount) public override {
        require(authorizedMlp[msg.sender], "unauthorized sender");
        uint256 _pid = pidByAddress[msg.sender];
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_account];
        updatePool(_pid);
        _notifyDeposit(_account, pool, user, _amount);
        emit Deposit(_account, _pid, _amount);
    }

    function _notifyDeposit(
        address _account,
        PoolInfo storage pool,
        UserInfo storage user,
        uint256 _amount
    ) private {
        if (user.amount > 0) {
            uint256 pending =
                user.amount.mul(pool.accPopPerShare).div(1e12).sub(
                    user.rewardDebt
                );
            safePopTransfer(_account, pending);
        }
        pool.lpSupply = pool.lpSupply.add(_amount);
        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(pool.accPopPerShare).div(1e12);
    }

    // Notify the amount of LP token withdrawn from the PopVault.
    function notifyWithdraw(address _account, uint256 _amount) public override {
        require(authorizedMlp[msg.sender], "unauthorized sender");
        uint256 _pid = pidByAddress[msg.sender];
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_account];
        updatePool(_pid);
        _notifyWithdraw(_account, pool, user, _amount, _pid);
        emit Withdraw(_account, _pid, _amount);
    }

    function _notifyWithdraw(
        address _account,
        PoolInfo storage pool,
        UserInfo storage user,
        uint256 _amount,
        uint256 _pid
    ) private {
        require(user.amount >= _amount, "withdraw: not good");
        uint256 pending =
            user.amount.mul(pool.accPopPerShare).div(1e12).sub(user.rewardDebt);
        safePopTransfer(_account, pending);
        user.amount = user.amount.sub(_amount);
        user.rewardDebt = user.amount.mul(pool.accPopPerShare).div(1e12);
        pool.lpSupply = pool.lpSupply.sub(_amount);
        emit RewardPaid(_account, _pid, pending);
    }

    // Safe pop transfer function, just in case if rounding error causes pool to not have enough POPs.
    function safePopTransfer(address _to, uint256 _amount) internal {
        uint256 popBal = pop.balanceOf(address(this)).sub(popVault.lpSupply);
        if (_amount > popBal) {
            pop.transfer(_to, popBal);
        } else {
            pop.transfer(_to, _amount);
        }
    }

    function stakePop(uint256 _amount) public {
        UserInfo storage user = popStaker[msg.sender];
        updatePopVault();
        _notifyDeposit(msg.sender, popVault, user, _amount);
        require(pop.transferFrom(msg.sender, address(this), _amount),"transfer failed");
        emit PopDeposit(msg.sender, _amount);
    }

    function withdrawPop(uint256 _amount) public {
        UserInfo storage user = popStaker[msg.sender];
        updatePopVault();
        _notifyWithdraw(msg.sender, popVault, user, _amount,0);
        require(pop.transfer(msg.sender, _amount),"transfer failed");
        emit PopWithdraw(msg.sender, _amount);
    }

    function updatePopVault() public {
        _updatePool(popVault);
    }

    function setPopVault(uint256 _allocPoint) public onlyOwner {
        _set(popVault, _allocPoint, false);
    }

    function setPopVaultStartBlock(uint256 _startBlock) external onlyOwner {
        popVault.lastRewardBlock = _startBlock;
    }

    function claimRewards(uint256 _poolId) external {
        updatePool(_poolId);
        _harvest(_poolId);
    }

    function _harvest(uint256 _poolId) internal {
        PoolInfo storage pool = poolInfo[_poolId];
        UserInfo storage user = userInfo[_poolId][msg.sender];
        if (user.amount == 0) return;
        uint256 pending =
            user.amount.mul(pool.accPopPerShare).div(1e12).sub(user.rewardDebt);
        if (pending > 0) {
            user.rewardDebt = user.amount.mul(pool.accPopPerShare).div(1e12);
            // Pay out the pending rewards
            safePopTransfer(msg.sender, pending);
            emit RewardPaid(msg.sender, _poolId, pending);
            return;
        }
        user.rewardDebt = user.amount.mul(pool.accPopPerShare).div(1e12);
    }
}
