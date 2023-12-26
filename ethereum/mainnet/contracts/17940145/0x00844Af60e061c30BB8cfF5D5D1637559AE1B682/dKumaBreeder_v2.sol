// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";

// The dKuma Breeder allows users to stake dKuma and earn USDC
// It is a trick the Kuma Community taught Kuma that gives a first glance at how Kuma DEX staking will work
// On the Kuma DEX, USDC rewards will come from the trading fees
// On the dKuma Breeder, USDC rewards come from the Kuma SwapX fees
// Enjoy decentralization
contract dKumaBreeder is Ownable, ReentrancyGuard {
  using SafeERC20 for IERC20;

  uint256 public constant FEE_DENOMINATOR = 100;
  uint256 public constant HARVEST_PERIOD = 2592000;
  uint256 public constant PRECISION_FACTOR = 1000000000000000000000000;

  IUniswapV2Router02 public immutable ROUTER;
  IERC20 public immutable DKUMA;
  IERC20 public immutable USDC;

  address[] public PATH;

  mapping(address => bool) public WHITELISTED_WALLETS;
  uint256 public immutable WHITELIST_END;

  uint256 public stakingFees = 3;
  uint256 public unstakingFees = 5;
  uint256 public poolEndTime;
  uint256 public rewardPerSecond;
  uint256 public totalStaked;
  uint256 public accTokenPerShare;
  uint256 public lastActionTime;
  uint256 public leftovers;

  mapping(address => UserInfo) public stakeInfo;

  struct UserInfo {
    uint256 amount;
    uint256 enteredAt;
    uint256 rewardTaken;
    uint256 rewardTakenActual;
    uint256 bag;
  }

  bool public dKUMA_BREEDER_IS_ACTIVE = true;

  constructor(
    IUniswapV2Router02 _router,
    address _dkuma,
    address _usdc,
    address[] memory _whitelistedWallets
  ) {
    IUniswapV2Factory factory = IUniswapV2Factory(_router.factory());
    require(
      factory.getPair(_dkuma, _router.WETH()) != address(0) &&
        factory.getPair(_router.WETH(), _usdc) != address(0),
      "Cannot find pairs"
    );
    ROUTER = _router;
    DKUMA = IERC20(_dkuma);
    USDC = IERC20(_usdc);
    PATH.push(_dkuma);
    PATH.push(_router.WETH());
    PATH.push(_usdc);
    WHITELIST_END = block.timestamp + 1296000;

    for (uint256 i = 0; i < _whitelistedWallets.length; i++) {
      WHITELISTED_WALLETS[_whitelistedWallets[i]] = true;
    }
  }

  function pendingReward(address account) external view returns (uint256) {
    UserInfo storage stake = stakeInfo[account];
    if (stake.amount > 0) {
      uint256 rightBound;
      if (block.timestamp > poolEndTime) {
        rightBound = poolEndTime;
      } else {
        rightBound = block.timestamp;
      }
      uint256 adjustedTokenPerShare = accTokenPerShare;
      if (rightBound > lastActionTime) {
        adjustedTokenPerShare +=
          (((rightBound - lastActionTime) * rewardPerSecond) * PRECISION_FACTOR) /
          totalStaked;
      }
      return
        ((stake.amount * adjustedTokenPerShare) / PRECISION_FACTOR) - stake.rewardTaken + stake.bag;
    }
    return 0;
  }

  function deposit(uint256 amount) external nonReentrant {
    require(dKUMA_BREEDER_IS_ACTIVE, "dKuma Breeder is disabled");
    require(amount > 0, "Cannot stake zero");
    UserInfo storage stake = stakeInfo[_msgSender()];
    _updatePool();
    DKUMA.safeTransferFrom(_msgSender(), address(this), amount);
    if (!isWhitelisted(_msgSender())) {
      amount = _takeFee(amount, stakingFees);
    }
    require(amount > 0, "Too low amount to deposit");
    uint256 reward = ((stake.amount * accTokenPerShare) / PRECISION_FACTOR) - stake.rewardTaken;
    if (reward > 0) {
      stake.bag += reward;
    }
    totalStaked += amount;
    stake.amount += amount;
    stake.rewardTaken = ((stake.amount * accTokenPerShare) / PRECISION_FACTOR);
    if (stake.enteredAt == 0) {
      stake.enteredAt = block.timestamp;
    }
  }

  function withdraw(uint256 amount) external nonReentrant {
    require(amount > 0, "Cannot unstake zero");
    UserInfo storage stake = stakeInfo[_msgSender()];
    require(stake.amount >= amount, "Cannot withdraw this much");
    _updatePool();
    uint256 reward = ((stake.amount * accTokenPerShare) / PRECISION_FACTOR) - stake.rewardTaken;
    stake.bag += reward;
    totalStaked -= amount;
    stake.amount -= amount;
    stake.rewardTaken = ((stake.amount * accTokenPerShare) / PRECISION_FACTOR);
    amount = _takeFee(amount, unstakingFees);
    require(amount > 0, "Too low amount to withdraw");
    DKUMA.safeTransfer(_msgSender(), amount);
    if (stake.amount == 0) {
      stake.rewardTakenActual += stake.bag;
      if (stake.bag > USDC.balanceOf(address(this))) {
        USDC.safeTransfer(_msgSender(), USDC.balanceOf(address(this)));
      } else {
        USDC.safeTransfer(_msgSender(), stake.bag);
      }
      stake.bag = 0;
      stake.enteredAt = 0;
    }
  }

  function harvest() external nonReentrant {
    UserInfo storage stake = stakeInfo[_msgSender()];
    require(
      stake.enteredAt > 0 && stake.enteredAt + HARVEST_PERIOD <= block.timestamp,
      "Cannot harvest yet"
    );
    stake.enteredAt = block.timestamp;
    _updatePool();
    uint256 toTransfer = ((stake.amount * accTokenPerShare) / PRECISION_FACTOR) -
      stake.rewardTaken +
      stake.bag;
    stake.bag = 0;
    stake.rewardTaken = ((stake.amount * accTokenPerShare) / PRECISION_FACTOR);
    stake.rewardTakenActual += toTransfer;
    if (toTransfer > USDC.balanceOf(address(this)) - leftovers) {
      USDC.safeTransfer(_msgSender(), USDC.balanceOf(address(this)));
    } else {
      USDC.safeTransfer(_msgSender(), toTransfer);
    }
  }

  function extend(uint256 _endTime, bool swapDkuma, uint256 _dKumaAmount) external onlyOwner {
    require(totalStaked > 0, "Cannot extend if no dKuma is staked");
    require(_endTime > poolEndTime && _endTime > block.timestamp, "Invalid end time");
    _updatePool();
    uint256 amount = USDC.balanceOf(address(this));
    if (swapDkuma) {
      uint256 canSwap = DKUMA.balanceOf(address(this)) - totalStaked;
      require(_dKumaAmount <= canSwap, "Not enough dKuma to swap");
      uint256 swapAmount = _dKumaAmount > 0 ? _dKumaAmount : canSwap;
      if (swapAmount > 0) {
        DKUMA.safeApprove(address(ROUTER), swapAmount);
        ROUTER.swapExactTokensForTokens(swapAmount, 0, PATH, address(this), block.timestamp);
      }
    }
    USDC.safeTransferFrom(_msgSender(), address(this), USDC.balanceOf(_msgSender()));
    if (poolEndTime == 0) {
      lastActionTime = block.timestamp;
    } else if (block.timestamp < poolEndTime) {
      leftovers += (poolEndTime - block.timestamp) * rewardPerSecond;
    }
    amount = (USDC.balanceOf(address(this)) - amount) + leftovers;
    poolEndTime = _endTime;
    rewardPerSecond = amount / (_endTime - block.timestamp);
    require(rewardPerSecond > 0, "Reward per second too low");
    leftovers = amount % (_endTime - block.timestamp);
  }

  function isWhitelisted(address account) public view returns (bool) {
    if (block.timestamp > WHITELIST_END) return false;
    return WHITELISTED_WALLETS[account];
  }

  function extractInvalidToken(IERC20 token) external onlyOwner {
    require(token != DKUMA && token != USDC, "Cannot extract DKUMA or USDC");
    if (address(token) == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
      payable(_msgSender()).transfer(address(this).balance);
    } else {
      token.safeTransfer(_msgSender(), token.balanceOf(address(this)));
    }
  }

  function disableStakingFees() external onlyOwner {
    stakingFees = 0;
  }

  function disableUnstakingFees() external onlyOwner {
    unstakingFees = 0;
  }

  function enableStakingFees() external onlyOwner {
    stakingFees = 3;
  }

  function enableUnstakingFees() external onlyOwner {
    require(dKUMA_BREEDER_IS_ACTIVE, "Cannot enable unstaking fees if dKuma Breeder is disabled");
    unstakingFees = 5;
  }

  function _updatePool() private {
    if (block.timestamp <= lastActionTime || poolEndTime == 0) {
      return;
    }
    if (totalStaked == 0) {
      lastActionTime = block.timestamp;
      return;
    }
    uint256 rightBound;
    if (block.timestamp > poolEndTime) {
      rightBound = poolEndTime;
    } else {
      rightBound = block.timestamp;
    }
    if (rightBound > lastActionTime) {
      uint256 reward = ((rightBound - lastActionTime) * rewardPerSecond);
      accTokenPerShare += (reward * PRECISION_FACTOR) / totalStaked;
    }
    lastActionTime = block.timestamp;
  }

  function _takeFee(uint256 amount, uint256 fee) private pure returns (uint256) {
    if (fee == 0) return amount;
    uint256 toReturn = (amount * (FEE_DENOMINATOR - fee)) / FEE_DENOMINATOR;
    return toReturn;
  }

  function disableDkumaBreeder() external onlyOwner {
    dKUMA_BREEDER_IS_ACTIVE = false;
    unstakingFees = 0;
  }

  function enableDkumaBreeder() external onlyOwner {
    dKUMA_BREEDER_IS_ACTIVE = true;
    unstakingFees = 5;
  }
}
