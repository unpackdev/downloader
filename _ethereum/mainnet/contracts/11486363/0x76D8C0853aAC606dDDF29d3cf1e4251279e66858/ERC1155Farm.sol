// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0 <0.7.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IERC1155.sol";
import "./ERC1155Holder.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

import "./IVault.sol";

contract ERC1155Farm is IVault, Ownable, ERC1155Holder {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
  event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
  event ClaimedRewards(
    address indexed user,
    uint256 indexed pid,
    uint256 amount
  );
  event EmergencyWithdraw(
    address indexed user,
    uint256 indexed pid,
    uint256 amount
  );

  /// @notice Detail of each user.
  struct UserInfo {
    uint256 amount; // How many tokens the user has provided.
    uint256 rewardDebt; // Reward debt. See explanation below.
    //
    // We do some fancy math here. Basically, any point in time, the amount of reward
    // entitled to a user which is pending to be distributed is:
    //
    // pending reward = (user.amount * pool.accRewardPerShare) - user.rewardDebt
    //
    // Whenever a user deposits or withdraws tokens to a pool:
    //   1. The pool's `accRewardPerShare` (and `lastRewardBlock`) gets updated.
    //   2. User receives the pending reward sent to their address.
    //   3. User's `amount` gets updated.
    //   4. User's `rewardDebt` gets updated.
  }

  /// @notice Detail of each pool.
  struct PoolInfo {
    address token; // Token to stake.
    uint256 tokenId; // NFT ID
    uint256 allocPoint; // How many allocation points assigned to this pool. Rewards to distribute per block.
    uint256 accRewardPerShare; // Accumulated rewards per share.
  }

  /// @dev Reward token balance minus any pending rewards.
  uint256 private rewardTokenBalance;

  /// @dev Division precision.
  uint256 private precision = 1e12;

  /// @notice Total allocation points. Must be the sum of all allocation points in all pools.
  uint256 public totalAllocPoint;

  /// @notice Pending rewards awaiting for massUpdate.
  uint256 public pendingRewards;

  /// @notice Contract block deployment.
  uint256 public initialBlock;

  /// @notice Time of the contract deployment.
  uint256 public timeDeployed;

  /// @notice Total rewards accumulated since contract deployment.
  uint256 public totalCumulativeRewards;

  /// @notice Reward token.
  address public rewardToken;

  /// @notice Detail of each pool.
  PoolInfo[] public poolInfo;

  /// @notice Detail of each user who stakes tokens.
  mapping(uint256 => mapping(address => UserInfo)) public userInfo;

  constructor(address _rewardToken) public {
    rewardToken = _rewardToken;
    initialBlock = block.number;
    timeDeployed = block.timestamp;
  }

  /// @notice Average fee generated since contract deployment.
  function avgFeesPerBlockTotal() external view returns (uint256 avgPerBlock) {
    return totalCumulativeRewards.div(block.number.sub(initialBlock));
  }

  /// @notice Average fee per second generated since contract deployment.
  function avgFeesPerSecondTotal()
    external
    view
    returns (uint256 avgPerSecond)
  {
    return totalCumulativeRewards.div(block.timestamp.sub(timeDeployed));
  }

  /// @notice Total pools.
  function poolLength() external view returns (uint256) {
    return poolInfo.length;
  }

  /// @notice Display user rewards for a specific pool.
  function pendingReward(uint256 _pid, address _user)
    public
    view
    returns (uint256)
  {
    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][_user];
    uint256 accRewardPerShare = pool.accRewardPerShare;

    return
      user.amount.mul(accRewardPerShare).div(precision).sub(user.rewardDebt);
  }

  /// @notice Add a new pool.
  function add(
    uint256 _allocPoint,
    address _token,
    uint256 _tokenId,
    bool _withUpdate
  ) public onlyOwner {
    if (_withUpdate) {
      massUpdatePools();
    }

    uint256 length = poolInfo.length;

    for (uint256 pid = 0; pid < length; ++pid) {
      if (poolInfo[pid].token == _token) {
        require(
          poolInfo[pid].tokenId != _tokenId,
          'NFTRewardsVault: Token pool already added.'
        );
      }
    }

    totalAllocPoint = totalAllocPoint.add(_allocPoint);

    poolInfo.push(
      PoolInfo({
        token: _token,
        tokenId: _tokenId,
        allocPoint: _allocPoint,
        accRewardPerShare: 0
      })
    );
  }

  /// @notice Update the given pool's allocation point.
  function set(
    uint256 _pid,
    uint256 _allocPoint,
    bool _withUpdate
  ) public onlyOwner {
    if (_withUpdate) {
      massUpdatePools();
    }

    totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(
      _allocPoint
    );
    poolInfo[_pid].allocPoint = _allocPoint;
  }

  /// @notice Updates rewards for all pools by adding pending rewards.
  /// Can spend a lot of gas.
  function massUpdatePools() public {
    uint256 length = poolInfo.length;
    uint256 allRewards;

    for (uint256 pid = 0; pid < length; ++pid) {
      allRewards = allRewards.add(_updatePool(pid));
    }

    pendingRewards = pendingRewards.sub(allRewards);
  }

  /// @notice Function that is part of Vault's interface. It must be implemented.
  function update(uint256 amount) external override {
    amount; // silence warning.
    _addPendingRewards();
    massUpdatePools();
  }

  /// @notice Deposit tokens to vault for reward allocation.
  function deposit(uint256 _pid, uint256 _amount) public {
    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][msg.sender];

    massUpdatePools();

    // Transfer pending tokens to user
    _updateAndPayOutPending(_pid, msg.sender);

    //Transfer in the amounts from user
    if (_amount > 0) {
      IERC1155(pool.token).safeTransferFrom(
        address(msg.sender),
        address(this),
        pool.tokenId,
        _amount,
        ''
      );
      user.amount = user.amount.add(_amount);
    }

    user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(precision);
    emit Deposit(msg.sender, _pid, _amount);
  }

  // Withdraw  tokens from Vault.
  function withdraw(uint256 _pid, uint256 _amount) public {
    _withdraw(_pid, _amount, msg.sender, msg.sender);
  }

  // Withdraw without caring about rewards. EMERGENCY ONLY.
  // !Caution this will remove all your pending rewards!
  function emergencyWithdraw(uint256 _pid) public {
    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][msg.sender];
    IERC1155(pool.token).safeTransferFrom(
      address(this),
      address(msg.sender),
      pool.tokenId,
      user.amount,
      ''
    );
    emit EmergencyWithdraw(msg.sender, _pid, user.amount);
    user.amount = 0;
    user.rewardDebt = 0;
    // No mass update dont update pending rewards
  }

  /// @notice Adds any rewards that were sent to the contract since last reward update.
  function _addPendingRewards() internal {
    uint256 newRewards =
      IERC20(rewardToken).balanceOf(address(this)).sub(rewardTokenBalance);

    if (newRewards > 0) {
      rewardTokenBalance = IERC20(rewardToken).balanceOf(address(this));
      pendingRewards = pendingRewards.add(newRewards);
      totalCumulativeRewards = totalCumulativeRewards.add(newRewards);
    }
  }

  // Low level withdraw function
  function _withdraw(
    uint256 _pid,
    uint256 _amount,
    address from,
    address to
  ) internal {
    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][from];
    require(
      user.amount >= _amount,
      'NFTRewardsVault: Withdraw amount is greater than user stake.'
    );
    massUpdatePools();
    _updateAndPayOutPending(_pid, from); // Update balance and claim rewards farmed

    if (_amount > 0) {
      user.amount = user.amount.sub(_amount);
      IERC1155(pool.token).safeTransferFrom(
        address(this),
        address(to),
        pool.tokenId,
        _amount,
        ''
      );
    }

    user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(precision);
    emit Withdraw(to, _pid, _amount);
  }

  /// @notice Allocates pending rewards to pool.
  function _updatePool(uint256 _pid)
    internal
    returns (uint256 poolShareRewards)
  {
    PoolInfo storage pool = poolInfo[_pid];

    uint256 stakedTokens;

    stakedTokens = IERC1155(pool.token).balanceOf(address(this), pool.tokenId);

    if (totalAllocPoint == 0 || stakedTokens == 0) {
      return 0;
    }

    poolShareRewards = pendingRewards.mul(pool.allocPoint).div(totalAllocPoint);
    pool.accRewardPerShare = pool.accRewardPerShare.add(
      poolShareRewards.mul(precision).div(stakedTokens)
    );
  }

  function _safeRewardTokenTransfer(address _to, uint256 _amount)
    internal
    returns (uint256 _claimed)
  {
    uint256 rewardTokenBal = IERC20(rewardToken).balanceOf(address(this));

    if (_amount > rewardTokenBal) {
      _claimed = rewardTokenBal;
      IERC20(rewardToken).transfer(_to, rewardTokenBal);
      rewardTokenBalance = IERC20(rewardToken).balanceOf(address(this));
    } else {
      _claimed = _amount;
      IERC20(rewardToken).transfer(_to, _amount);
      rewardTokenBalance = IERC20(rewardToken).balanceOf(address(this));
    }
  }

  function _updateAndPayOutPending(uint256 _pid, address _from) internal {
    uint256 pending = pendingReward(_pid, _from);

    if (pending > 0) {
      uint256 _amountClaimed = _safeRewardTokenTransfer(_from, pending);
      emit ClaimedRewards(_from, _pid, _amountClaimed);
    }
  }
}
