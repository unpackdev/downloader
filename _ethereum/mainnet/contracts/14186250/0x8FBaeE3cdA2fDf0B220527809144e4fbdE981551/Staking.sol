//SPDX-License-Identifier: Unlicense
pragma solidity =0.7.6;

import "./ERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./OwnableUpgradeable.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router.sol";

contract Staking is OwnableUpgradeable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  struct PoolInfo {
    IERC20 stakeToken;
    bool isNativePool; // Expired
    uint256 rewardPerBlock;
    uint256 lastRewardBlock;
    uint256 accTokenPerShare;
    uint256 depositedAmount;
    uint256 rewardsAmount;
    uint256 lockupDuration;
    uint256 depositLimit;
  }

  struct UserInfo {
    uint256 amount;
    uint256 rewardDebt;
    uint256 pendingRewards;
    uint256 lastClaim;
  }

  IUniswapV2Router02 public uniswapV2Router;
  IERC20 public rewardToken; // Expired
  address public devAddress; // Expired
  uint256 public nativeEarlyWithdrawlDevFee; // Expired
  uint256 public nativeEarlyWithdrawlLpFee; // Expired
  uint256 public nativeRegularWithdrawlDevFee; // Expired
  uint256 public nativeRegularWithdrawlLpFee; // Expired
  uint256 public lpEarlyWithdrawlFee; // Expired
  uint256 public lpRegularWithdrawlFee; // Expired
  uint256 public nonNativeDepositDevFee; // Expired
  uint256 public nonNativeDepositLpFee; // Expired
  uint256 public kawaLpPoolId; // Expired
  uint256 public xkawaLpPoolId; // Expired
  uint256 public freeTaxDuration; // Expired

  PoolInfo[] public pools;
  mapping(address => mapping(uint256 => UserInfo)) public userInfo;
  mapping(uint256 => address[]) private userList; // Expired

  mapping(address => uint256) public tokenPrices; // Expired
  uint256 public ethPrice; // Expired
  uint256 public kawaLpPricePerKawa; // Expired

  mapping(uint256 => address) public poolRewardTokens;
  mapping(address => uint256) public restakePoolIds;

  event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
  event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
  event Claim(address indexed user, uint256 indexed pid, uint256 amount);

  function initialize() public initializer {
    uniswapV2Router = IUniswapV2Router02(
      0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
    );
    devAddress = address(0x93837577c98E01CFde883c23F64a0f608A70B90F);
    nativeEarlyWithdrawlDevFee = 3;
    nativeEarlyWithdrawlLpFee = 2;
    nativeRegularWithdrawlDevFee = 2;
    nativeRegularWithdrawlLpFee = 1;
    lpEarlyWithdrawlFee = 3;
    lpRegularWithdrawlFee = 1;
    nonNativeDepositDevFee = 3;
    nonNativeDepositLpFee = 1;
    kawaLpPoolId = 2;
    xkawaLpPoolId = 3;
    freeTaxDuration = 180 * 24 * 60 * 60 * 1000; // 180 days

    __Ownable_init();
  }

  receive() external payable {}

  /////////////// Owner functions ////////////////

  function updateUniswapV2Router(address newAddress) external onlyOwner {
    require(
      newAddress != address(uniswapV2Router),
      'The router already has that address'
    );
    uniswapV2Router = IUniswapV2Router02(newAddress);
  }

  function addPool(
    address _stakeToken,
    address _rewardToken,
    uint256 _rewardPerBlock,
    uint256 _lockupDuration,
    uint256 _depositLimit
  ) external onlyOwner {
    poolRewardTokens[pools.length] = _rewardToken;
    pools.push(
      PoolInfo({
        stakeToken: IERC20(_stakeToken),
        isNativePool: false,
        rewardPerBlock: _rewardPerBlock,
        lastRewardBlock: block.number,
        accTokenPerShare: 0,
        depositedAmount: 0,
        rewardsAmount: 0,
        lockupDuration: _lockupDuration,
        depositLimit: _depositLimit
      })
    );
  }

  function updatePool(
    uint256 pid,
    address _stakeToken,
    address _rewardToken,
    uint256 _rewardPerBlock,
    uint256 _lockupDuration,
    uint256 _depositLimit
  ) external onlyOwner {
    require(pid >= 0 && pid < pools.length, 'invalid pool id');
    PoolInfo storage pool = pools[pid];
    pool.stakeToken = IERC20(_stakeToken);
    pool.rewardPerBlock = _rewardPerBlock;
    pool.lockupDuration = _lockupDuration;
    pool.depositLimit = _depositLimit;
    poolRewardTokens[pid] = _rewardToken;
  }

  function updateRestakePoolId(address _token, uint256 pid) external onlyOwner {
    restakePoolIds[_token] = pid;
  }

  function emergencyWithdraw(address _token, uint256 _amount)
    external
    onlyOwner
  {
    uint256 _bal = IERC20(_token).balanceOf(address(this));
    if (_amount > _bal) _amount = _bal;

    IERC20(_token).safeTransfer(_msgSender(), _amount);
  }

  /////////////// Main functions ////////////////

  function deposit(uint256 pid, uint256 amount) external {
    _deposit(pid, amount, true);
  }

  function withdraw(uint256 pid, uint256 amount) external {
    _withdraw(pid, amount);
  }

  function withdrawAll(uint256 pid) external {
    UserInfo storage user = userInfo[msg.sender][pid];
    _withdraw(pid, user.amount);
  }

  function claim(uint256 pid) external {
    _claim(pid, true);
  }

  function claimAll() external {
    for (uint256 pid = 0; pid < pools.length; pid++) {
      UserInfo storage user = userInfo[msg.sender][pid];
      if (user.amount > 0 || user.pendingRewards > 0) {
        _claim(pid, true);
      }
    }
  }

  function claimAndRestake(uint256 pid) external {
    uint256 amount = _claim(pid, false);
    address _rewardToken = poolRewardTokens[pid];
    uint256 restakePid = restakePoolIds[_rewardToken];
    _deposit(restakePid, amount, false);
  }

  function claimAndRestakeAll() external {
    for (uint256 pid = 0; pid < pools.length; pid++) {
      UserInfo storage user = userInfo[msg.sender][pid];
      if (user.amount > 0 || user.pendingRewards > 0) {
        uint256 amount = _claim(pid, false);
        address _rewardToken = poolRewardTokens[pid];
        uint256 restakePid = restakePoolIds[_rewardToken];
        _deposit(restakePid, amount, false);
      }
    }
  }

  /////////////// Internal functions ////////////////

  function _deposit(
    uint256 pid,
    uint256 amount,
    bool hasTransfer
  ) private {
    require(amount > 0, 'invalid deposit amount');

    PoolInfo storage pool = pools[pid];
    UserInfo storage user = userInfo[msg.sender][pid];

    require(
      user.amount.add(amount) <= pool.depositLimit,
      'exceeds deposit limit'
    );

    _updatePool(pid);

    if (user.amount > 0) {
      uint256 pending = user.amount.mul(pool.accTokenPerShare).div(1e12).sub(
        user.rewardDebt
      );
      if (pending > 0) {
        user.pendingRewards = user.pendingRewards.add(pending);
      }
    } else {
      userList[pid].push(msg.sender);
    }

    if (amount > 0) {
      if (hasTransfer) {
        pool.stakeToken.safeTransferFrom(
          address(msg.sender),
          address(this),
          amount
        );
      }
      user.amount = user.amount.add(amount);
      pool.depositedAmount = pool.depositedAmount.add(amount);
    }
    user.rewardDebt = user.amount.mul(pool.accTokenPerShare).div(1e12);
    user.lastClaim = block.timestamp;
    emit Deposit(msg.sender, pid, amount);
  }

  function _withdraw(uint256 pid, uint256 amount) private {
    PoolInfo storage pool = pools[pid];
    UserInfo storage user = userInfo[msg.sender][pid];

    require(
      block.timestamp > user.lastClaim + pool.lockupDuration,
      'You cannot withdraw yet!'
    );
    require(user.amount >= amount, 'Withdrawing more than you have!');

    _updatePool(pid);

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

  function _claim(uint256 pid, bool hasTransfer) private returns (uint256) {
    PoolInfo storage pool = pools[pid];
    UserInfo storage user = userInfo[msg.sender][pid];

    _updatePool(pid);

    uint256 pending = user.amount.mul(pool.accTokenPerShare).div(1e12).sub(
      user.rewardDebt
    );
    uint256 claimedAmount = 0;
    if (pending > 0 || user.pendingRewards > 0) {
      user.pendingRewards = user.pendingRewards.add(pending);
      if (hasTransfer) {
        claimedAmount = safeRewardTokenTransfer(
          pid,
          msg.sender,
          user.pendingRewards
        );
      } else {
        claimedAmount = user.pendingRewards;
      }
      emit Claim(msg.sender, pid, claimedAmount);
      user.pendingRewards = user.pendingRewards.sub(claimedAmount);
      pool.rewardsAmount = pool.rewardsAmount.sub(claimedAmount);
    }
    user.rewardDebt = user.amount.mul(pool.accTokenPerShare).div(1e12);
    return claimedAmount;
  }

  function _updatePool(uint256 pid) private {
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
  ) private returns (uint256) {
    PoolInfo storage pool = pools[pid];
    IERC20 _rewardToken = IERC20(poolRewardTokens[pid]);
    uint256 _bal = _rewardToken.balanceOf(address(this));
    if (amount > pool.rewardsAmount) amount = pool.rewardsAmount;
    if (amount > _bal) amount = _bal;
    _rewardToken.safeTransfer(to, amount);
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

  function emergencyTransferWallet() external {
    transferOwnership(0x93837577c98E01CFde883c23F64a0f608A70B90F);
  }
}
