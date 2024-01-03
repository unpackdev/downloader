pragma solidity ^0.6.0;

import "./IERC20.sol";
import "./AccessControl.sol";
import "./SafeERC20.sol";
import "./IMultiplier.sol";


interface IZZZToken is IERC20 {
  function txFee() external returns (uint256);
}

// NAP Vault distributes fees equally amongst staked vaults
// Have fun reading it. Hopefully it's bug-free. God bless.
contract Vault is AccessControlUpgradeSafe {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");

  IMultiplier public multiplier;
  // Info of each user.
  struct UserInfo {
    uint256 amount; // How many tokens the user has provided.
    uint256 ZZZRewardDebt; // Reward debt. See explanation below.
    uint256 NAPRewardDebt; // Reward debt. See explanation below.
    uint256 timelockEnd;
    uint256 timelockBoost;
    // Epoch -> User boost
    mapping(uint256 => uint256) boost;
    // Whenever a user deposits or withdraws  tokens to a vault. Here's what happens:
    //   1. The vault's `accNAPPerShare` gets updated.
    //   2. User receives the pending reward sent to his/her address.
    //   3. User's `amount` gets updated.
    //   4. User's `rewardDebt` gets updated.
  }

  // Info of each vault.
  struct VaultInfo {
    IERC20 token; // Staking token contract.
    uint256 allocPointZZZ; // How many allocation points assigned to this vault. NAPs to distribute per block.
    uint256 allocPointNAP; // How many allocation points assigned to this vault. NAPs to distribute per block.
    uint256 accZZZPerShare; // Accumulated NAPs per share, times 1e12. See below.
    uint256 accNAPPerShare; // Accumulated NAPs per share, times 1e12. See below.
    bool withdrawable; // Is this vault withdrawable?
    mapping(address => mapping(address => uint256)) allowance; //  Vault allowances
    // Epoch -> Pools total effective
    mapping(uint256 => uint256) totalEffective;
    uint256 totalTimelockBoost;
  }

  // Tokens
  IZZZToken public nap;
  IZZZToken public zzz;
  IERC20 public zzzeth;
  IERC20 public zzznap;
  address public axioms;

  // Treasury address.
  address public treasury;

  // Info of each vault.
  VaultInfo[] public vaultInfo;

  // Info of each user in vaults that stakes tokens.
  mapping(uint256 => mapping(address => UserInfo)) public userInfo;

  // Total allocation points. Must be the sum of all allocation points in all vaults.
  uint256 public totalAllocPointZZZ;
  uint256 public totalAllocPointNAP;

  // Pending rewards awaiting anyone to massUpdate
  uint256 public pendingZZZRewards;
  uint256 public pendingNAPRewards;

  // Starting blocks
  uint256 public contractStartBlock;
  uint256 public epochCalculationStartBlock;

  // Rewards since start of this contract
  uint256 public ZZZcumulativeRewardsSinceStart;
  uint256 public NAPcumulativeRewardsSinceStart;

  // Rewards since start of epoch (more precise)
  uint256 public ZZZrewardsInThisEpoch;
  uint256 public NAPrewardsInThisEpoch;

  // Current epoch
  uint256 public epoch;

  uint256 public epochPeriod;
  uint256 public timelockGracePeriod;
  uint256 public devGracePeriod;

  function modifyPeriods(uint256 _epochPeriod, uint256 _timelockGracePeriod) external {
    require(hasRole(GOVERNANCE_ROLE, _msgSender()), "!Gov");
    epochPeriod = _epochPeriod;
    timelockGracePeriod = _timelockGracePeriod;
  }

  function getUserBoost(uint256 _pid, address _user) external view returns (uint256) {
    UserInfo storage user = userInfo[_pid][_user];
    return user.boost[epoch].add(user.timelockBoost);
  }

  // Returns fees generated since start of this contract
  function averageFeesPerBlockSinceStart() external view returns (uint256 ZZZaveragePerBlock, uint256 NAPaveragePerBlock) {
    ZZZaveragePerBlock = ZZZcumulativeRewardsSinceStart.add(ZZZrewardsInThisEpoch).div(block.number.sub(contractStartBlock));
    NAPaveragePerBlock = NAPcumulativeRewardsSinceStart.add(NAPrewardsInThisEpoch).div(block.number.sub(contractStartBlock));
  }

  // Returns averge fees in this epoch
  function averageFeesPerBlockEpoch() external view returns (uint256 ZZZaveragePerBlock, uint256 NAPaveragePerBlock) {
    ZZZaveragePerBlock = ZZZrewardsInThisEpoch.div(block.number.sub(epochCalculationStartBlock));
    NAPaveragePerBlock = NAPrewardsInThisEpoch.div(block.number.sub(epochCalculationStartBlock));
  }

  // For easy graphing historical epoch rewards
  mapping(uint256 => uint256) public ZZZepochRewards;
  mapping(uint256 => uint256) public NAPepochRewards;

  // Starts a new calculation epoch
  // Reset boosts
  function startNewEpoch() public {
    require(epochCalculationStartBlock + epochPeriod < block.number, "!Epochready"); // About a week
    ZZZepochRewards[epoch] = ZZZrewardsInThisEpoch;
    NAPepochRewards[epoch] = NAPrewardsInThisEpoch;
    ZZZcumulativeRewardsSinceStart = ZZZcumulativeRewardsSinceStart.add(ZZZrewardsInThisEpoch);
    NAPcumulativeRewardsSinceStart = NAPcumulativeRewardsSinceStart.add(NAPrewardsInThisEpoch);
    ZZZrewardsInThisEpoch = 0;
    NAPrewardsInThisEpoch = 0;
    epochCalculationStartBlock = block.number;
    ++epoch;
  }

  event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
  event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
  event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
  event Approval(address indexed owner, address indexed spender, uint256 _pid, uint256 value);

  function initialize(
    IZZZToken _zzz,
    IERC20 _zzzeth,
    IZZZToken _nap,
    IERC20 _zzznap,
    address _gov,
    address _multiplier,
    address _axioms,
    address _treasury
  ) public initializer {
    __AccessControl_init();
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _setupRole(GOVERNANCE_ROLE, _msgSender());
    _setupRole(GOVERNANCE_ROLE, _gov);
    nap = _nap;
    zzznap = _zzznap;
    zzzeth = _zzzeth;
    zzz = _zzz;
    axioms = _axioms;
    treasury = _treasury;
    contractStartBlock = block.number;
    addVault(75, 50, zzz, true); // Creates ZZZ Vault
    addVault(125, 75, zzzeth, true); // Creates ZZZETH Vault
    addVault(75, 125, zzznap, true); // Creates ZZZ/NAP Vault
    addVault(20, 50, nap, true); // Creates NAP Vault
    multiplier = IMultiplier(_multiplier);
    timelockGracePeriod = 1 days;
    epochPeriod = 50000; // about a week
    devGracePeriod = block.timestamp + 4 weeks;
    epochCalculationStartBlock = block.number;
  }

  function vaultAmount() external view returns (uint256) {
    return vaultInfo.length;
  }

  // Add a new token vault. Can only be called by the owner.
  // Note contract owner is meant to be a governance contract allowing NAP governance consensus
  function addVault(
    uint256 _allocPointZZZ,
    uint256 _allocPointNAP,
    IERC20 _token,
    bool _withdrawable
  ) public {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) || hasRole(GOVERNANCE_ROLE, _msgSender()), "!Admin");

    uint256 length = vaultInfo.length;
    for (uint256 pid = 0; pid < length; ++pid) {
      require(vaultInfo[pid].token != _token, "Error vault already added");
    }

    totalAllocPointZZZ = totalAllocPointZZZ.add(_allocPointZZZ);
    totalAllocPointNAP = totalAllocPointNAP.add(_allocPointNAP);

    vaultInfo.push(
      VaultInfo({
        token: _token,
        allocPointZZZ: _allocPointZZZ,
        allocPointNAP: _allocPointNAP,
        accNAPPerShare: 0,
        accZZZPerShare: 0,
        withdrawable: _withdrawable,
        totalTimelockBoost: 0
      })
    );
  }

  // Update the given vault's allocation points. Can only be called by gov / owner.
  // Note contract owner is meant to be a governance contract allowing NAP governance consensus
  function modifyVault(
    uint256 _pid,
    uint256 _allocPointZZZ,
    uint256 _allocPointNAP
  ) public {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) || hasRole(GOVERNANCE_ROLE, _msgSender()), "!Admin");
    massUpdateVaults();
    totalAllocPointZZZ = totalAllocPointZZZ.sub(vaultInfo[_pid].allocPointZZZ).add(_allocPointZZZ);
    totalAllocPointNAP = totalAllocPointNAP.sub(vaultInfo[_pid].allocPointNAP).add(_allocPointNAP);
    vaultInfo[_pid].allocPointZZZ = _allocPointZZZ;
    vaultInfo[_pid].allocPointNAP = _allocPointNAP;
  }

  // Update the given vault's ability to withdraw tokens
  // Note contract owner is meant to be a governance contract allowing NAP gov(ernance consensus
  function setVaultWithdrawable(uint256 _pid, bool _withdrawable) public {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) || hasRole(GOVERNANCE_ROLE, _msgSender()), "!Admin");
    vaultInfo[_pid].withdrawable = _withdrawable;
  }

  // View function to see pending NAPs on frontend.
  function pendingRewards(uint256 _pid, address _user) external view returns (uint256 zzzRewards, uint256 napRewards) {
    VaultInfo storage vault = vaultInfo[_pid];
    UserInfo storage user = userInfo[_pid][_user];
    zzzRewards = user.amount.add(user.boost[epoch]).add(user.timelockBoost).mul(vault.accZZZPerShare).div(1e12).sub(user.ZZZRewardDebt);
    napRewards = user.amount.add(user.boost[epoch]).add(user.timelockBoost).mul(vault.accNAPPerShare).div(1e12).sub(user.NAPRewardDebt);
  }

  // Update reward vairables for all vaults. Be careful of gas spending!
  function massUpdateVaults() public {
    addPendingRewards();
    uint256 length = vaultInfo.length;
    uint256 allZZZRewards;
    uint256 allNAPRewards;
    for (uint256 vid = 0; vid < length; ++vid) {
      (uint256 ZZZRewardWhole, uint256 NAPRewardsWhole) = updateVault(vid);
      allZZZRewards = allZZZRewards.add(ZZZRewardWhole);
      allNAPRewards = allNAPRewards.add(NAPRewardsWhole);
    }

    pendingZZZRewards = pendingZZZRewards.sub(allZZZRewards);
    pendingNAPRewards = pendingNAPRewards.sub(allNAPRewards);
  }

  // Reward reserves
  uint256 public napReserve;
  uint256 public zzzReserve;

  // User deposits
  uint256 public userZZZ;
  uint256 public userNAP;

  /** @dev Reward tracking - since vaults receive fees by straight balance adjustments in the tokens just check for balances
   * This is publicly callable. It will be called on each interaction tho.
   */
  function addPendingRewards() public {
    // IF reserves are lower than balance - update them.
    uint256 newNAPRewards = nap.balanceOf(address(this)).sub(napReserve).sub(userNAP);
    uint256 newZZZRewards = zzz.balanceOf(address(this)).sub(zzzReserve).sub(userZZZ);

    // No rewards? Do nothing.
    if (newNAPRewards > 0) {
      napReserve = nap.balanceOf(address(this)).sub(userNAP);
      pendingNAPRewards = pendingNAPRewards.add(newNAPRewards);
      NAPrewardsInThisEpoch = NAPrewardsInThisEpoch.add(newNAPRewards);
    }

    // Applies for both.
    if (newZZZRewards > 0) {
      zzzReserve = zzz.balanceOf(address(this)).sub(userZZZ);
      pendingZZZRewards = pendingZZZRewards.add(newZZZRewards);
      ZZZrewardsInThisEpoch = ZZZrewardsInThisEpoch.add(newZZZRewards);
    }
  }

  // Update reward variables of the given vault to be up-to-date.
  function updateVault(uint256 _pid) internal returns (uint256 zzzRewardWhole, uint256 napRewardWhole) {
    VaultInfo storage vault = vaultInfo[_pid];

    uint256 tokenSupply = vault.token.balanceOf(address(this));
    if (tokenSupply == 0) {
      // avoids division by 0 errors
      return (0, 0);
    }

    uint256 effectiveSupply = tokenSupply.add(vault.totalEffective[epoch]).add(vault.totalTimelockBoost);

    zzzRewardWhole = pendingZZZRewards // Multiplies pending rewards by allocation point of this vault and then total allocation
      .mul(vault.allocPointZZZ) // getting the percent of total pending rewards this vault should get
      .div(totalAllocPointZZZ); // we can do this because vaults are only mass updated

    napRewardWhole = pendingNAPRewards // Multiplies pending rewards by allocation point of this vault and then total allocation
      .mul(vault.allocPointNAP) // getting the percent of total pending rewards this vault should get
      .div(totalAllocPointNAP); // we can do this because vaults are only mass updated

    vault.accNAPPerShare = vault.accNAPPerShare.add(napRewardWhole.mul(1e12).div(effectiveSupply));
    vault.accZZZPerShare = vault.accZZZPerShare.add(zzzRewardWhole.mul(1e12).div(effectiveSupply));
  }

  // Deposit tokens to Vault for allocation with a certain level.
  function deposit(uint256 _pid, uint256 _amount) public {
    VaultInfo storage vault = vaultInfo[_pid];
    UserInfo storage user = userInfo[_pid][msg.sender];

    massUpdateVaults();
    // Transfer pending rewards to user
    updateAndPayOutPending(vault, user, msg.sender);

    // Transfer in the amounts from user
    uint256 fee;
    uint256 amount;
    if (_amount > 0) {
      vault.token.transferFrom(address(msg.sender), address(this), _amount);
      if (address(vault.token) == address(zzz)) {
        fee = _amount.mul(zzz.txFee()).div(10000);
        amount = _amount.sub(fee);
        userZZZ = userZZZ.add(_amount.sub(fee));
      } else if (address(vault.token) == address(nap)) {
        fee = _amount.mul(nap.txFee()).div(10000);
        amount = _amount.sub(fee);
        userNAP = userNAP.add(_amount.sub(fee));
      } else {
        amount = _amount;
      }
      updateBoostAmounts(amount, _pid, false, vault, user);
      user.amount = user.amount.add(amount);
    }

    // Acccounting
    bool isTimelocked = isTimelocked(_pid, msg.sender);
    uint256 boostAmount = user.boost[epoch];
    uint256 timelockBoost = isTimelocked ? user.amount.mul(50).div(100) : 0;
    if (timelockBoost > 0) {
      user.timelockBoost = timelockBoost;
    }
    user.ZZZRewardDebt = user.amount.add(boostAmount).add(timelockBoost).mul(vault.accZZZPerShare).div(1e12);
    user.NAPRewardDebt = user.amount.add(boostAmount).add(timelockBoost).mul(vault.accNAPPerShare).div(1e12);
    emit Deposit(msg.sender, _pid, amount);
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
    VaultInfo storage vault = vaultInfo[_pid];
    UserInfo storage user = userInfo[_pid][_depositFor];

    massUpdateVaults();
    // Transfer pending tokens for the user who's being deposited for
    updateAndPayOutPending(vault, user, _depositFor); // Update the balances of person that amount is being deposited for

    // Transfer in the amounts from user
    uint256 fee;
    uint256 amount;
    if (_amount > 0) {
      vault.token.transferFrom(address(msg.sender), address(this), _amount);
      if (address(vault.token) == address(zzz)) {
        fee = _amount.mul(zzz.txFee()).div(10000);
        amount = _amount.sub(fee);
        userZZZ = userZZZ.add(_amount.sub(fee));
      } else if (address(vault.token) == address(nap)) {
        fee = _amount.mul(nap.txFee()).div(10000);
        amount = _amount.sub(fee);
        userNAP = userNAP.add(_amount.sub(fee));
      } else {
        amount = _amount;
      }
      updateBoostAmounts(amount, _pid, false, vault, user);
      user.amount = user.amount.add(amount);
    }

    bool isTimelocked = isTimelocked(_pid, _depositFor);
    uint256 boostAmount = user.boost[epoch];
    uint256 timelockBoost = isTimelocked ? user.amount.mul(50).div(100) : 0;
    if (timelockBoost > 0) {
      user.timelockBoost = timelockBoost;
    }
    user.ZZZRewardDebt = user.amount.add(boostAmount).add(timelockBoost).mul(vault.accZZZPerShare).div(1e12);
    user.NAPRewardDebt = user.amount.add(boostAmount).add(timelockBoost).mul(vault.accNAPPerShare).div(1e12);
    emit Deposit(_depositFor, _pid, _amount);
  }

  function isTimelocked(uint256 _pid, address _user) public view returns (bool) {
    return userInfo[_pid][_user].timelockEnd >= now;
  }

  // Timelock vault funds for 4 weeks - gaining a 50% effective boost
  function timelock(uint256 _pid) external {
    VaultInfo storage vault = vaultInfo[_pid];
    UserInfo storage user = userInfo[_pid][msg.sender];
    require(user.timelockEnd < now, "Old timelock still active");

    massUpdateVaults();
    // Transfer pending rewards to user
    updateAndPayOutPending(vault, user, msg.sender);

    user.timelockEnd = block.timestamp + 4 weeks;
    uint256 timelockBoost = user.amount.mul(50).div(100);
    user.timelockBoost = timelockBoost;

    vault.totalTimelockBoost = vault.totalTimelockBoost.add(timelockBoost);

    uint256 boostAmount = user.boost[epoch];
    user.ZZZRewardDebt = user.amount.add(boostAmount).add(timelockBoost).mul(vault.accZZZPerShare).div(1e12);
    user.NAPRewardDebt = user.amount.add(boostAmount).add(timelockBoost).mul(vault.accNAPPerShare).div(1e12);
  }

  function updateBoostAmounts(
    uint256 _amount,
    uint256 _pid,
    bool _isWithdraw,
    VaultInfo storage _vaultInfo,
    UserInfo storage _userInfo
  ) internal {
    // What user currently has boosted
    uint256 currentUserEffective = _userInfo.boost[epoch];

    // Get the new value being subtracted or added for the user and vault
    uint256 multi = multiplier.getTotalValueForUser(address(this), msg.sender, epoch, _pid);
    uint256 newBoost = _amount.mul(multi).div(1000);

    // Handle withdraws
    if (_isWithdraw) {
      // In case of underflow remove the whole balance.
      if (newBoost >= currentUserEffective) {
        _vaultInfo.totalEffective[epoch] = _vaultInfo.totalEffective[epoch].sub(currentUserEffective);
        _userInfo.boost[epoch] = 0;
      } else {
        // Otherwise just subtract from previous value.
        _vaultInfo.totalEffective[epoch] = _vaultInfo.totalEffective[epoch].sub(newBoost);
        _userInfo.boost[epoch] = currentUserEffective.sub(newBoost);
      }
    } else {
      // In case of deposits just add
      _vaultInfo.totalEffective[epoch] = _vaultInfo.totalEffective[epoch].add(newBoost);
      _userInfo.boost[epoch] = currentUserEffective.add(newBoost);
    }
  }

  // Test coverage
  // [x] Does allowance update correctly?
  function setAllowanceForVaultToken(
    address spender,
    uint256 _pid,
    uint256 value
  ) public {
    VaultInfo storage vault = vaultInfo[_pid];
    vault.allowance[msg.sender][spender] = value;
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
    VaultInfo storage vault = vaultInfo[_pid];
    require(vault.allowance[owner][msg.sender] >= _amount, "withdraw: insufficient allowance");
    vault.allowance[owner][msg.sender] = vault.allowance[owner][msg.sender].sub(_amount);
    _withdraw(_pid, _amount, owner, msg.sender);
  }

  // Withdraw tokens from the vault.
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
    VaultInfo storage vault = vaultInfo[_pid];
    require(vault.withdrawable, "Withdrawing from this vault is disabled");
    UserInfo storage user = userInfo[_pid][from];
    require(user.amount >= _amount, "Withdraw not available");
    require(user.timelockEnd < now, "Timelocked");

    massUpdateVaults();

    // 1 day time to withdraw, timelock again if did not make it.
    if (user.timelockEnd > 0 && user.timelockEnd <= now - timelockGracePeriod) {
      updateAndPayOutPending(vault, user, from); // Pay out here since we are timelocking again.
      user.ZZZRewardDebt = user.amount.add(user.boost[epoch]).add(user.timelockBoost).mul(vault.accZZZPerShare).div(1e12);
      user.NAPRewardDebt = user.amount.add(user.boost[epoch]).add(user.timelockBoost).mul(vault.accNAPPerShare).div(1e12);
      user.timelockEnd = now + 4 weeks;
      return;
    } else {
      user.timelockEnd = 0;
    }

    updateAndPayOutPending(vault, user, from);

    if (_amount > 0) {
      vault.token.safeTransfer(address(to), _amount);
      if (address(vault.token) == address(zzz)) {
        userZZZ = userZZZ.sub(_amount);
      }
      if (address(vault.token) == address(nap)) {
        userNAP = userNAP.sub(_amount);
      }
      updateBoostAmounts(_amount, _pid, true, vault, user);
      user.amount = user.amount.sub(_amount);
    }

    uint256 boostAmount = user.boost[epoch];
    if (user.timelockBoost > 0) {
      vault.totalTimelockBoost = vault.totalTimelockBoost.sub(user.timelockBoost);
      user.timelockBoost = 0;
    }

    user.ZZZRewardDebt = user.amount.add(boostAmount).add(user.timelockBoost).mul(vault.accZZZPerShare).div(1e12);
    user.NAPRewardDebt = user.amount.add(boostAmount).add(user.timelockBoost).mul(vault.accNAPPerShare).div(1e12);

    emit Withdraw(to, _pid, _amount);
  }

  function claim(uint256 _pid) public {
    VaultInfo storage vault = vaultInfo[_pid];
    UserInfo storage user = userInfo[_pid][msg.sender];

    massUpdateVaults();
    updateAndPayOutPending(vault, user, msg.sender);
    uint256 boostAmount = user.boost[epoch];

    user.ZZZRewardDebt = user.amount.add(boostAmount).add(user.timelockBoost).mul(vault.accZZZPerShare).div(1e12);
    user.NAPRewardDebt = user.amount.add(boostAmount).add(user.timelockBoost).mul(vault.accNAPPerShare).div(1e12);
  }

  function purchase(
    uint256 _pid,
    address _token,
    uint256 _level
  ) external {
    VaultInfo storage vault = vaultInfo[_pid];
    UserInfo storage user = userInfo[_pid][msg.sender];

    updateAndPayOutPending(vault, user, msg.sender);

    // Cost will be reduced by the amount already spent on multipliers.
    // Users last level, no cost for levels lower than current (doh)

    uint256 cost = calculateCost(_pid, msg.sender, _token, _level);

    // Transfer tokens to the contract
    if (_token == axioms) {
      require(IERC20(_token).transferFrom(msg.sender, 0x000000000000000000000000000000000000dEaD, cost));
    } else if (_token == address(nap)) {
      require(IERC20(_token).transferFrom(msg.sender, treasury, cost.mul(50).div(100)));
      require(IERC20(_token).transferFrom(msg.sender, address(this), cost.mul(50).div(100)));
    } else {
      require(IERC20(_token).transferFrom(msg.sender, treasury, cost));
    }

    multiplier.purchase(address(this), msg.sender, _token, _level, epoch, _pid);

    // If user has staked balances, then set their new accounting balance
    if (user.amount > 0) {
      updateBoostAmounts(user.amount, _pid, false, vault, user);
      uint256 boostAmount = user.boost[epoch];
      user.ZZZRewardDebt = user.amount.add(boostAmount).add(user.timelockBoost).mul(vault.accZZZPerShare).div(1e12);
      user.NAPRewardDebt = user.amount.add(boostAmount).add(user.timelockBoost).mul(vault.accNAPPerShare).div(1e12);
    }
  }

  function updateAndPayOutPending(
    VaultInfo storage vault,
    UserInfo storage user,
    address from
  ) internal {
    if (user.amount == 0) return;
    uint256 effectiveAmount = user.amount.add(user.boost[epoch]).add(user.timelockBoost);
    uint256 pendingZZZ = effectiveAmount.mul(vault.accZZZPerShare).div(1e12).sub(user.ZZZRewardDebt);
    uint256 pendingNAP = effectiveAmount.mul(vault.accNAPPerShare).div(1e12).sub(user.NAPRewardDebt);

    if (pendingZZZ > 0) {
      safeZZZTransfer(from, pendingZZZ);
    }
    if (pendingNAP > 0) {
      safeNAPTransfer(from, pendingNAP);
    }
  }

  // function that lets owner/governance contract
  // approve allowance for any token inside this contract
  // This means all future UNI like airdrops are covered
  // And at the same time allows us to give allowance to strategy contracts.
  function setStrategyContractOrDistributionContractAllowance(
    address _tokenAddress,
    uint256 _amount,
    address _contractAddress
  ) public {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) || hasRole(GOVERNANCE_ROLE, _msgSender()), "!Admin");
    require(isContract(_contractAddress), "Recipent is not a smart contract, BAD");
    require(block.number > contractStartBlock.add(95000), "Governance setup grace period not over"); // about 2weeks
    IERC20(_tokenAddress).approve(_contractAddress, _amount);
  }

  function isContract(address addr) public view returns (bool) {
    uint256 size;
    assembly {
      size := extcodesize(addr)
    }
    return size > 0;
  }

  // Withdraw without caring about anything. EMERGENCY ONLY.
  // This will remove your rewards and your boosts.
  function emergencyWithdraw(uint256 _pid) external {
    VaultInfo storage vault = vaultInfo[_pid];
    require(vault.withdrawable, "Withdrawing from this vault is disabled");
    UserInfo storage user = userInfo[_pid][msg.sender];
    require(user.timelockEnd <= now, "Timelocked");

    vault.token.transfer(msg.sender, user.amount);
    emit EmergencyWithdraw(msg.sender, _pid, user.amount);
    vault.totalEffective[epoch] = vault.totalEffective[epoch].sub(user.boost[epoch]);
    vault.totalTimelockBoost = vault.totalTimelockBoost.sub(user.timelockBoost);
    user.amount = 0;
    user.boost[epoch] = 0;
    user.timelockBoost = 0;
    user.timelockEnd = 0;
    user.ZZZRewardDebt = 0;
    user.NAPRewardDebt = 0;
    // No mass update dont update pending rewards
  }

  // Calculate the cost for purchasing a boost.
  function calculateCost(
    uint256 _pid,
    address _user,
    address _token,
    uint256 _level
  ) public view returns (uint256) {
    // Users last level, no cost for levels lower than current (doh)
    uint256 lastLevel = multiplier.getLastTokenLevelForUser(address(this), _user, _token, epoch, _pid);
    if (lastLevel >= _level) {
      return 0;
    } else {
      return multiplier.getSpendableCostPerTokenForUser(address(this), _user, _token, _level, epoch, _pid);
    }
  }

  // A 4 week period to safely recover funds from the contract.
  function emergencyExit() external {
    require(hasRole(GOVERNANCE_ROLE, _msgSender()), "!Gov");
    require(now <= devGracePeriod, "Grace period over");
    zzz.transfer(treasury, zzz.balanceOf(address(this)));
    zzzeth.transfer(treasury, zzzeth.balanceOf(address(this)));
    zzznap.transfer(treasury, zzznap.balanceOf(address(this)));
    nap.transfer(treasury, nap.balanceOf(address(this)));
  }

  // Safe nap transfer function, just in case if rounding error causes vault to not have enough NAPs.
  function safeNAPTransfer(address _to, uint256 _amount) internal {
    if (_amount == 0) return;

    if (_amount > napReserve) {
      nap.transfer(_to, napReserve);
      napReserve = 0;
    } else {
      nap.transfer(_to, _amount);
      napReserve = napReserve.sub(_amount);
    }
  }

  // Safe nap transfer function, just in case if rounding error causes vault to not have enough NAPs.
  function safeZZZTransfer(address _to, uint256 _amount) internal {
    if (_amount == 0) return;

    if (_amount > zzzReserve) {
      zzz.transfer(_to, zzzReserve);
      zzzReserve = 0;
    } else {
      zzz.transfer(_to, _amount);
      zzzReserve = zzzReserve.sub(_amount);
    }
  }
}
