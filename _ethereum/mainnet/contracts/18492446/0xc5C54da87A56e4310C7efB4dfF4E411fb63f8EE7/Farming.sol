// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./IFarming.sol";

contract Farming is Ownable, IFarming {
  using SafeERC20 for IERC20;

  // Info of each user.
  struct UserInfo {
    uint256 amount;     // How many LP tokens the user has provided.
    uint256 rewardDebt; // Reward debt. See explanation below.
    //
    // We do some fancy math here. Basically, any point in time, the amount of ERC20s
    // entitled to a user but is pending to be distributed is:
    //
    //   pending reward = (user.amount * pool.accERC20PerShare) - user.rewardDebt
    //
    // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
    //   1. The pool's `accERC20PerShare` (and `lastRewardBlock`) gets updated.
    //   2. User receives the pending reward sent to his/her address.
    //   3. User's `amount` gets updated.
    //   4. User's `rewardDebt` gets updated.
  }

  // Info of each pool.
  struct PoolInfo {
    IERC20 lpToken;             // Address of LP token contract.
    uint256 allocPoint;         // How many allocation points assigned to this pool. ERC20s to distribute per block.
    uint256 lastRewardBlock;    // Last block number that ERC20s distribution occurs.
    uint256 accERC20PerShare;   // Accumulated ERC20s per share, times 1e36.
  }

  // Minimum number of blocks that needs to pass, from the deploy, in order to start distributing rewards
  // uint constant MINIMUM_BLOCKS_BEFORE_DISTRIBUTION = 216_000; // 30 days divided by 12 seconds (average Ethereum block time)
  uint constant MINIMUM_BLOCKS_BEFORE_DISTRIBUTION = 0; // Removed due to time constraints

  // Maximum number of blocks that needs to pass, from the deploy, in order to start distributing rewards
  uint constant MAXIMUM_BLOCKS_BEFORE_DISTRIBUTION = 1_296_000; // 180 days divided by 12 seconds (average Ethereum block time)

  // Address of the ERC20 Token contract.
  IERC20 public erc20;
  // The total amount of ERC20 that's paid out as reward.
  uint256 public paidOut;
  // ERC20 tokens rewarded per block.
  uint256 public rewardPerBlock;

  // Info of each pool.
  PoolInfo[] public poolInfo;
  // Info of each user that stakes LP tokens.
  mapping (uint256 => mapping (address => UserInfo)) public userInfo;
  // Total allocation points. Must be the sum of all allocation points in all pools.
  uint256 public totalAllocPoint;

  // The block number when farming starts.
  uint256 public startBlock;
  // The block number when farming ends.
  uint256 public endBlock;

  /**
    * @notice Constructor
    * @param _erc20 Address of the reward token
    * @param _rewardPerBlock Distributed rewards per block
    * @param _startBlock Block number from which users can farm
    */
  constructor(
    IERC20 _erc20, 
    uint256 _rewardPerBlock, 
    uint256 _startBlock
  ) {
    require(_startBlock >= block.number + MINIMUM_BLOCKS_BEFORE_DISTRIBUTION && 
      _startBlock <= block.number + MAXIMUM_BLOCKS_BEFORE_DISTRIBUTION, "constructor: invalid start block");

    erc20 = _erc20;
    rewardPerBlock = _rewardPerBlock;
    startBlock = _startBlock;
    endBlock = _startBlock;
  }

  /**
    * @notice Returns the number of farming pools
    * @return pools Number of farming pools
    */
  function poolLength() external view returns (uint256) {
    return poolInfo.length;
  }

  /**
    * @notice Fund the farming and extends the end block
    * @param _amount Amount of token to fund
    * @dev Caller must approve the transfer of token from its wallet
          to this contract before calling this function
    */
  function fund(
    uint256 _amount
  ) public {
    require(block.number < endBlock, "fund: too late, the farm is closed");
    require(_amount % rewardPerBlock == 0, "fund: invalid amount");

    erc20.safeTransferFrom(address(msg.sender), address(this), _amount);
    endBlock += _amount / rewardPerBlock;
  }

  /**
    * @notice Create a farming pool
    * @param _allocPoint Allocation points of the pool. This pool will receive
              _allocPoint / totalAllocPoint of the reward per block
    * @param _lpToken Address of the LP token
    * @param _withUpdate If true, updates other farmimg pools
    * @dev Owner should withdraw before endBlock in order to not lose rewards
    * @dev DO NOT add the same LP token more than once. Rewards will be messed
                up if you do.
    */
  function add(
    uint256 _allocPoint, 
    IERC20 _lpToken, 
    bool _withUpdate
  ) public onlyOwner {
    if (_withUpdate) {
      massUpdatePools();
    }
    uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
    totalAllocPoint = totalAllocPoint + _allocPoint;
    poolInfo.push(PoolInfo({
      lpToken: _lpToken,
      allocPoint: _allocPoint,
      lastRewardBlock: lastRewardBlock,
      accERC20PerShare: 0
    }));

    // Deposit 1 wei in order to not lose rewards 
    deposit(poolInfo.length - 1, 1 wei);
  }

  /**
    * @notice Update allocation points of a farming pool
    * @param _pid Pool id
    * @param _allocPoint Allocation points of the pool
    * @param _withUpdate If true, updates other farmimg pools
    */
  function set(
    uint256 _pid, 
    uint256 _allocPoint, 
    bool _withUpdate
  ) public onlyOwner {
    if (_withUpdate) {
      massUpdatePools();
    }
    totalAllocPoint = totalAllocPoint - poolInfo[_pid].allocPoint + _allocPoint;
    poolInfo[_pid].allocPoint = _allocPoint;
  }

  /**
    * @notice Returns the amount of deposited LPs for a user
    * @param _pid Pool id
    * @param _user Address of the user
    * @return deposited Deposited tokens of the user
    */
  function deposited(
    uint256 _pid, 
    address _user
  ) external view returns (uint256) {
    UserInfo storage user = userInfo[_pid][_user];
    return user.amount;
  }

  /**
    * @notice Returns the pending rewards for a user
    * @param _pid Pool id
    * @param _user Address of the user
    * @return rewards Rewards of the user in the farming pool
    */
  function pending(
    uint256 _pid, 
    address _user
  ) external view returns (uint256) {
    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][_user];
    uint256 accERC20PerShare = pool.accERC20PerShare;
    uint256 lpSupply = pool.lpToken.balanceOf(address(this));
    uint256 lastBlock = block.number < endBlock ? block.number : endBlock;

    if (lastBlock > pool.lastRewardBlock && lpSupply != 0) {
      uint256 nrOfBlocks = lastBlock - pool.lastRewardBlock;
      uint256 erc20Reward = nrOfBlocks * rewardPerBlock * pool.allocPoint / totalAllocPoint;
      accERC20PerShare = accERC20PerShare + erc20Reward * 1e36 / lpSupply;
    }

    return user.amount * accERC20PerShare / 1e36 - user.rewardDebt;
  }

  /**
    * @notice Returns the total amount of pending rewards
    * @return totalRewards Total amount of pending rewards
    */
  function totalPending() external view returns (uint256) {
    if (block.number <= startBlock) {
      return 0;
    }

    uint256 lastBlock = block.number < endBlock ? block.number : endBlock;
    return rewardPerBlock * (lastBlock - startBlock) - paidOut;
  }

  /**
    * @notice Updates reward variables for every farming pool
    * @dev Can be really expensive in gas
    */
  function massUpdatePools() public {
    uint256 length = poolInfo.length;
    for (uint256 pid = 0; pid < length; ++pid) {
      updatePool(pid);
    }
  }

  /**
    * @notice Updates reward variables for a single farming pool
    * @param _pid Pool id
    */
  function updatePool(
    uint256 _pid
  ) public {
    PoolInfo storage pool = poolInfo[_pid];
    uint256 lastBlock = block.number < endBlock ? block.number : endBlock;

    if (lastBlock <= pool.lastRewardBlock) {
      return;
    }
    uint256 lpSupply = pool.lpToken.balanceOf(address(this));
    if (lpSupply == 0) {
      pool.lastRewardBlock = lastBlock;
      return;
    }

    uint256 nrOfBlocks = lastBlock - pool.lastRewardBlock;
    uint256 erc20Reward = nrOfBlocks * rewardPerBlock * pool.allocPoint / totalAllocPoint;

    pool.accERC20PerShare = pool.accERC20PerShare + erc20Reward * 1e36 / lpSupply;
    pool.lastRewardBlock = block.number;
  }

  /**
    * @notice Deposit LP tokens in a farming pool
    * @param _pid Pool id
    * @param _amount Amount of LP tokens to deposit
    */
  function deposit(
    uint256 _pid, 
    uint256 _amount
  ) public {
    require(block.number <= endBlock, "deposit: cannot deposit after end block");

    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][msg.sender];
    updatePool(_pid);
    if (user.amount > 0) {
      uint256 pendingAmount = user.amount * pool.accERC20PerShare / 1e36 - user.rewardDebt;
      if (pendingAmount > 0) {
        erc20Transfer(msg.sender, pendingAmount);
      }
    }
    pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
    user.amount = user.amount + _amount;
    user.rewardDebt = user.amount * pool.accERC20PerShare / 1e36;
    emit Deposit(msg.sender, _pid, _amount);
  }

  /**
    * @notice Withdraw tokens from a farming pool
    * @param _pid Pool id
    * @param _amount Amount of LP tokens to withdraw
    */
  function withdraw(
    uint256 _pid, 
    uint256 _amount
  ) public {
    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][msg.sender];
    require(user.amount >= _amount, "withdraw: can't withdraw more than deposit");
    updatePool(_pid);

    uint256 pendingAmount = user.amount * pool.accERC20PerShare / 1e36 - user.rewardDebt;
    if (pendingAmount > 0) {
      erc20Transfer(msg.sender, pendingAmount);
    }
    
    user.amount = user.amount - _amount;
    user.rewardDebt = user.amount * pool.accERC20PerShare / 1e36;
    pool.lpToken.safeTransfer(address(msg.sender), _amount);
    emit Withdraw(msg.sender, _pid, _amount);
  }

  /**
    * @notice Withdraw LP tokens from a farming pool ignoring rewards
    * @param _pid Pool id
    * @dev Emergency only
    */
  function emergencyWithdraw(
    uint256 _pid
  ) public {
    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][msg.sender];
    pool.lpToken.safeTransfer(address(msg.sender), user.amount);
    emit EmergencyWithdraw(msg.sender, _pid, user.amount);
    user.amount = 0;
    user.rewardDebt = 0;
  }

  // Transfer ERC20 and update the required ERC20 to payout all rewards
  function erc20Transfer(
    address _to, 
    uint256 _amount
  ) internal {
    SafeERC20.safeTransfer(erc20, _to, _amount);
    paidOut += _amount;
  }
}