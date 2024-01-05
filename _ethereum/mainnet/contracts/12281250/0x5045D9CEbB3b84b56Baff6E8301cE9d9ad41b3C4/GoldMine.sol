// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./IAlchemist.sol";

contract GoldMine is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  struct UserInfo {
    uint256 staked;
    uint256 goldDebt;
    uint256 depositBlock;
  }

  struct PoolInfo {
    address stakingToken;
    uint256 totalStaked;
    uint256 goldPerBlock;
    uint256 goldStartBlock;
    uint256 goldEndBlock;
    uint256 accGoldPerShare_e24;
    uint256 lastUpdateBlock;

    uint256 minHodlBlocks;
    uint256 earlyWithdrawalFeeBps;
  }

  IAlchemist public alchemist;
  IERC20 public goldToken;
  address public feeAddress;

  PoolInfo[] public poolInfo;
  mapping(uint256 => mapping(address => UserInfo)) public userInfo;

  event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
  event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
  event Harvest(address indexed user, uint256 indexed pid, uint256 amount);

  constructor(IAlchemist _alchemist, IERC20 _goldToken, address _feeAddress) public {
    alchemist = _alchemist;
    goldToken = _goldToken;
    feeAddress = _feeAddress;
  }

  function poolLength() external view returns (uint256) {
    return poolInfo.length;
  }

  function addPool(
    address _stakingToken,
    uint256 _goldPerBlock,
    uint256 _goldStartBlock,
    uint256 _goldEndBlock,
    uint256 _minHodlBlocks,
    uint256 _earlyWithdrawalFeeBps
  ) public onlyOwner {
    require(_earlyWithdrawalFeeBps <= 10000, "addPool: invalid early withdrawal fee");
    massUpdatePools();
    poolInfo.push(
      PoolInfo({
        stakingToken: _stakingToken,
        totalStaked: 0,
        goldPerBlock: _goldPerBlock,
        goldStartBlock: _goldStartBlock,
        goldEndBlock: _goldEndBlock,
        accGoldPerShare_e24: 0,
        lastUpdateBlock: _goldStartBlock,
        minHodlBlocks: _minHodlBlocks,
        earlyWithdrawalFeeBps: _earlyWithdrawalFeeBps
      })
    );
  }

  function updatePool(uint256 _pid) public {
    PoolInfo storage pool = poolInfo[_pid];
    if (block.number <= pool.lastUpdateBlock || block.number < pool.goldStartBlock) {
        return;
    }
    if (pool.lastUpdateBlock >= pool.goldEndBlock) {
        return;
    }
    uint256 pendingEndBlock = block.number >= pool.goldEndBlock ? pool.goldEndBlock : block.number;
    if (pool.totalStaked > 0) {
      uint256 newGold = pendingEndBlock.sub(pool.lastUpdateBlock).mul(pool.goldPerBlock);
      alchemist.mintGold(address(this), newGold);
      pool.accGoldPerShare_e24 = pool.accGoldPerShare_e24.add(newGold.mul(1e24).div(pool.totalStaked));
    }
    pool.lastUpdateBlock = pendingEndBlock;
  }

  function massUpdatePools() public {
      uint256 length = poolInfo.length;
      for (uint256 pid = 0; pid < length; ++pid) {
          updatePool(pid);
      }
  }

  function deposit(uint256 _pid, uint256 _amount) public {
    require(_amount > 0, "deposit must be non-zero");

    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][msg.sender];
    updatePool(_pid);
    if (user.staked > 0) {
      uint256 pending = user.staked.mul(pool.accGoldPerShare_e24).div(1e24).sub(user.goldDebt);
      safeGoldTransfer(msg.sender, pending);
    }
    if (_amount > 0) {
      IERC20(pool.stakingToken).safeTransferFrom(
        address(msg.sender),
        address(this),
        _amount
      );
      user.staked = user.staked.add(_amount);
      user.depositBlock = block.number;
      pool.totalStaked = pool.totalStaked.add(_amount);
    }
    user.goldDebt = user.staked.mul(pool.accGoldPerShare_e24).div(1e24);
    emit Deposit(msg.sender, _pid, _amount);
  }

  function harvest(uint256 _pid) public {
    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][msg.sender];
    updatePool(_pid);
    uint256 pending = user.staked.mul(pool.accGoldPerShare_e24).div(1e24).sub(user.goldDebt);
    require(pending > 0, "harvest: no gold owed");
    user.goldDebt = user.staked.mul(pool.accGoldPerShare_e24).div(1e24);
    safeGoldTransfer(msg.sender, pending);
    emit Harvest(msg.sender, _pid, pending);
  }

  function _withdraw(uint256 _pid, uint256 _amount) internal {
    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][msg.sender];
    require(user.staked >= _amount, "withdraw: invalid amount");
    updatePool(_pid);
    uint256 pending = user.staked.mul(pool.accGoldPerShare_e24).div(1e24).sub(user.goldDebt);
    if (pending > 0) {
      user.goldDebt = user.staked.mul(pool.accGoldPerShare_e24).div(1e24);
      safeGoldTransfer(msg.sender, pending);
    }

    user.staked = user.staked.sub(_amount);
    user.goldDebt = user.staked.mul(pool.accGoldPerShare_e24).div(1e24);
    pool.totalStaked = pool.totalStaked.sub(_amount);

    if ((pool.earlyWithdrawalFeeBps > 0) &&
        ((block.number - user.depositBlock) < pool.minHodlBlocks)) {
      uint256 feeAmount = _amount.mul(pool.earlyWithdrawalFeeBps).div(10000);
      if (feeAmount > 0) {
        IERC20(pool.stakingToken).safeTransfer(feeAddress, feeAmount);
      }
      IERC20(pool.stakingToken).safeTransfer(msg.sender, _amount.sub(feeAmount));
    }
    else {
      IERC20(pool.stakingToken).safeTransfer(msg.sender, _amount);
    }
  }

  function withdraw(uint256 _pid, uint256 _amount) public {
      _withdraw(_pid, _amount);
      emit Withdraw(msg.sender, _pid, _amount);
  }

  function withdrawAll(uint256 _pid) public {
      UserInfo storage user = userInfo[_pid][msg.sender];
      uint256 amount = user.staked;
      _withdraw(_pid, amount);
      emit Withdraw(msg.sender, _pid, amount);
  }

  function pendingReward(uint256 _pid, address _user) external view returns (uint256) {
    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][_user];
    uint256 accGoldPerShare_e24 = pool.accGoldPerShare_e24;

    if (block.number >= pool.goldStartBlock &&
        block.number > pool.lastUpdateBlock &&
        pool.totalStaked > 0 &&
        pool.lastUpdateBlock < pool.goldEndBlock
    ) {
      uint256 pendingEndBlock = block.number >= pool.goldEndBlock ? pool.goldEndBlock : block.number;
      uint256 newGold = pendingEndBlock.sub(pool.lastUpdateBlock).mul(pool.goldPerBlock);
      accGoldPerShare_e24 = accGoldPerShare_e24.add(newGold.mul(1e24).div(pool.totalStaked));
    }
    return user.staked.mul(accGoldPerShare_e24).div(1e24).sub(user.goldDebt);
  }

  // Safe transfer function, just in case rounding error causes pool to not have enough rewards.
  function safeGoldTransfer(address _to, uint256 _amount) internal {
    if (_amount > 0) {
      uint256 balance = goldToken.balanceOf(address(this));
      if (_amount > balance) {
        if (balance > 0) {
          goldToken.transfer(_to, balance);
        }
      }
      else {
        goldToken.transfer(_to, _amount);
      }
    }
  }

  // =========================================
  // Timelocked functions to support new mines
  // =========================================
  function setFeeAddress(address _feeAddress) public onlyOwner {
      feeAddress = _feeAddress;
  }

  function setAlchemist(IAlchemist _alchemist) public onlyOwner {
    alchemist = _alchemist;
  }

  function shutdownPool(uint256 _pid, uint256 _goldEndBlock, uint256 _minHodlBlocks) public onlyOwner {
    require(block.number <= _goldEndBlock, "shutdownPool: invalid block");

    PoolInfo storage pool = poolInfo[_pid];
    pool.goldEndBlock = _goldEndBlock;
    pool.minHodlBlocks = _minHodlBlocks;
  }
}
