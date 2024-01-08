// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ProxyAdmin.sol";
import "./TransparentUpgradeableProxy.sol";

import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./Initializable.sol";
import "./PausableUpgradeable.sol";
import "./IFarming.sol";

// Derived from Sushi Farming contract

contract Farming is Initializable, AccessControlUpgradeable, PausableUpgradeable {
    /**
        As mathematical model, farming contract can be described by parametrs with dimentions:
        1)lpToken
        2)rewardToken
        3)block
        4)allocationPoint
        5)timestamp

        Annotation "[param]" means the dimention of param.
        For example: [UserInfo.amount] = lptoken

        param `accTokenPerShare` increase every time when function updatePool() is called.
        The updatePool is called by functions deposit(),depositTo(),withdraw(),claimReward(),exit().
        `accTokenPerShare` increases every block by this formula:
        accTokenPerShare = (multiplier * tokensFarmedPerBlock * pool.allocPoint / totalAllocPoint) * 10**12 / pool.totalDeposited
        where `multiplier` is difference  current block `block.number` and block, where reward was occured (this block also calls lastBlockReward),
              `tokensFarmedPerBlock` the amount of tokens that distributes in each block,
              `pool.allocPoint` the amount of the part of pool where reward tokens are distributed
              `totalAllocPoint` the sum of all allocation points
              `pool.totalDeposited` is all lpTokens that are staked in the pool
        [accTokenPerShare]=([multiplier] * [tokensFarmedPerBlock] * [pool.allocPoint] / [totalAllocPoint]) * [10**12] / [pool.totalDeposited]=
        =(block * rewardToken/block * allocationPoint / allocationPoint) * 1 /  lpToken = rewardToken/lpToken
        So, [accTokenPerShare]=rewardToken/lpToken

        param `rewardDept` is user to determine how much the user was farmed when he last time called the 
        deposit(),depositTo(),withdraw(),claimReward(),exit()
        `rewardDept` is needed because the pure (user.amount * accTokenPerShare) shows the reward from `startBlock` to `block.number`
        and if we use (user.amount * accTokenPerShare - rewardDept), we got the reward from block, where user called 
        functions that change the user.amount or claims reward, to `block.number`.
        user.pendingReward = user.pendingReward + user.amount * pool.accTokenPerShare / 1e12 - user.rewardDebt
        [user.pendingReward] = [user.pendingReward] + [user.amount] * [pool.accTokenPerShare] / [1e12] - [user.rewardDebt]=
        = rewardToken + lpToken * rewardToken/lpToken / 1 - rewardToken = rewardToken + rewardToken - rewardToken = rewardToken
        So, [user.pendingReward] = rewardToken

        The dimension `timestamp` has parametr `noRewardClaimsUntil`.

     */



    using SafeERC20Upgradeable for IERC20Upgradeable;

    //ACL
    //Manager is the person allowed to manage pools
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    // Info of each user.
    struct UserInfo {
        uint256 amount;         // How many LP tokens the user has provided. [amount]=lpToken
        uint256 pendingReward;  // how many tokens user was rewarded with, pending to withdraw. [pendingReward]=rewardToken
        uint256 totalRewarded;  // total amount of tokens rewarded to user [totalRewarded]=rewardToken
        uint256 rewardDebt;     // Reward debt. See explanation below. [rewardDebt]=rewardToken
        //
        // We do some fancy math here. Basically, any point in time, the amount of Tokens
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accTokenPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accTokenPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20Upgradeable lpToken;  // Address of LP token contract. 
        uint64 allocPoint;          // How many allocation points assigned to this pool. Tokens to distribute per block.[allocPoint] = allocationPoint
        uint64 startBlock;          // farming start block. [startBlock]=block
        uint64 endBlock;            // farming endBlock. [endBlock]=block
        uint64 lastRewardBlock;     // Last block number that Tokens distribution occurs. [lastRewardBlock]=block
        uint256 accTokenPerShare;   // Accumulated Tokens per share, times 1e12. See below. [accTokenPerShare]=rewardToken/lpToken
        uint256 totalDeposited;     //total tokens deposited in address of a pool. [totalDeposited]=lpToken
    }

    // The Token TOKEN
    IERC20Upgradeable public rewardToken;
    // Token tokens created per block.
    uint256 public tokensFarmedPerBlock; //[tokensFarmedPerBlock]=rewardToken/block
    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping (uint16 => mapping (address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0; //[totalAllocPoint]=allocationPoint
    // timestamp until claiming rewards are disabled;
    uint64 public noRewardClaimsUntil; //[noRewardClaimsUntil]=timestamp

    event PoolAdded(uint256 indexed pid);
    event Deposit(address indexed user, uint256 indexed pid, uint256 amountLiquidity);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amountLiquidity);
    event RewardClaimed(address indexed user, uint256 indexed pid, uint256 amountRewarded);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amountLiquidity);

    function initialize(
        address _admin,
        address _rewardToken,
        uint256 _tokensPerBlock,
        uint64 _noRewardClaimsUntil
    ) public initializer {
        __AccessControl_init();
        __Pausable_init_unchained();

        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        _setupRole(MANAGER_ROLE, _admin);

        rewardToken = IERC20Upgradeable(_rewardToken);
        tokensFarmedPerBlock = _tokensPerBlock;
        require (_noRewardClaimsUntil > block.timestamp, "Incorrect _noRewardClaimsUntil");
        noRewardClaimsUntil = _noRewardClaimsUntil;
    }

    function version() public pure returns (uint32){
        //version in format aaa.bbb.ccc => aaa*1E6+bbb*1E3+ccc;
        return uint32(1001000);
    }

    /**
    * @dev Throws if called by any account other than the one with the Manager role granted.
    */
    modifier onlyManager() {
        require(hasRole(MANAGER_ROLE, msg.sender), "Caller is not the Manager");
        _;
    }

    /**
    * @dev Throws if called by any account other than the one with the Admin role granted.
    */
    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not the Admin");
        _;
    }

    //************* MANAGER FUNCTIONS ********************************

    function setTokenPerBlock(uint256 _tokensFarmedPerBlock) public onlyManager {
        tokensFarmedPerBlock = _tokensFarmedPerBlock;
        massUpdatePools();
    }

    function setNoRewardClaimsUntil(uint64 _noRewardClaimsUntil) public onlyManager {
        require (_noRewardClaimsUntil > block.timestamp, "Incorrect _noRewardClaimsUntil");
        noRewardClaimsUntil = _noRewardClaimsUntil;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function addPool(uint64 _allocPoint, address _lpTokenAddress, uint64 _startBlock, uint64 _endBlock, bool _withUpdate) public onlyManager {
        require (block.number < _endBlock, "Incorrect endblock number");
        IERC20Upgradeable _lpToken = IERC20Upgradeable(_lpTokenAddress);
        if (_withUpdate) {
            massUpdatePools();
        }
        uint64 lastRewardBlock = block.number > _startBlock ? uint64(block.number) : _startBlock;
        totalAllocPoint += _allocPoint;
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            startBlock: _startBlock,
            endBlock: _endBlock,
            lastRewardBlock: lastRewardBlock,
            accTokenPerShare: 0,
            totalDeposited: 0
        }));

        emit PoolAdded(poolInfo.length-1);
    }

    // Update the given pool's Token allocation point. Can only be called by the owner.
    function updatePoolData(uint16 _pid, uint64 _allocPoint, uint64 _startBlock, uint64 _endBlock, bool _withUpdate) public onlyManager {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint - poolInfo[_pid].allocPoint + _allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
        if(_startBlock > 0){
            poolInfo[_pid].startBlock = _startBlock;
        }
        if(_endBlock > 0){
            require (block.number < _endBlock, "Incorrect endblock number");
            poolInfo[_pid].endBlock = _endBlock;
        }
        if(_withUpdate){

        }
    }

    //************* ADMIN FUNCTIONS ********************************

    function withdrawRewardTokens(address _to, uint256 _amount) public onlyAdmin {
        rewardToken.safeTransfer(_to, _amount);
    }

    function pause() onlyAdmin public {
        super._pause();
    }
   
    function unpause() onlyAdmin public {
        super._unpause();
    }

    //************* PUBLIC FUNCTIONS ********************************

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public whenNotPaused {
        _massUpdatePools();
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public whenNotPaused {
        _updatePool(_pid);
    }

    // Deposit LP tokens to PureFiFarming for Token allocation.
    function deposit(uint16 _pid, uint256 _amount) public whenNotPaused {
        depositTo(_pid, _amount, msg.sender);
    }

    // Deposit LP tokens to PureFiFarming for Token allocation.
    function depositTo(uint16 _pid, uint256 _amount, address _beneficiary) public whenNotPaused {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_beneficiary];
        updatePool(_pid);
        if (user.amount > 0) {
            user.pendingReward += user.amount * pool.accTokenPerShare / 1e12 - user.rewardDebt;
        }
        if(_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amount += _amount;
            pool.totalDeposited += _amount;
        }
        user.rewardDebt = user.amount * pool.accTokenPerShare / 1e12;
        emit Deposit(_beneficiary, _pid, _amount);
    }

    // Withdraw LP tokens from PureFiFarming.
    function withdraw(uint16 _pid, uint256 _amount) public whenNotPaused {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        user.pendingReward += user.amount * pool.accTokenPerShare / 1e12 - user.rewardDebt;
        if(_amount > 0) {
            user.amount -= _amount;
            pool.totalDeposited -= _amount;
            pool.lpToken.safeTransfer(msg.sender, _amount);
            emit Withdraw(msg.sender, _pid, _amount);
        }
        user.rewardDebt = user.amount * pool.accTokenPerShare / 1e12;   
    }

    // Claim rewarded tokens from PureFiFarming.
    function claimReward(uint16 _pid) public whenNotPaused {
        require(block.timestamp >= noRewardClaimsUntil, "Claiming reward is not available yet");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        user.pendingReward += user.amount * pool.accTokenPerShare / 1e12 - user.rewardDebt;
        user.rewardDebt = user.amount * pool.accTokenPerShare / 1e12;
        if(user.pendingReward > 0){
            user.totalRewarded += user.pendingReward;
            uint256 pending = user.pendingReward;
            user.pendingReward = 0;
            _safeTokenTransfer(msg.sender, pending);
            emit RewardClaimed(msg.sender, _pid, pending);
        }     
    }

    // withdraw all liquidity and claim all pending reward
    function exit(uint16 _pid) public whenNotPaused {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        user.pendingReward += user.amount * pool.accTokenPerShare / 1e12 - user.rewardDebt;
        if(user.amount > 0) {
            uint256 amountLiquidity = user.amount;
            pool.totalDeposited -= amountLiquidity;
            user.amount = 0;
            pool.lpToken.safeTransfer(msg.sender, amountLiquidity);
            emit Withdraw(msg.sender, _pid, amountLiquidity);
        }
        if(user.pendingReward > 0){
            require(block.timestamp >= noRewardClaimsUntil, "Claiming reward is not available yet");
            user.totalRewarded += user.pendingReward;
            uint256 pending = user.pendingReward;
            user.pendingReward = 0;
            _safeTokenTransfer(msg.sender,pending);
            emit RewardClaimed(msg.sender, _pid, pending);
        }    
        user.rewardDebt = 0;   
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint16 _pid) public whenNotPaused {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        pool.totalDeposited -= amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.lpToken.safeTransfer(address(msg.sender), amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    function claimAndStake(uint16 _pid) public {
        require(address(rewardToken) == address(poolInfo[_pid].lpToken), "Not allowed to this pool");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        user.pendingReward += user.amount * pool.accTokenPerShare / 1e12 - user.rewardDebt;
        if(user.pendingReward > 0) {
            user.totalRewarded += user.pendingReward;
            user.amount += user.pendingReward;
            user.pendingReward = 0;
            user.rewardDebt = user.amount * pool.accTokenPerShare / 1e12;
        }
        
    }

    //************* VIEW FUNCTIONS ********************************

    function getContractData() external view returns (uint256, uint256, uint64){
        return (tokensFarmedPerBlock, totalAllocPoint, noRewardClaimsUntil);
    }

    function getPoolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function getPool(uint16 _index) external view returns (address, uint256, uint64, uint64, uint64, uint256, uint256) {
        require (_index < poolInfo.length, "index incorrect");
        PoolInfo memory pool = poolInfo[_index];
        return (address(pool.lpToken), pool.allocPoint, pool.startBlock, pool.endBlock, pool.lastRewardBlock, pool.accTokenPerShare, pool.totalDeposited);
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _pid, uint256 _from, uint256 _to) public view returns (uint256) {
        require (_from <= _to, "incorrect from/to sequence");
        if (poolInfo[_pid].startBlock == 0 || _to <= poolInfo[_pid].startBlock || _from >= poolInfo[_pid].endBlock) {
            return 0;
        }

        uint256 lastBlock = _to <= poolInfo[_pid].endBlock ? _to : poolInfo[_pid].endBlock;
        uint256 firstBlock = _from >= poolInfo[_pid].startBlock ? _from : poolInfo[_pid].startBlock;
        return lastBlock - firstBlock;
    }

    // View function to see pending Tokens on frontend.
    function getUserInfo(uint16 _pid, address _user) external view returns (uint256, uint256, uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accTokenPerShare = pool.accTokenPerShare;
        if (block.number > pool.lastRewardBlock && pool.totalDeposited != 0) {
            uint256 multiplier = getMultiplier(_pid, pool.lastRewardBlock, block.number);
            uint256 amountRewardedPerPool = totalAllocPoint > 0 ? (multiplier * tokensFarmedPerBlock * pool.allocPoint / totalAllocPoint) : 0;
            accTokenPerShare += amountRewardedPerPool * 1e12 / pool.totalDeposited;
        }
        return (user.amount, user.totalRewarded, user.pendingReward + user.amount * accTokenPerShare / 1e12 - user.rewardDebt);
    }

    //************* INTERNAL FUNCTIONS ********************************

    // Safe rewardToken transfer function, just in case if rounding error causes pool to not have enough Tokens.
    function _safeTokenTransfer(address _to, uint256 _amount) internal {
        uint256 tokenBal = rewardToken.balanceOf(address(this));
        if (_amount > tokenBal) {
            rewardToken.transfer(_to, tokenBal);
        } else {
            rewardToken.transfer(_to, _amount);
        }
    }

    function _massUpdatePools() internal {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            _updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function _updatePool(uint256 _pid) internal {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        if (pool.totalDeposited == 0) {
            pool.lastRewardBlock = uint64(block.number);
            return;
        }
        uint256 multiplier = getMultiplier(_pid, pool.lastRewardBlock, block.number);
        uint256 amountRewardedPerPool = totalAllocPoint > 0 ? (multiplier * tokensFarmedPerBlock * pool.allocPoint / totalAllocPoint) : 0;
        pool.accTokenPerShare += amountRewardedPerPool * 1e12 / pool.totalDeposited;
        pool.lastRewardBlock = uint64(block.number);
    }
}