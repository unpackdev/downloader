// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./Aureus.sol";
import "./IERC20.sol";
import "./EnumerableSet.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";

contract ElysianFields is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for Aureus;
  using SafeERC20 for IERC20;

  struct UserInfo {
    uint256 amount; // amount of LP tokens provided by the user
    uint256 rewardDebt; // Reward debt. See explanation below.
    //
    // We do some fancy math here. Basically, any point in time, the amount of AURs
    // entitled to a user but is pending to be distributed is:
    //
    //   pending reward = (user.amount * pool.accRwdPerShare) - user.rewardDebt
    //
    // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
    //   1. The pool's `accRwdPerShare` (and `lastRewardBlock`) gets updated.
    //   2. User receives the pending reward sent to his/her address.
    //   3. User's `amount` gets updated.
    //   4. User's `rewardDebt` gets updated.
  }

  struct PoolInfo {
    IERC20 lpToken; // address of the LP token contract
    uint256 allocPoint; // Allocation points for said pool. AURs to be distributed to pool participants per block
    uint256 lastRewardBlock; // Last block number that AURs distribution occurs.
    uint256 accRwdPerShare; // Accumulated AUR rewards per share, times 1e18
  }

  constructor(
    address _owner,
    string memory _name,
    string memory _symbol,
    uint256 _cap,
    uint256 _amountForPool,
    address _rewardReceiver
  ) {
    transferOwnership(_owner);
    deployAureus(_name, _symbol, _cap, _amountForPool, _rewardReceiver);
  }

  // The Reward token
  Aureus public rwdToken;
  // Info of each pool.
  PoolInfo[] public poolInfo;
  // Info of each user that stakes LP tokens.
  mapping(uint256 => mapping(address => UserInfo)) public userInfo;
  // Total allocation points in all pools.
  uint256 public totalAllocPoints = 0;
  // Reward tokens per block to be distributed
  uint256 public rwdPerBlock;
  // The block number when RWD mining starts
  uint256 public startBlock;
  // The ending block of the current program - rwdPerBlock will be set to 0 after block number is reached
  uint256 public endBlock;
  // The timeout expressed in block, after which owner can withdraw excess amount
  uint256 public claimTimeout;

  event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
  event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
  event EmergencyWithdraw(
    address indexed user,
    uint256 indexed pid,
    uint256 amount
  );

  /** @dev Deploys a new RewardToken contract. Callable only by Owner. Mints the cap amount and transfers it to this contract
   * @param _name - Pass a name for the token
   * @param _symbol - Pass a symbol for the token
   * @param _cap - set a cap on how many ERC20 reward tokens can be minted
   * @param _amountForPool - a portion of the ERC20 reward token is transferred to owner to create a new pool on a DEX
   * @param _rewardReceiver - receiver of the portion of ERC20 reward token
   */
  function deployAureus(
    string memory _name,
    string memory _symbol,
    uint256 _cap,
    uint256 _amountForPool,
    address _rewardReceiver
  ) internal {
    rwdToken = new Aureus(_name, _symbol, _cap);
    rwdToken.safeTransfer(_rewardReceiver, _amountForPool);
  }

  /** @dev - A function to add a pool or multiple pools to the contract
   * @param _allocPoints - An array of the allocation points for each pool that will be added
   * @param _lpTokens - An array of each LP token for which a pool is created
   */
  function add(uint256[] calldata _allocPoints, IERC20[] calldata _lpTokens)
    external
    onlyOwner
  {
    require(
      address(rwdToken) != address(0),
      'A reward token has not been deployed'
    );
    require(
      _allocPoints.length == _lpTokens.length,
      'Arrays length doesnt match'
    );
    massUpdatePools();
    uint256 lastRewardBlock =
      block.number > startBlock ? block.number : startBlock;
    uint256 tempTotalAllocPoints = totalAllocPoints;
    for (uint256 j = 0; j < _lpTokens.length; j++) {
      tempTotalAllocPoints = tempTotalAllocPoints.add(_allocPoints[j]);
      poolInfo.push(
        PoolInfo({
          lpToken: _lpTokens[j],
          allocPoint: _allocPoints[j],
          lastRewardBlock: lastRewardBlock,
          accRwdPerShare: 0
        })
      );
    }
    totalAllocPoints = tempTotalAllocPoints;
  }

  /** @dev - Updates the allocationPoints for an array of pools
   * @param _pids - An array of pool ids which will be updated
   * @param _allocPoints - An array of allocationPoints for each pool that will be updated
   */
  function set(uint256[] calldata _pids, uint256[] calldata _allocPoints)
    external
    onlyOwner
  {
    require(_pids.length == _allocPoints.length, 'Arrays length doesnt match');
    massUpdatePools();
    uint256 tempTotalAllocPoints = totalAllocPoints;
    for (uint256 j = 0; j < _pids.length; j++) {
      poolInfo[_pids[j]].allocPoint = _allocPoints[j];
      tempTotalAllocPoints = tempTotalAllocPoints
        .sub(poolInfo[_pids[j]].allocPoint)
        .add(_allocPoints[j]);
    }
    totalAllocPoints = tempTotalAllocPoints;
  }

  /** @dev Allows the owner to set the parameters for a new upcomming farming program
   * @param _startBlock - the starting block when the farming program will start
   * @param _endBlock - the block on which the farming program will end
   * @param _rwdPerBlock - updates the rwdPerBlock variable for the new farming program
   * @param _ownerWithdrawBlockTimeout - The added timeout after a program finishes after which the excess ERC20 tokens stored can be withdrawn by the owner
   */
  function setProgramParameters(
    uint256 _startBlock,
    uint256 _endBlock,
    uint256 _rwdPerBlock,
    uint256 _ownerWithdrawBlockTimeout
  ) external onlyOwner {
    require(
      startBlock == 0,
      'The start block of a program has already been set'
    );
    require(poolInfo.length > 0, 'No pools added');
    require(
      _startBlock > block.number,
      'The start block passed is before the current block number'
    );
    require(
      _endBlock > _startBlock,
      'The end block passed should be bigger than _startBlock'
    );
    require(_rwdPerBlock != 0, 'The reward per block can not be set to 0');
    require(
      _ownerWithdrawBlockTimeout > 0,
      'Claim timeout can not be set to 0'
    );
    require(
      rwdToken.balanceOf(address(this)) >=
        _rwdPerBlock.mul(_endBlock - _startBlock),
      'Smart contract has not enough balance in rewards token'
    );
    startBlock = _startBlock;
    endBlock = _endBlock;
    rwdPerBlock = _rwdPerBlock;
    claimTimeout = endBlock.add(_ownerWithdrawBlockTimeout);
  }

  /** @dev Allows the owner to withdraw any excess ERC20 tokens stored in the contract
   * @param _receiver - The receiving address for the ERC20 tokens
   */
  function withdrawExcessRwd(address _receiver) external onlyOwner {
    require(
      block.number > claimTimeout,
      'The current farming program has not finished'
    );
    uint256 amount = rwdToken.balanceOf(address(this));
    rwdToken.safeTransfer(_receiver, amount);
  }

  /** @dev - A function to be called when depositing LP tokens to a certain pool
   * @param _pid - The pool id to which the user wants to deposit LP tokens
   * @param _amount - The amount of LP tokens to be deposited
   * emit - Emits the Deposit event
   */
  function deposit(uint256 _pid, uint256 _amount) external {
    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][msg.sender];
    updatePool(_pid);
    if (user.amount > 0) {
      uint256 pending =
        user.amount.mul(pool.accRwdPerShare).div(1e18).sub(user.rewardDebt);
      safeRewardTransfer(msg.sender, pending);
    }
    pool.lpToken.safeTransferFrom(msg.sender, address(this), _amount);
    user.amount = user.amount.add(_amount);
    user.rewardDebt = user.amount.mul(pool.accRwdPerShare).div(1e18);
    emit Deposit(msg.sender, _pid, _amount);
  }

  /** @dev - A function which is called to withdraw LP tokens from a pool
   * @param _pid - The pool id from which to withdraw the deposited LP tokens
   * @param _amount - The amount of LP tokens to withdraw
   * emits - Withdraw event is emited
   */
  function withdraw(uint256 _pid, uint256 _amount) external {
    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][msg.sender];
    require(user.amount >= _amount, 'withdraw: not good');
    updatePool(_pid);
    uint256 pending =
      user.amount.mul(pool.accRwdPerShare).div(1e18).sub(user.rewardDebt);
    safeRewardTransfer(msg.sender, pending);
    user.amount = user.amount.sub(_amount);
    user.rewardDebt = user.amount.mul(pool.accRwdPerShare).div(1e18);
    pool.lpToken.safeTransfer(address(msg.sender), _amount);
    emit Withdraw(msg.sender, _pid, _amount);
  }

  /** @dev - A function to withdraw any outstanding LP tokens of a user without withdrawing ERC20 reward tokens
   * @param _pid - The pool id on which to perform emergency withdraw
   */
  function emergencyWithdraw(uint256 _pid) external {
    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][msg.sender];
    pool.lpToken.safeTransfer(address(msg.sender), user.amount);
    emit EmergencyWithdraw(msg.sender, _pid, user.amount);
    user.amount = 0;
    user.rewardDebt = 0;
  }

  /** @dev - Calculates the pending ERC20 reward tokens the user can claim
   * @param _pid - The pool id
   * @param _user - The address of the user
   * return - the pending ERC20 reward tokens to be claimed
   */
  function pendingRwd(uint256 _pid, address _user)
    external
    view
    returns (uint256)
  {
    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][_user];
    uint256 accRwdPerShare = pool.accRwdPerShare;
    uint256 lpSupply = pool.lpToken.balanceOf(address(this));
    if (block.number > pool.lastRewardBlock && lpSupply != 0) {
      uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
      uint256 rwdReward =
        multiplier.mul(rwdPerBlock).mul(pool.allocPoint).div(totalAllocPoints);
      accRwdPerShare = accRwdPerShare.add(rwdReward.mul(1e18).div(lpSupply));
    }
    return user.amount.mul(accRwdPerShare).div(1e18).sub(user.rewardDebt);
  }

  /** @dev Checks the poolInfo struct lenght
   * return the number of active pools
   */
  function poolLength() external view returns (uint256) {
    return poolInfo.length;
  }

  /** @dev - Updates the variables of each pool in the array
   */
  function massUpdatePools() public {
    uint256 length = poolInfo.length;
    for (uint256 pid = 0; pid < length; ++pid) {
      updatePool(pid);
    }
  }

  /** @dev - Updates the pool variables to be up to date
   * @param _pid - The ID of the pool to be updated
   */
  function updatePool(uint256 _pid) public {
    require(
      block.number >= startBlock,
      'The farming program has not yet started!'
    );
    PoolInfo storage pool = poolInfo[_pid];
    if (block.number <= pool.lastRewardBlock) {
      return;
    }
    uint256 lpSupply = pool.lpToken.balanceOf(address(this));
    if (lpSupply == 0) {
      pool.lastRewardBlock = block.number;
      return;
    }
    uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
    uint256 rwdReward =
      multiplier.mul(rwdPerBlock).mul(pool.allocPoint).div(totalAllocPoints);
    pool.accRwdPerShare = pool.accRwdPerShare.add(
      rwdReward.mul(1e18).div(lpSupply)
    );
    pool.lastRewardBlock = block.number < endBlock ? block.number : endBlock;
  }

  /** @dev - Calculates and returns reward multiplier over the given _from to _to block.
   * @param _from - Should be a block number
   * @param _to - Should be a block number
   */
  function getMultiplier(uint256 _from, uint256 _to)
    public
    view
    returns (uint256)
  {
    if (_to <= endBlock) {
      return _to.sub(_from);
    } else if (_from >= endBlock) {
      return (_to.sub(_from)).mul(0);
    } else {
      return endBlock.sub(_from);
    }
  }

  /** @dev - A function used for safeTransfer of ERC20 tokens to the user
   * @param _to - The address to which the ERC20 tokens should be transferred
   * @param _amount - The amount to be transferred
   */
  function safeRewardTransfer(address _to, uint256 _amount) internal {
    uint256 rwdTokenBal = rwdToken.balanceOf(address(this));
    if (_amount > rwdTokenBal) {
      rwdToken.transfer(_to, rwdTokenBal);
    } else {
      rwdToken.transfer(_to, _amount);
    }
  }
}
