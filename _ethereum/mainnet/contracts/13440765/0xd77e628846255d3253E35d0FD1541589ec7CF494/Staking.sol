//SPDX-License-Identifier: Unlicense
pragma solidity =0.7.6;

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
    bool isNativePool;
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
  IERC20 public rewardToken;
  address public devAddress;
  uint256 public nativeEarlyWithdrawlDevFee;
  uint256 public nativeEarlyWithdrawlLpFee;
  uint256 public nativeRegularWithdrawlDevFee;
  uint256 public nativeRegularWithdrawlLpFee;
  uint256 public lpEarlyWithdrawlFee;
  uint256 public lpRegularWithdrawlFee;
  uint256 public nonNativeDepositDevFee;
  uint256 public nonNativeDepositLpFee;
  uint256 public kawaLpPoolId;
  uint256 public xkawaLpPoolId;
  uint256 public freeTaxDuration;

  PoolInfo[] public pools;
  mapping(address => mapping(uint256 => UserInfo)) public userInfo;
  mapping(uint256 => address[]) private userList;

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

  function setRewardToken(address _rewardToken) external onlyOwner {
    rewardToken = IERC20(_rewardToken);
  }

  function setDevAddress(address _devAddress) external onlyOwner {
    devAddress = _devAddress;
  }

  function setNativeEarlyWithdrawlDevFee(uint256 _fee) external onlyOwner {
    nativeEarlyWithdrawlDevFee = _fee;
  }

  function setNativeEarlyWithdrawlLpFee(uint256 _fee) external onlyOwner {
    nativeEarlyWithdrawlLpFee = _fee;
  }

  function setNativeRegularWithdrawlDevFee(uint256 _fee) external onlyOwner {
    nativeRegularWithdrawlDevFee = _fee;
  }

  function setNativeRegularWithdrawlLpFee(uint256 _fee) external onlyOwner {
    nativeRegularWithdrawlLpFee = _fee;
  }

  function setLpEarlyWithdrawlFee(uint256 _fee) external onlyOwner {
    lpEarlyWithdrawlFee = _fee;
  }

  function setLpRegularWithdrawlFee(uint256 _fee) external onlyOwner {
    lpRegularWithdrawlFee = _fee;
  }

  function setNonNativeDepositDevFee(uint256 _fee) external onlyOwner {
    nonNativeDepositDevFee = _fee;
  }

  function setNonNativeDepositLpFee(uint256 _fee) external onlyOwner {
    nonNativeDepositLpFee = _fee;
  }

  function setKawaLpPoolId(uint256 pid) external onlyOwner {
    kawaLpPoolId = pid;
  }

  function setXkawaLpPoolId(uint256 pid) external onlyOwner {
    xkawaLpPoolId = pid;
  }

  function setFreeTaxDuration(uint256 _duration) external onlyOwner {
    freeTaxDuration = _duration;
  }

  function addPool(
    address _stakeToken,
    bool _isNativePool,
    uint256 _rewardPerBlock,
    uint256 _lockupDuration,
    uint256 _depositLimit
  ) external onlyOwner {
    pools.push(
      PoolInfo({
        stakeToken: IERC20(_stakeToken),
        isNativePool: _isNativePool,
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
    bool _isNativePool,
    uint256 _rewardPerBlock,
    uint256 _lockupDuration,
    uint256 _depositLimit
  ) external onlyOwner {
    require(pid >= 0 && pid < pools.length, 'invalid pool id');
    PoolInfo storage pool = pools[pid];
    pool.stakeToken = IERC20(_stakeToken);
    pool.isNativePool = _isNativePool;
    pool.rewardPerBlock = _rewardPerBlock;
    pool.lockupDuration = _lockupDuration;
    pool.depositLimit = _depositLimit;
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
    require(amount > 0, 'invalid deposit amount');

    PoolInfo storage pool = pools[pid];
    UserInfo storage user = userInfo[msg.sender][pid];

    uint256 depositAmount = amount;
    uint256 totalFeePercent = nonNativeDepositDevFee
      .add(nonNativeDepositLpFee)
      .add(nonNativeDepositLpFee);
    uint256 feeAmount = amount.mul(totalFeePercent).div(100);

    if (!pool.isNativePool && !isTaxFree(pid, msg.sender)) {
      depositAmount = amount.sub(feeAmount);
    }

    require(
      user.amount.add(depositAmount) <= pool.depositLimit,
      'exceeds deposit limit'
    );

    updatePool(pid);

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

    if (depositAmount > 0) {
      pool.stakeToken.safeTransferFrom(
        address(msg.sender),
        address(this),
        amount
      );
      user.amount = user.amount.add(depositAmount);
      pool.depositedAmount = pool.depositedAmount.add(depositAmount);
    }
    user.rewardDebt = user.amount.mul(pool.accTokenPerShare).div(1e12);
    user.lastClaim = block.timestamp;
    emit Deposit(msg.sender, pid, amount);

    // swap and distribute here
    if (!pool.isNativePool && feeAmount > 0) {
      swapTokensForEth(pool.stakeToken, feeAmount);
      uint256 amountETH = address(this).balance;
      uint256 lpETH = amountETH.mul(nonNativeDepositLpFee).div(totalFeePercent);
      uint256 devETH = amountETH.sub(lpETH).sub(lpETH);
      sendEthToAddress(devAddress, devETH);
      distributeETHToLpStakers(kawaLpPoolId, lpETH);
      distributeETHToLpStakers(xkawaLpPoolId, lpETH);
    }
  }

  function withdraw(uint256 pid, uint256 amount) public {
    PoolInfo storage pool = pools[pid];
    UserInfo storage user = userInfo[msg.sender][pid];

    require(user.amount >= amount, 'Withdrawing more than you have!');

    bool isRegularWithdrawl = (block.timestamp >
      user.lastClaim + pool.lockupDuration);

    updatePool(pid);

    uint256 pending = user.amount.mul(pool.accTokenPerShare).div(1e12).sub(
      user.rewardDebt
    );
    if (pending > 0) {
      user.pendingRewards = user.pendingRewards.add(pending);
    }

    uint256 lpFee = 0;
    uint256 devFee = 0;
    if (pool.isNativePool && !isTaxFree(pid, msg.sender)) {
      if (pid == kawaLpPoolId || pid == xkawaLpPoolId) {
        if (isRegularWithdrawl) {
          devFee = amount.mul(lpRegularWithdrawlFee).div(100);
        } else {
          devFee = amount.mul(lpEarlyWithdrawlFee).div(100);
        }
      } else if (isRegularWithdrawl) {
        lpFee = amount.mul(nativeRegularWithdrawlLpFee).div(100);
        devFee = amount.mul(nativeRegularWithdrawlDevFee).div(100);
      } else {
        lpFee = amount.mul(nativeEarlyWithdrawlLpFee).div(100);
        devFee = amount.mul(nativeEarlyWithdrawlDevFee).div(100);
      }
    }
    uint256 withdrawAmount = amount.sub(lpFee).sub(lpFee).sub(devFee);

    if (amount > 0) {
      pool.stakeToken.safeTransfer(address(msg.sender), withdrawAmount);
      user.amount = user.amount.sub(amount);
      pool.depositedAmount = pool.depositedAmount.sub(amount);
    }

    if (user.amount == 0) {
      removeFromUserList(pid, msg.sender);
    }

    user.rewardDebt = user.amount.mul(pool.accTokenPerShare).div(1e12);
    user.lastClaim = block.timestamp;
    emit Withdraw(msg.sender, pid, amount);

    // swap and distribute here
    if (pool.isNativePool && !isTaxFree(pid, msg.sender)) {
      if (pid == kawaLpPoolId || pid == xkawaLpPoolId) {
        if (devFee > 0) {
          distributeTokensToStakers(pid, devFee);
        }
      } else if (isRegularWithdrawl) {
        if (devFee > 0) {
          distributeTokensToStakers(pid, devFee);
        }
        if (lpFee > 0) {
          swapTokensForEth(pool.stakeToken, lpFee.add(lpFee));
          uint256 amountETH = address(this).balance;
          uint256 lpETH = amountETH.div(2);
          distributeETHToLpStakers(kawaLpPoolId, lpETH);
          distributeETHToLpStakers(xkawaLpPoolId, lpETH);
        }
      } else {
        uint256 feeAmount = devFee.add(lpFee).add(lpFee);
        uint256 totalFeePercent = nativeRegularWithdrawlDevFee
          .add(nativeRegularWithdrawlLpFee)
          .add(nativeRegularWithdrawlLpFee);
        if (feeAmount > 0) {
          swapTokensForEth(pool.stakeToken, feeAmount);
          uint256 amountETH = address(this).balance;
          uint256 lpETH = amountETH.mul(nativeRegularWithdrawlLpFee).div(
            totalFeePercent
          );
          uint256 devETH = amountETH.sub(lpETH).sub(lpETH);
          if (devETH > 0) {
            sendEthToAddress(devAddress, devETH);
          }
          if (lpETH > 0) {
            distributeETHToLpStakers(kawaLpPoolId, lpETH);
            distributeETHToLpStakers(xkawaLpPoolId, lpETH);
          }
        }
      }
    }
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
    uint256 _bal = rewardToken.balanceOf(address(this));
    if (amount > pool.rewardsAmount) amount = pool.rewardsAmount;
    if (amount > _bal) amount = _bal;
    rewardToken.safeTransfer(to, amount);
    return amount;
  }

  function removeFromUserList(uint256 pid, address _addr) internal {
    for (uint256 i = 0; i < userList[pid].length; i++) {
      if (userList[pid][i] == _addr) {
        userList[pid][i] = userList[pid][userList[pid].length - 1];
        userList[pid].pop();
        return;
      }
    }
  }

  function swapTokensForEth(IERC20 token, uint256 tokenAmount) private {
    // generate the uniswap pair path of token -> weth
    address[] memory path = new address[](2);
    path[0] = address(token);
    path[1] = uniswapV2Router.WETH();

    token.safeApprove(address(uniswapV2Router), tokenAmount);

    // make the swap
    uniswapV2Router.swapExactTokensForETH(
      tokenAmount,
      0, // accept any amount of ETH
      path,
      address(this),
      block.timestamp
    );
  }

  function distributeTokensToStakers(uint256 pid, uint256 tokenAmount) private {
    PoolInfo storage pool = pools[pid];
    for (uint256 i = 0; i < userList[pid].length; i++) {
      address userAddress = userList[pid][i];
      uint256 amount = tokenAmount.mul(userInfo[userAddress][pid].amount).div(
        pool.depositedAmount
      );
      userInfo[userAddress][pid].amount = userInfo[userAddress][pid].amount.add(
        amount
      );
      pool.depositedAmount = pool.depositedAmount.add(amount);
    }
  }

  function distributeETHToLpStakers(uint256 pid, uint256 amountETH) private {
    PoolInfo storage pool = pools[pid];
    for (uint256 i = 0; i < userList[pid].length; i++) {
      address userAddress = userList[pid][i];
      uint256 amount = amountETH.mul(userInfo[userAddress][pid].amount).div(
        pool.depositedAmount
      );
      sendEthToAddress(userAddress, amount);
    }
  }

  function sendEthToAddress(address _addr, uint256 amountETH) private {
    payable(_addr).call{value: amountETH}('');
  }

  function isTaxFree(uint256 pid, address _user) private view returns (bool) {
    UserInfo storage user = userInfo[_user][pid];
    if (user.amount > 0) {
      uint256 diff = block.timestamp.sub(user.lastClaim);
      if (diff > freeTaxDuration) {
        return true;
      }
    }
    return false;
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
