//SPDX-License-Identifier: Unlicense
pragma solidity =0.7.6;

import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./OwnableUpgradeable.sol";

contract Staking is OwnableUpgradeable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  struct UserInfo {
    uint256 amount;
    uint256 rewardDebt;
    uint256 pendingRewards;
    uint256 lastClaim;
  }

  struct PoolInfo {
    IERC20 stakeToken;
    IERC20 rewardToken;
    uint256 rewardPerBlock;
    uint256 lastRewardBlock;
    uint256 accTokenPerShare;
    uint256 depositedAmount;
    uint256 rewardsAmount;
    uint256 lockupDuration;
  }

  PoolInfo[] public pools;
  mapping(address => mapping(uint256 => UserInfo)) public userInfo;

  event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
  event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
  event Claim(address indexed user, uint256 indexed pid, uint256 amount);

  function initialize() public initializer {
    __Ownable_init();
  }

  /////////////// Owner functions ////////////////

  function addPool(
    address _stakeToken,
    address _rewardToken,
    uint256 _lockupDuration,
    uint256 _rewardPerBlock
  ) external onlyOwner {
    pools.push(
      PoolInfo({
        stakeToken: IERC20(_stakeToken),
        rewardToken: IERC20(_rewardToken),
        rewardPerBlock: _rewardPerBlock,
        lastRewardBlock: block.number,
        accTokenPerShare: 0,
        depositedAmount: 0,
        rewardsAmount: 0,
        lockupDuration: _lockupDuration
      })
    );
  }

  function emergencyWithdraw(uint256 pid, uint256 _amount) external onlyOwner {
    PoolInfo storage pool = pools[pid];
    uint256 _bal = IERC20(pool.rewardToken).balanceOf(address(this));
    if (_amount > _bal) _amount = _bal;

    IERC20(pool.rewardToken).safeTransfer(_msgSender(), _amount);
  }

  function setLockupDuration(uint256 pid, uint256 _lockupDuration)
    external
    onlyOwner
  {
    require(pid >= 0 && pid < pools.length, 'invalid pool id');
    pools[pid].lockupDuration = _lockupDuration;
  }

  function setRewardPerBlock(uint256 pid, uint256 _rewardPerBlock)
    external
    onlyOwner
  {
    require(pid >= 0 && pid < pools.length, 'invalid pool id');
    pools[pid].rewardPerBlock = _rewardPerBlock;
  }

  /////////////// Main functions ////////////////

  function deposit(uint256 pid, uint256 amount) external {
    require(amount > 0, 'invalid deposit amount');

    PoolInfo storage pool = pools[pid];
    UserInfo storage user = userInfo[msg.sender][pid];

    updatePool(pid);

    if (user.amount > 0) {
      uint256 pending = user.amount.mul(pool.accTokenPerShare).div(1e12).sub(
        user.rewardDebt
      );
      if (pending > 0) {
        user.pendingRewards = user.pendingRewards.add(pending);
      }
    }
    if (amount > 0) {
      pool.stakeToken.safeTransferFrom(
        address(msg.sender),
        address(this),
        amount
      );
      user.amount = user.amount.add(amount);
      pool.depositedAmount = pool.depositedAmount.add(amount);
    }
    user.rewardDebt = user.amount.mul(pool.accTokenPerShare).div(1e12);
    user.lastClaim = block.timestamp;
    emit Deposit(msg.sender, pid, amount);
  }

  function withdraw(uint256 pid, uint256 amount) public {
    PoolInfo storage pool = pools[pid];
    UserInfo storage user = userInfo[msg.sender][pid];

    require(
      block.timestamp > user.lastClaim + pool.lockupDuration,
      'You cannot withdraw yet!'
    );
    require(user.amount >= amount, 'Withdrawing more than you have!');

    updatePool(pid);

    uint256 pending = user.amount.mul(pool.accTokenPerShare).div(1e12).sub(
      user.rewardDebt
    );
    if (pending > 0) {
      user.pendingRewards = user.pendingRewards.add(pending);
    }
    if (amount > 0) {
      pool.stakeToken.safeTransfer(address(msg.sender), amount);
      user.amount = user.amount.sub(amount);
      pool.depositedAmount = pool.depositedAmount.sub(amount);
    }
    user.rewardDebt = user.amount.mul(pool.accTokenPerShare).div(1e12);
    user.lastClaim = block.timestamp;
    emit Withdraw(msg.sender, pid, amount);
  }

  function withdrawAll(uint256 pid) external {
    UserInfo storage user = userInfo[msg.sender][pid];

    withdraw(pid, user.amount);
  }

  function claim(uint256 pid) public {
    PoolInfo storage pool = pools[pid];
    UserInfo storage user = userInfo[msg.sender][pid];

    updatePool(pid);

    uint256 pending = user.amount.mul(pool.accTokenPerShare).div(1e12).sub(
      user.rewardDebt
    );
    if (pending > 0 || user.pendingRewards > 0) {
      user.pendingRewards = user.pendingRewards.add(pending);
      uint256 claimedAmount = safeRewardTokenTransfer(
        pid,
        msg.sender,
        user.pendingRewards
      );
      emit Claim(msg.sender, pid, claimedAmount);
      user.pendingRewards = user.pendingRewards.sub(claimedAmount);
      user.lastClaim = block.timestamp;
      pool.rewardsAmount = pool.rewardsAmount.sub(claimedAmount);
    }
    user.rewardDebt = user.amount.mul(pool.accTokenPerShare).div(1e12);
  }

  /////////////// Internal functions ////////////////

  function updatePool(uint256 pid) internal {
    PoolInfo storage pool = pools[pid];

    if (block.number <= pool.lastRewardBlock) {
      return;
    }
    uint256 depositedAmount = pool.depositedAmount;
    if (pool.depositedAmount == 0) {
      pool.lastRewardBlock = block.number;
      return;
    }
    uint256 multiplier = block.number.sub(pool.lastRewardBlock);
    uint256 tokenReward = multiplier.mul(pool.rewardPerBlock);
    pool.rewardsAmount = pool.rewardsAmount.add(tokenReward);
    pool.accTokenPerShare = pool.accTokenPerShare.add(
      tokenReward.mul(1e12).div(depositedAmount)
    );
    pool.lastRewardBlock = block.number;
  }

  function safeRewardTokenTransfer(
    uint256 pid,
    address to,
    uint256 amount
  ) internal returns (uint256) {
    PoolInfo storage pool = pools[pid];
    uint256 _bal = pool.rewardToken.balanceOf(address(this));
    if (amount > pool.rewardsAmount) amount = pool.rewardsAmount;
    if (amount > _bal) amount = _bal;
    pool.rewardToken.safeTransfer(to, amount);
    return amount;
  }

  /////////////// Get functions ////////////////

  function pendingRewards(uint256 pid, address _user)
    external
    view
    returns (uint256)
  {
    PoolInfo storage pool = pools[pid];
    UserInfo storage user = userInfo[_user][pid];
    uint256 accTokenPerShare = pool.accTokenPerShare;
    uint256 depositedAmount = pool.depositedAmount;
    if (block.number > pool.lastRewardBlock && depositedAmount != 0) {
      uint256 multiplier = block.number.sub(pool.lastRewardBlock);
      uint256 tokenReward = multiplier.mul(pool.rewardPerBlock);
      accTokenPerShare = accTokenPerShare.add(
        tokenReward.mul(1e12).div(depositedAmount)
      );
    }
    return
      user.amount.mul(accTokenPerShare).div(1e12).sub(user.rewardDebt).add(
        user.pendingRewards
      );
  }

  function getPoolCount() external view returns (uint256) {
    return pools.length;
  }
}
