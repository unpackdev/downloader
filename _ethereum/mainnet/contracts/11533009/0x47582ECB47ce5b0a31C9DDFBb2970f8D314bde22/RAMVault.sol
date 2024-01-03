// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./SafeERC20.sol";
import "./Ownable.sol";

import "./Bytes.sol";
import "./PoolHelper.sol";
import "./UserHelper.sol";
import "./INFT.sol";
import "./StorageState.sol";


// Ram Vault distributes fees equally amongst staked pools
contract RAMVault is StorageState, OwnableUpgradeSafe {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;
  using Bytes for bytes;
  using UserHelper for YGYStorageV1.UserInfo;
  using PoolHelper for YGYStorageV1.PoolInfo;

  event NewEpoch(uint256);
  event RewardPaid(uint256 pid, address to);
  event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
  event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
  event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
  event Approval(address indexed owner, address indexed spender, uint256 _pid, uint256 value);
  event Boost(address indexed user, uint256 indexed pid, uint256 indexed level, bool fromNFT);

  address private devaddr;
  address private teamaddr;
  address private regeneratoraddr;
  address private nftFactory;

  function initialize(
    address __superAdmin,
    address _regeneratoraddr,
    address _devaddr,
    address _teamaddr,
    address _nftFactory
  ) public initializer {
    OwnableUpgradeSafe.__Ownable_init();
    DEV_FEE = 724;
    _superAdmin = __superAdmin;
    regeneratoraddr = _regeneratoraddr;
    devaddr = _devaddr;
    teamaddr = _teamaddr;
    nftFactory = _nftFactory;
  }

  function NFTUsage(
    address _user,
    address _tokenAddress,
    uint256 _tokenId,
    uint256 _poolId
  ) external {
    require(msg.sender == nftFactory, "Prohibited caller");
    INFT nft = INFT(_tokenAddress);
    YGYStorageV1.NFTProperty memory properties = nft.getTokenProperty(_tokenId);
    YGYStorageV1.UserInfo memory user = UserHelper.getUser(_poolId, _user, _storage);

    YGYStorageV1.PoolInfo memory pool = PoolHelper.getPool(_poolId, _storage);
    if (keccak256(abi.encodePacked(properties.pType)) == keccak256("boost")) {
      _storage.setNFTInUse(nft.contractId(), _user);
      user.adjustEffectiveStake(pool, _user, 0, false, _storage);
    }
    nft.burn(_tokenId);
    _storage.updateUserInfo(_poolId, _user, user);
    _storage.updatePoolInfo(_poolId, pool);
    emit Boost(_user, _poolId, 0, true);
  }

  // --------------------------------------------
  //                  EPOCH
  // --------------------------------------------

  // Starts a new calculation epoch
  // Also dismisses NFT boost effects
  // Because averge since start will not be accurate
  function startNewEpoch() public {
    require(_storage.epochStartBlock() + 5760 < block.number); // about 3 days.
    _storage.setEpochRewards();
    _storage.setCumulativeRewardsSinceStart();
    _storage.setRewardsInThisEpoch(0, 0);
    _storage.setEpochCalculationStartBlock();
    emit NewEpoch(_storage.epoch());
  }

  // --------------------------------------------
  //                OWNER
  // --------------------------------------------

  // Adds additional RAM rewards
  function addRAMRewardsOwner(uint256 _amount) public onlyOwner {
    require(_storage.ram().transferFrom(msg.sender, address(this), _amount) && _amount > 0);
    _storage.addAdditionalRewards(_amount, false);
  }

  // Adds additional YGY rewards
  function addYGYRewardsOwner(uint256 _amount) public onlyOwner {
    require(_storage.ygy().transferFrom(msg.sender, address(this), _amount) && _amount > 0);
    _storage.addAdditionalRewards(_amount, true);
  }

  // --------------------------------------------
  //                  POOL
  // --------------------------------------------

  // Add a new token pool. Can only be called by the owner.
  // Note contract owner is meant to be a governance contract allowing RAM governance consensus
  function addPool(
    uint256 _allocPoint,
    IERC20 _token,
    bool _withdrawable
  ) public onlyOwner {
    massUpdatePools();
    _storage.addPool(_allocPoint, _token, _withdrawable);
  }

  // Update the given pool's RAMs allocation point. Can only be called by the owner.
  // Note contract owner is meant to be a governance contract allowing RAM governance consensus
  function set(
    uint256 _pid,
    uint256 _allocPoint,
    bool _withdrawable
  ) public onlyOwner {
    massUpdatePools();
    _storage.setPool(_pid, _allocPoint, _withdrawable);
  }

  // Function that adds pending rewards, called by the RAM token.
  function addPendingRewards(uint256 _amount) external {
    require(msg.sender == address(_storage.ram()));
    _storage.addPendingRewards(_amount);
  }

  // Update reward variables of the given pool to be up-to-date.
  function updatePool(uint256 _pid) internal returns (uint256 ramRewardsWhole, uint256 ygyRewardsWhole) {
    YGYStorageV1.PoolInfo memory pool = PoolHelper.getPool(_pid, _storage);

    uint256 tokenSupply = pool.token.balanceOf(address(this));
    if (tokenSupply == 0) {
      return (0, 0);
    }
    uint256 effectivePoolStakedSupply = tokenSupply.add(pool.effectiveAdditionalTokensFromBoosts);

    ramRewardsWhole = _storage.pendingRewards().mul(pool.allocPoint).div(_storage.totalAllocPoint());

    // Ram rewards
    uint256 ramRewardFee = ramRewardsWhole.mul(DEV_FEE).div(10000);
    pending_DEV_rewards = pending_DEV_rewards.add(ramRewardFee);

    // Ygy rewards should be zero most of the time running.
    uint256 pendingYGYRewards = _storage.pendingYGYRewards();
    if (pendingYGYRewards > 0) {
      ygyRewardsWhole = pendingYGYRewards.mul(pool.allocPoint).div(_storage.totalAllocPoint());
      uint256 ygyRewardFee = ygyRewardsWhole.mul(DEV_FEE).div(10000);
      pending_DEV_YGY_rewards = pending_DEV_YGY_rewards.add(ygyRewardFee);
      pool.accYGYPerShare = pool.accYGYPerShare.add(ygyRewardsWhole.sub(ygyRewardFee).mul(1e12).div(effectivePoolStakedSupply));
    }

    // Update shares
    pool.accRAMPerShare = pool.accRAMPerShare.add(ramRewardsWhole.sub(ramRewardFee).mul(1e12).div(effectivePoolStakedSupply));
    _storage.updatePoolInfo(_pid, pool);
  }

  // Deposit tokens to RamVault for RAM allocation.
  function deposit(uint256 _pid, uint256 _amount) public {
    YGYStorageV1.PoolInfo memory pool = PoolHelper.getPool(_pid, _storage);
    YGYStorageV1.UserInfo memory user = UserHelper.getUser(_pid, msg.sender, _storage);
    // Pay the user
    updateAndPayOutPending(_pid, msg.sender);

    // save gas
    if (_amount > 0) {
      pool.token.transferFrom(address(msg.sender), address(this), _amount);
      user.amount = user.amount.add(_amount);

      // Users that have bought multipliers will have an extra balance added to their stake according to the boost multiplier.
      if (user.boostAmount > 0 || user.boostLevel > 0) {
        user.adjustEffectiveStake(pool, msg.sender, 0, false, _storage);
      }
    }

    user.updateDebts(pool);
    _storage.updateUserInfo(_pid, msg.sender, user);
    _storage.updatePoolInfo(_pid, pool);
    emit Deposit(msg.sender, _pid, _amount);
  }

  function claimRewards(uint256 _pid) external {
    YGYStorageV1.PoolInfo memory pool = PoolHelper.getPool(_pid, _storage);
    YGYStorageV1.UserInfo memory user = UserHelper.getUser(_pid, msg.sender, _storage);

    // Adjust the stake since user might have not acted after an epoch change and got boost amounts reduced
    if (user.boostAmount > 0) {
      user.adjustEffectiveStake(pool, msg.sender, 0, false, _storage);
    }
    updateAndPayOutPending(_pid, msg.sender);

    user.updateDebts(pool);
    _storage.updateUserInfo(_pid, msg.sender, user);
    _storage.updatePoolInfo(_pid, pool);
    emit RewardPaid(_pid, msg.sender);
  }

  // Test coverage
  // [x] Does user get the deposited amounts?
  // [x] Does user that its deposited for update correcty?
  // [x] Does the depositor get their tokens decreased
  function depositFor(
    address _depositFor,
    uint256 _pid,
    uint256 _amount
  ) public {
    // requires no allowances
    YGYStorageV1.PoolInfo memory pool = PoolHelper.getPool(_pid, _storage);
    YGYStorageV1.UserInfo memory user = UserHelper.getUser(_pid, _depositFor, _storage);

    // Pay the user
    updateAndPayOutPending(_pid, _depositFor);

    // Update the balances of person that amount is being deposited for
    if (_amount > 0) {
      pool.token.transferFrom(msg.sender, address(this), _amount);
      user.amount = user.amount.add(_amount); // This is depositedFor address

      // Users that have bought multipliers will have an extra balance added to their stake according to the boost multiplier.
      if (user.boostAmount > 0 || user.boostLevel > 0) {
        user.adjustEffectiveStake(pool, _depositFor, 0, false, _storage);
      }
    }

    user.updateDebts(pool);
    _storage.updateUserInfo(_pid, _depositFor, user);
    _storage.updatePoolInfo(_pid, pool);
    emit Deposit(_depositFor, _pid, _amount);
  }

  // Test coverage
  // [x] Does allowance update correctly?
  function setAllowanceForPoolToken(
    address spender,
    uint256 _pid,
    uint256 value
  ) public {
    _storage.setPoolAllowance(_pid, msg.sender, spender, value);
    emit Approval(msg.sender, spender, _pid, value);
  }

  // Test coverage
  // [x] Does allowance decrease?
  // [x] Do oyu need allowance
  // [x] Withdraws to correct address
  function withdrawFrom(
    address owner,
    uint256 _pid,
    uint256 _amount
  ) public {
    uint256 allowance = _storage.poolAllowance(_pid, owner, msg.sender);
    require(allowance >= _amount, "No allowance");
    _storage.setPoolAllowance(_pid, owner, msg.sender, allowance.sub(_amount));
    _withdraw(_pid, _amount, owner, msg.sender);
  }

  // Withdraw  tokens from RamVault.
  function withdraw(uint256 _pid, uint256 _amount) public {
    _withdraw(_pid, _amount, msg.sender, msg.sender);
  }

  // Low level withdraw function
  function _withdraw(
    uint256 _pid,
    uint256 _amount,
    address from,
    address to
  ) internal {
    YGYStorageV1.PoolInfo memory pool = PoolHelper.getPool(_pid, _storage);
    require(pool.withdrawable, "Not withdrawable");
    YGYStorageV1.UserInfo memory user = UserHelper.getUser(_pid, from, _storage);

    require(user.amount >= _amount, "Withdraw amount exceeds balance");
    updateAndPayOutPending(_pid, from); // Update balances of from, this is not withdrawal but claiming RAM farmed

    if (_amount > 0) {
      user.amount = user.amount.sub(_amount);
      pool.token.safeTransfer(address(to), _amount);

      // Users who have bought multipliers will have their accounting balances readjusted.
      if (user.boostAmount > 0 || user.boostLevel > 0) {
        user.adjustEffectiveStake(pool, from, 0, true, _storage);
      }
    }

    user.updateDebts(pool);
    _storage.updateUserInfo(_pid, msg.sender, user);
    _storage.updatePoolInfo(_pid, pool);
    emit Withdraw(to, _pid, _amount);
  }

  function massUpdatePools() public {
    uint256 allRewards;
    uint256 allYGYRewards;
    for (uint256 pid = 0; pid < _storage.getPoolLength(); ++pid) {
      (uint256 ramWholeReward, uint256 ygyWholeReward) = updatePool(pid);
      allRewards = allRewards.add(ramWholeReward);
      allYGYRewards = allYGYRewards.add(ygyWholeReward);
    }

    _storage.updatePoolRewards(allRewards, allYGYRewards);
  }

  function checkRewards(uint256 _pid, address _user) public view returns (uint256 pendingRAM, uint256 pendingYGY) {
    return _storage.checkRewards(_pid, _user);
  }

  function updateAndPayOutPending(uint256 _pid, address _from) internal {
    massUpdatePools();

    (uint256 pendingRAM, uint256 pendingYGY) = checkRewards(_pid, _from);
    if (pendingRAM > 0) {
      safeRamTransfer(_from, pendingRAM);
    }
    if (pendingYGY > 0) {
      safeYgyTransfer(_from, pendingYGY);
    }
  }

  // Withdraw without caring about rewards. EMERGENCY ONLY.
  // !Caution this will remove all your pending rewards!
  function emergencyWithdraw(uint256 _pid) public {
    YGYStorageV1.PoolInfo memory pool = PoolHelper.getPool(_pid, _storage);
    require(pool.withdrawable, "Pool not withdrawable");
    YGYStorageV1.UserInfo memory user = UserHelper.getUser(_pid, msg.sender, _storage);
    pool.token.safeTransfer(address(msg.sender), user.amount);
    emit EmergencyWithdraw(msg.sender, _pid, user.amount);
    user.amount = 0;
    user.boostAmount = 0;
    user.rewardDebt = 0;
    user.rewardDebtYGY = 0;
    _storage.updateUserInfo(_pid, msg.sender, user);
    _storage.updatePoolInfo(_pid, pool);
    // No mass update dont update pending rewards
  }

  // --------------------------------------------
  //                  BOOST
  // --------------------------------------------

  // Purchase a multiplier level for an individual user for an individual pool, same level cannot be purchased twice.
  function purchase(uint256 _pid, uint256 _level) external {
    YGYStorageV1.PoolInfo memory pool = PoolHelper.getPool(_pid, _storage);
    YGYStorageV1.UserInfo memory user = UserHelper.getUser(_pid, msg.sender, _storage);

    require(_level > user.boostLevel && _level <= 4);

    // Cost will be reduced by the amount already spent on multipliers.
    uint256 cost = _storage.getBoostLevelCost(_level);
    uint256 finalCost = cost.sub(user.spentMultiplierTokens);

    // Transfer RAM tokens to the contract
    require(_storage.ram().transferFrom(msg.sender, address(this), finalCost));

    // Update balances and level
    user.spentMultiplierTokens = user.spentMultiplierTokens.add(finalCost);
    user.boostLevel = _level;

    // If user has staked balances, then set their new accounting balance
    if (user.amount > 0) {
      // Get the new multiplier
      user.adjustEffectiveStake(pool, msg.sender, _level, false, _storage);
    }

    _storage.updateUserInfo(_pid, msg.sender, user);
    _storage.updatePoolInfo(_pid, pool);
    _storage.setBoostFees(finalCost, true);
    emit Boost(msg.sender, _pid, _level, false);
  }

  // Distributes boost fees to devs and protocol
  function distributeFees() public {
    // Reset taxes to 0 before distributing any funds
    _storage.setBoostFees(0, false);

    // Distribute taxes to regenerator and team 50/50%
    uint256 halfDistAmt = _storage.boostFees().div(2);
    if (halfDistAmt > 0) {
      // 50% to regenerator
      require(_storage.ram().transfer(regeneratoraddr, halfDistAmt));
      // 70% of the other 50% to devs
      uint256 devDistAmt = halfDistAmt.mul(70).div(100);
      if (devDistAmt > 0) {
        require(_storage.ram().transfer(devaddr, devDistAmt));
      }
      // 30% of the other 50% to team
      uint256 teamDistAmt = halfDistAmt.mul(30).div(100);
      if (teamDistAmt > 0) {
        require(_storage.ram().transfer(teamaddr, teamDistAmt));
      }
    }
  }

  // --------------------------------------------
  //                  Utils
  // --------------------------------------------

  // Sets the dev fee for this contract
  // defaults at 7.24%
  // Note contract owner is meant to be a governance contract allowing RAM governance consensus
  uint16 DEV_FEE;

  function setDevFee(uint16 _DEV_FEE) public onlyOwner {
    require(_DEV_FEE <= 1000, "Max 10%");
    DEV_FEE = _DEV_FEE;
  }

  uint256 pending_DEV_rewards;
  uint256 pending_DEV_YGY_rewards;

  // function that lets owner/governance contract
  // approve allowance for any token inside this contract
  // This means all future UNI like airdrops are covered
  // And at the same time allows us to give allowance to strategy contracts.
  // Upcoming cYFI etc vaults strategy contracts will  se this function to manage and farm yield on value locked
  function setStrategyContractOrDistributionContractAllowance(
    address tokenAddress,
    uint256 _amount,
    address contractAddress
  ) external {
    require(isContract(contractAddress) && _superAdmin == _msgSender());
    require(block.number > _storage.RAMVaultStartBlock().add(95_000), "Gov not ready");
    IERC20(tokenAddress).approve(contractAddress, _amount);
  }

  function isContract(address addr) internal view returns (bool) {
    uint256 size;
    assembly {
      size := extcodesize(addr)
    }
    return size > 0;
  }

  function safeRamTransfer(address _to, uint256 _amount) internal {
    uint256 ramBal = _storage.ram().balanceOf(address(this));

    if (_amount > ramBal) {
      _storage.ram().transfer(_to, ramBal);
    } else {
      _storage.ram().transfer(_to, _amount);
    }
    transferRAMDevFee();
    _storage.setRAMBalance(_storage.ram().balanceOf(address(this)));
  }

  function safeYgyTransfer(address _to, uint256 _amount) internal {
    uint256 ygyBal = _storage.ygy().balanceOf(address(this));

    if (_amount > ygyBal) {
      _storage.ygy().transfer(_to, ygyBal);
    } else {
      _storage.ygy().transfer(_to, _amount);
    }
    _storage.setYGYBalance(_storage.ygy().balanceOf(address(this)));
    transferYGYDevFee();
  }

  function transferRAMDevFee() public {
    if (pending_DEV_rewards > 0) {
      uint256 devDistAmt;
      uint256 teamDistAmt;
      uint256 ramBal = _storage.ram().balanceOf(address(this));
      if (pending_DEV_rewards > ramBal) {
        devDistAmt = ramBal.mul(70).div(100);
        teamDistAmt = ramBal.mul(30).div(100);
      } else {
        devDistAmt = pending_DEV_rewards.mul(70).div(100);
        teamDistAmt = pending_DEV_rewards.mul(30).div(100);
      }

      if (devDistAmt > 0) {
        _storage.ram().transfer(devaddr, devDistAmt);
      }
      if (teamDistAmt > 0) {
        _storage.ram().transfer(teamaddr, teamDistAmt);
      }

      _storage.setRAMBalance(_storage.ram().balanceOf(address(this)));
      pending_DEV_rewards = 0;
    }
  }

  function transferYGYDevFee() public {
    if (pending_DEV_YGY_rewards > 0) {
      uint256 devDistAmt;
      uint256 teamDistAmt;
      uint256 ygyBal = _storage.ygy().balanceOf(address(this));
      if (pending_DEV_YGY_rewards > ygyBal) {
        devDistAmt = ygyBal.mul(70).div(100);
        teamDistAmt = ygyBal.mul(30).div(100);
      } else {
        devDistAmt = pending_DEV_YGY_rewards.mul(70).div(100);
        teamDistAmt = pending_DEV_YGY_rewards.mul(30).div(100);
      }

      if (devDistAmt > 0) {
        _storage.ygy().transfer(devaddr, devDistAmt);
      }
      if (teamDistAmt > 0) {
        _storage.ygy().transfer(teamaddr, teamDistAmt);
      }

      _storage.setYGYBalance(_storage.ygy().balanceOf(address(this)));
      pending_DEV_YGY_rewards = 0;
    }
  }

  function setAddresses(
    address _devaddr,
    address _teamaddr,
    address _regeneratoraddr
  ) external onlyOwner {
    devaddr = _devaddr;
    teamaddr = _teamaddr;
    regeneratoraddr = _regeneratoraddr;
  }

  address private _superAdmin;

  event SuperAdminTransfered(address previousOwner, address newOwner);

  function superAdmin() public view returns (address) {
    return _superAdmin;
  }

  function burnSuperAdmin() public virtual {
    require(_superAdmin == _msgSender());
    _superAdmin = address(0);
    emit SuperAdminTransfered(_superAdmin, address(0));
  }

  function newSuperAdmin(address newOwner) public virtual {
    require(_superAdmin == _msgSender());
    require(newOwner != address(0));
    _superAdmin = newOwner;
    emit SuperAdminTransfered(_superAdmin, newOwner);
  }
}
