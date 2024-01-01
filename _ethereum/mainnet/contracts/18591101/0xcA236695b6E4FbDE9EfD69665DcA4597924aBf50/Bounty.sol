// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./ERC20Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./IAddressContract.sol";
import "./SafeERC20Upgradeable.sol";
import "./ERC20PermitUpgradeable.sol";
import "./ERC20VotesUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./SafeCastUpgradeable.sol";

contract Bounty is
  ERC20Upgradeable,
  ERC20PermitUpgradeable,
  ERC20VotesUpgradeable,
  OwnableUpgradeable,
  PausableUpgradeable
{
  // libraries
  using SafeMathUpgradeable for uint256;
  using SafeERC20Upgradeable for IERC20Upgradeable;

  // state vars
  // pirate token
  IERC20Upgradeable public PIRATE;
  // admin address
  address public adminAddress;
  // Bonus muliplier for early PIRATE makers.
  uint256 public BONUS_MULTIPLIER;
  // // Number of top staker stored
  // uint256 public topStakerNumber;
  // Total allocation points. Must be the sum of all allocation points in all pools.
  uint256 public totalAllocPoint;
  // The block number when reward distribution start.
  uint256 public startBlock;
  // total PIRATE staked
  uint256 public totalPIRATEStaked;
  // total PIRATE used for purchase land
  uint256 public totalPirateUsedForPurchase;
  // Info of each user that stakes LP tokens.
  mapping(uint256 => mapping(address => UserInfo)) public userInfo;
  // mapping(uint256 => HighestAstaStaker[]) public highestStakerInPool;
  // Info of each pool.
  PoolInfo[] public poolInfo;

  // //highest staked users
  // struct HighestAstaStaker {
  //     uint256 deposited;
  //     address addr;
  // }

  // Info of each user.
  struct UserInfo {
    uint256 amount; // How many LP tokens the user has provided.
    uint256 rewarbountyDebt; // Reward debt in PIRATE.
  }

  // Info of each pool.
  struct PoolInfo {
    IERC20Upgradeable lpToken; // Address of LP token contract.//
    uint256 allocPoint; // How many allocation points assigned to this pool.
    uint256 lastRewardBlock; // Last block number that Pirate distribution occurs.
    uint256 accPiratePerShare; // Accumulated Pirates per share, times 1e12. See below.
    uint256 lastTotalPirateReward; // last total rewards
    uint256 lastPirateRewardBalance; // last Pirate rewards tokens
    uint256 totalPirateReward; // total Pirate rewards tokens
  }

  // events
  event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
  event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
  event EmergencyWithdraw(
    address indexed user,
    uint256 indexed pid,
    uint256 amount
  );
  event AdminUpdated(address newAdmin);

  function initialize(
    IERC20Upgradeable _pirate,
    address _adminAddress,
    uint256 _startBlock
  ) external initializer {
    __ERC20_init_unchained("BOUNTY", "BOUNTY");
    __ERC20Permit_init("BOUNTY");
    __ERC20Votes_init_unchained();
    __Ownable_init_unchained();
    __Pausable_init_unchained();
    require(_adminAddress != address(0), "initialize: Zero address");
    PIRATE = _pirate;
    adminAddress = _adminAddress;
    startBlock = _startBlock;
    BONUS_MULTIPLIER = 1;
  }

  function setContractAddresses(
    IAddressContract _contractFactory
  ) external onlyOwner {
    PIRATE = IERC20Upgradeable(_contractFactory.getPirate());
  }

  // Add a new lp to the pool. Can only be called by the owner.
  // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
  function add(
    uint256 _allocPoint,
    IERC20Upgradeable _lpToken,
    bool _withUpdate
  ) external onlyOwner {
    if (_withUpdate) {
      massUpdatePools();
    }
    uint256 lastRewardBlock = block.number > startBlock
      ? block.number
      : startBlock;
    totalAllocPoint = totalAllocPoint.add(_allocPoint);
    poolInfo.push(
      PoolInfo({
        lpToken: _lpToken,
        allocPoint: _allocPoint,
        lastRewardBlock: lastRewardBlock,
        accPiratePerShare: 0,
        lastTotalPirateReward: 0,
        lastPirateRewardBalance: 0,
        totalPirateReward: 0
      })
    );
  }

  // Update the given pool's PIRATE allocation point. Can only be called by the owner.
  function set(
    uint256 _pid,
    uint256 _allocPoint,
    bool _withUpdate
  ) external onlyOwner {
    if (_withUpdate) {
      massUpdatePools();
    }
    totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(
      _allocPoint
    );
    poolInfo[_pid].allocPoint = _allocPoint;
  }

  // Deposit PIRATE tokens to MasterChef.
  function deposit(uint256 _pid, uint256 _amount) external {
    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][msg.sender];
    updatePool(_pid);
    if (user.amount > 0) {
      uint256 pirateReward = user
        .amount
        .mul(pool.accPiratePerShare)
        .div(1e12)
        .sub(user.rewarbountyDebt);
      pool.lpToken.safeTransfer(msg.sender, pirateReward);
      pool.lastPirateRewardBalance = pool.lpToken.balanceOf(address(this)).sub(
        totalPIRATEStaked.sub(totalPirateUsedForPurchase)
      );
    }
    pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
    totalPIRATEStaked = totalPIRATEStaked.add(_amount);
    user.amount = user.amount.add(_amount);
    user.rewarbountyDebt = user.amount.mul(pool.accPiratePerShare).div(1e12);
    // addHighestStakedUser(_pid, user.amount, msg.sender);
    _mint(msg.sender, _amount);
    emit Deposit(msg.sender, _pid, _amount);
  }

  // Earn PIRATE tokens to MasterChef.
  function claimPIRATE(uint256 _pid) external {
    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][msg.sender];
    updatePool(_pid);

    uint256 pirateReward = user
      .amount
      .mul(pool.accPiratePerShare)
      .div(1e12)
      .sub(user.rewarbountyDebt);
    pool.lpToken.safeTransfer(msg.sender, pirateReward);
    pool.lastPirateRewardBalance = pool.lpToken.balanceOf(address(this)).sub(
      totalPIRATEStaked.sub(totalPirateUsedForPurchase)
    );

    user.rewarbountyDebt = user.amount.mul(pool.accPiratePerShare).div(1e12);
  }

  function withdraw(uint256 _pid, uint256 _amount) external {
    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][msg.sender];
    require(user.amount >= _amount, "withdraw: not good");
    updatePool(_pid);

    uint256 pirateReward = user
      .amount
      .mul(pool.accPiratePerShare)
      .div(1e12)
      .sub(user.rewarbountyDebt);
    pool.lpToken.safeTransfer(msg.sender, pirateReward);
    pool.lastPirateRewardBalance = pool.lpToken.balanceOf(address(this)).sub(
      totalPIRATEStaked.sub(totalPirateUsedForPurchase)
    );

    user.amount = user.amount.sub(_amount);
    totalPIRATEStaked = totalPIRATEStaked.sub(_amount);
    user.rewarbountyDebt = user.amount.mul(pool.accPiratePerShare).div(1e12);
    pool.lpToken.safeTransfer(address(msg.sender), _amount);
    // removeHighestStakedUser(_pid, user.amount, msg.sender);
    _burn(msg.sender, _amount);
    emit Withdraw(msg.sender, _pid, _amount);
  }

  // Safe PIRATE transfer function to admin.
  function accessPIRATETokens(
    uint256 _pid,
    address _to,
    uint256 _amount
  ) external {
    require(msg.sender == adminAddress, "sender must be admin address");
    require(
      totalPIRATEStaked.sub(totalPirateUsedForPurchase) >= _amount,
      "Amount must be less than staked PIRATE amount"
    );
    PoolInfo storage pool = poolInfo[_pid];
    uint256 PirateBal = pool.lpToken.balanceOf(address(this));
    if (_amount > PirateBal) {
      require(pool.lpToken.transfer(_to, PirateBal), "err in transfer");
      totalPirateUsedForPurchase = totalPirateUsedForPurchase.add(PirateBal);
      emit EmergencyWithdraw(_to, _pid, PirateBal);
    } else {
      require(pool.lpToken.transfer(_to, _amount), "err in transfer");
      totalPirateUsedForPurchase = totalPirateUsedForPurchase.add(_amount);
      emit EmergencyWithdraw(_to, _pid, _amount);
    }
  }

  // Update admin address by the previous admin.
  function admin(address _adminAddress) external {
    require(_adminAddress != address(0), "admin: Zero address");
    require(msg.sender == adminAddress, "admin: wut?");
    adminAddress = _adminAddress;
    emit AdminUpdated(_adminAddress);
  }

  function poolLength() external view returns (uint256) {
    return poolInfo.length;
  }

  // View function to see pending PIRATEs on frontend.
  function pendingPIRATE(
    uint256 _pid,
    address _user
  ) external view returns (uint256) {
    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][_user];
    uint256 accPiratePerShare = pool.accPiratePerShare;
    uint256 lpSupply = totalPIRATEStaked;
    if (block.number > pool.lastRewardBlock && lpSupply != 0) {
      uint256 rewardBalance = pool.lpToken.balanceOf(address(this)).sub(
        totalPIRATEStaked.sub(totalPirateUsedForPurchase)
      );
      uint256 _totalReward = rewardBalance.sub(pool.lastPirateRewardBalance);
      accPiratePerShare = accPiratePerShare.add(
        _totalReward.mul(1e12).div(lpSupply)
      );
    }
    return
      user.amount.mul(accPiratePerShare).div(1e12).sub(user.rewarbountyDebt);
  }

  // Update reward variables for all pools. Be careful of gas spending!
  function massUpdatePools() public {
    uint256 length = poolInfo.length;
    for (uint256 pid = 0; pid < length; ++pid) {
      updatePool(pid);
    }
  }

  // Update reward variables of the given pool to be up-to-date.
  function updatePool(uint256 _pid) public {
    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][msg.sender];

    if (block.number <= pool.lastRewardBlock) {
      return;
    }
    uint256 rewardBalance = pool.lpToken.balanceOf(address(this)).sub(
      totalPIRATEStaked.sub(totalPirateUsedForPurchase)
    );
    uint256 _totalReward = pool.totalPirateReward.add(
      rewardBalance.sub(pool.lastPirateRewardBalance)
    );
    pool.lastPirateRewardBalance = rewardBalance;
    pool.totalPirateReward = _totalReward;

    uint256 lpSupply = totalPIRATEStaked;
    if (lpSupply == 0) {
      pool.lastRewardBlock = block.number;
      pool.accPiratePerShare = 0;
      pool.lastTotalPirateReward = 0;
      user.rewarbountyDebt = 0;
      pool.lastPirateRewardBalance = 0;
      pool.totalPirateReward = 0;
      return;
    }

    uint256 reward = _totalReward.sub(pool.lastTotalPirateReward);
    pool.accPiratePerShare = pool.accPiratePerShare.add(
      reward.mul(1e12).div(lpSupply)
    );
    pool.lastTotalPirateReward = _totalReward;
  }

  // Return reward multiplier over the given _from to _to block.
  function getMultiplier(
    uint256 _from,
    uint256 _to
  ) public view returns (uint256) {
    if (_to >= _from) {
      return _to.sub(_from).mul(BONUS_MULTIPLIER);
    } else {
      return _from.sub(_to);
    }
  }

  function _mint(
    address to,
    uint256 amount
  ) internal override(ERC20Upgradeable, ERC20VotesUpgradeable) {
    super._mint(to, amount);
  }

  function _burn(
    address account,
    uint256 amount
  ) internal override(ERC20Upgradeable, ERC20VotesUpgradeable) {
    super._burn(account, amount);
  }

  function _afterTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal override(ERC20Upgradeable, ERC20VotesUpgradeable) {
    ERC20VotesUpgradeable._afterTokenTransfer(from, to, amount);
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal override {
    if (from == address(0) || to == address(0)) {
      super._beforeTokenTransfer(from, to, amount);
    } else {
      revert("Non transferable token");
    }
  }

  function _delegate(address delegator, address delegatee) internal override {
    // require(!checkHighestStaker(0, delegator),"Top staker cannot delegate");
    super._delegate(delegator, delegatee);
  }

  function clock() public view override returns (uint48) {
    return SafeCastUpgradeable.toUint48(block.timestamp);
  }

  function CLOCK_MODE() public view override returns (string memory) {
    require(clock() == block.timestamp, "ERC20Votes: broken clock mode");
    return "mode=blocktimestamp&from=default";
  }
}
