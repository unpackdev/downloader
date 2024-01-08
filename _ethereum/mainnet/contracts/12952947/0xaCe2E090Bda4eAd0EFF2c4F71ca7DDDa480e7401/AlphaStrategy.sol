pragma solidity 0.7.3;

import "./Math.sol";
import "./BaseUpgradeableStrategy.sol";
import "./SushiBar.sol";
import "./IMasterChef.sol";
import "./TAlphaToken.sol";
import "./IVault.sol";
import "./console.sol";

contract AlphaStrategy is BaseUpgradeableStrategy {

  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  // additional storage slots (on top of BaseUpgradeableStrategy ones) are defined here
  bytes32 internal constant _SLP_POOLID_SLOT = 0x8956ecb40f9dfb494a392437d28a65bb0ddc57b20a9b6274df098a6daa528a72;
  bytes32 internal constant _ONX_FARM_POOLID_SLOT = 0x1da1707f101f5a1bf84020973bd9ccafa38ae6f35fcff3e0f1f3590f13f665c0;

  address public onx;
  address public stakedOnx;
  address public sushi;
  address public xSushi;

  address public treasury;

  mapping(address => uint256) public userRewardDebt;

  uint256 public accRewardPerShare;
  uint256 public lastPendingReward;
  uint256 public curPendingReward;

  mapping(address => uint256) public userXSushiDebt;

  uint256 public accXSushiPerShare;
  uint256 public lastPendingXSushi;
  uint256 public curPendingXSushi;

  uint256 keepFee;
  uint256 keepFeeMax;

  TAlphaToken public tAlpha;

  constructor() public {
  }

  function initializeAlphaStrategy(
    address _storage,
    address _underlying,
    address _vault,
    address _slpRewardPool,
    uint256 _slpPoolID,
    address _onxFarmRewardPool,
    uint256 _onxFarmRewardPoolId,
    address _onx,
    address _stakedOnx,
    address _sushi,
    address _xSushi,
    address _tAlpha
  ) public initializer {
    assert(_SLP_POOLID_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.slpPoolId")) - 1));
    assert(_ONX_FARM_POOLID_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.onxFarmRewardPoolId")) - 1));

    BaseUpgradeableStrategy.initializeBaseUpgradeableStrategy(
      _storage,
      _underlying,
      _vault,
      _slpRewardPool,
      _sushi,
      _onxFarmRewardPool,
      _stakedOnx,
      true, // sell
      0, // sell floor
      12 hours // implementation change delay
    );

    address _lpt;
    (_lpt,,,) = IMasterChef(slpRewardPool()).poolInfo(_slpPoolID);
    require(_lpt == underlying(), "Pool Info does not match underlying");
    _setSLPPoolId(_slpPoolID);
    _setOnxFarmPoolId(_onxFarmRewardPoolId);

    onx = _onx;
    sushi = _sushi;
    xSushi = _xSushi;
    stakedOnx = _stakedOnx;

    tAlpha = TAlphaToken(_tAlpha);

    treasury = address(0x252766CD49395B6f11b9F319DAC1c786a72f6537);
    keepFee = 10;
    keepFeeMax = 100;
  }

  // keep fee functions
  function setKeepFee(uint256 _fee, uint256 _feeMax) external onlyGovernance {
    require(_feeMax > 0, "feeMax should be bigger than zero");
    require(_fee < _feeMax, "fee can't be bigger than feeMax");
    keepFee = _fee;
    keepFeeMax = _feeMax;
  }

  // Salvage functions
  function unsalvagableTokens(address token) public view returns (bool) {
    return (token == onx || token == stakedOnx || token == sushi || token == underlying());
  }

  /**
  * Salvages a token.
  */
  function salvage(address recipient, address token, uint256 amount) public onlyGovernance {
    // To make sure that governance cannot come in and take away the coins
    require(!unsalvagableTokens(token), "token is defined as not salvagable");
    IERC20(token).safeTransfer(recipient, amount);
  }

  // Reward time based model functions

  modifier onlyVault() {
    require(msg.sender == vault(), "Not a vault");
    _;
  }

  function updateAccPerShare(address user) public onlyVault {
    updateAccSOnxPerShare(user);
    updateAccXSushiPerShare(user);
  }

  function updateAccSOnxPerShare(address user) internal {
    // For xOnx
    curPendingReward = pendingReward();
    uint256 totalSupply = IERC20(vault()).totalSupply();

    if (lastPendingReward > 0 && curPendingReward < lastPendingReward) {
      curPendingReward = 0;
      lastPendingReward = 0;
      accRewardPerShare = 0;
      userRewardDebt[user] = 0;
      return;
    }

    if (totalSupply == 0) {
      accRewardPerShare = 0;
      return;
    }

    uint256 addedReward = curPendingReward.sub(lastPendingReward);
    accRewardPerShare = accRewardPerShare.add(
      (addedReward.mul(1e36)).div(totalSupply)
    );
  }

  function updateAccXSushiPerShare(address user) internal {
    // For XSushi
    curPendingXSushi = pendingXSushi();
    uint256 totalSupply = IERC20(vault()).totalSupply();

    if (lastPendingXSushi > 0 && curPendingXSushi < lastPendingXSushi) {
      curPendingXSushi = 0;
      lastPendingXSushi = 0;
      accXSushiPerShare = 0;
      userXSushiDebt[user] = 0;
      return;
    }

    if (totalSupply == 0) {
      accXSushiPerShare = 0;
      return;
    }

    uint256 addedReward = curPendingXSushi.sub(lastPendingXSushi);
    accXSushiPerShare = accXSushiPerShare.add(
      (addedReward.mul(1e36)).div(totalSupply)
    );
  }

  function updateUserRewardDebts(address user) public onlyVault {
    userRewardDebt[user] = IERC20(vault()).balanceOf(user)
    .mul(accRewardPerShare)
    .div(1e36);

    userXSushiDebt[user] = IERC20(vault()).balanceOf(user)
    .mul(accXSushiPerShare)
    .div(1e36);
  }

  function pendingReward() public view returns (uint256) {
    return IERC20(stakedOnx).balanceOf(address(this));
  }

  function pendingXSushi() public view returns (uint256) {
    return IERC20(xSushi).balanceOf(address(this));
  }

  function pendingRewardOfUser(address user) external view returns (uint256, uint256) {
    return (pendingSOnxOfUser(user), pendingXSushiOfUser(user));
  }

  function pendingXSushiOfUser(address user) public view returns (uint256) {
    uint256 totalSupply = IERC20(vault()).totalSupply();
    uint256 userBalance = IERC20(vault()).balanceOf(user);
    if (totalSupply == 0) return 0;

    // pending xSushi
    uint256 allPendingXSushi = pendingXSushi();
    if (allPendingXSushi < lastPendingXSushi) return 0;
    uint256 addedReward = allPendingXSushi.sub(lastPendingXSushi);
    uint256 newAccXSushiPerShare = accXSushiPerShare.add(
        (addedReward.mul(1e36)).div(totalSupply)
    );
    uint256 _pendingXSushi = userBalance.mul(newAccXSushiPerShare).div(1e36).sub(
      userXSushiDebt[user]
    );
    _pendingXSushi = _pendingXSushi.sub(_pendingXSushi.mul(keepFee).div(keepFeeMax));

    return _pendingXSushi;
  }

  function pendingSOnxOfUser(address user) public view returns (uint256) {
    uint256 totalSupply = IERC20(vault()).totalSupply();
    uint256 userBalance = IERC20(vault()).balanceOf(user);
    if (totalSupply == 0) return 0;

    // pending sOnx
    uint256 allPendingReward = pendingReward();
    if (allPendingReward < lastPendingReward) return 0;
    uint256 addedReward = allPendingReward.sub(lastPendingReward);
    uint256 newAccRewardPerShare = accRewardPerShare.add(
        (addedReward.mul(1e36)).div(totalSupply)
    );
    uint256 _pendingReward = userBalance.mul(newAccRewardPerShare).div(1e36).sub(
      userRewardDebt[user]
    );
    _pendingReward = _pendingReward.sub(_pendingReward.mul(keepFee).div(keepFeeMax));

    return _pendingReward;
  }

  function withdrawReward(address user) public onlyVault {
    // withdraw pending SOnx
    uint256 _pending = IERC20(vault()).balanceOf(user)
    .mul(accRewardPerShare)
    .div(1e36)
    .sub(userRewardDebt[user]);
    uint256 _balance = IERC20(stakedOnx).balanceOf(address(this));
    if (_balance < _pending) {
      _pending = _balance;
    }
    // keep fee for treasury
    uint256 _fee = _pending.mul(keepFee).div(keepFeeMax);
    IERC20(stakedOnx).safeTransfer(treasury, _fee);
    lastPendingReward = curPendingReward.sub(_fee);
    // send reward to user
    _pending = _pending.sub(_fee);
    IERC20(stakedOnx).safeTransfer(user, _pending);
    lastPendingReward = lastPendingReward.sub(_pending);

    // withdraw pending XSushi
    uint256 _pendingXSushi = IERC20(vault()).balanceOf(user)
    .mul(accXSushiPerShare)
    .div(1e36)
    .sub(userXSushiDebt[user]);
    uint256 _xSushiBalance = IERC20(xSushi).balanceOf(address(this));
    if (_xSushiBalance < _pendingXSushi) {
      _pendingXSushi = _xSushiBalance;
    }
    // keep fee for treasury
    uint256 _feeXSushi = _pendingXSushi.mul(keepFee).div(keepFeeMax);
    IERC20(xSushi).safeTransfer(treasury, _feeXSushi);
    lastPendingXSushi = curPendingXSushi.sub(_feeXSushi);
    // send reward to user
    _pendingXSushi = _pendingXSushi.sub(_feeXSushi);
    IERC20(xSushi).safeTransfer(user, _pendingXSushi);
    lastPendingXSushi = lastPendingXSushi.sub(_pendingXSushi);
  }

  /*
  *   In case there are some issues discovered about the pool or underlying asset
  *   Governance can exit the pool properly
  *   The function is only used for emergency to exit the pool
  */
  function emergencyExit() public onlyGovernance {
    emergencyExitSLPRewardPool();
    _setPausedInvesting(true);
  }

  /*
  *   Resumes the ability to invest into the underlying reward pools
  */

  function continueInvesting() public onlyGovernance {
    _setPausedInvesting(false);
  }

  /*
  *   Withdraws all the asset to the vault
  */
  function withdrawAllToVault() public restricted {
    if (address(slpRewardPool()) != address(0)) {
      exitSLPRewardPool();
    }
    // _liquidateReward();
    IERC20(underlying()).safeTransfer(vault(), IERC20(underlying()).balanceOf(address(this)));
  }

  /*
  *   Withdraws all the asset to the vault
  */
  function withdrawToVault(uint256 amount) public restricted {
    // Typically there wouldn't be any amount here
    // however, it is possible because of the emergencyExit
    uint256 entireBalance = IERC20(underlying()).balanceOf(address(this));

    if(amount > entireBalance){
      // While we have the check above, we still using SafeMath below
      // for the peace of mind (in case something gets changed in between)
      uint256 needToWithdraw = amount.sub(entireBalance);
      uint256 toWithdraw = Math.min(slpRewardPoolBalance(), needToWithdraw);
      IMasterChef(slpRewardPool()).withdraw(slpPoolId(), toWithdraw);
    }

    IERC20(underlying()).safeTransfer(vault(), amount);
  }

  /*
  *   Note that we currently do not have a mechanism here to include the
  *   amount of reward that is accrued.
  */
  function investedUnderlyingBalance() external view returns (uint256) {
    if (slpRewardPool() == address(0)) {
      return IERC20(underlying()).balanceOf(address(this));
    }
    // Adding the amount locked in the reward pool and the amount that is somehow in this contract
    // both are in the units of "underlying"
    // The second part is needed because there is the emergency exit mechanism
    // which would break the assumption that all the funds are always inside of the reward pool
    return slpRewardPoolBalance().add(IERC20(underlying()).balanceOf(address(this)));
  }

  // OnsenFarm functions - Sushiswap slp reward pool functions

  function slpRewardPoolBalance() internal view returns (uint256 bal) {
      (bal,) = IMasterChef(slpRewardPool()).userInfo(slpPoolId(), address(this));
  }

  function exitSLPRewardPool() internal {
      uint256 bal = slpRewardPoolBalance();
      if (bal != 0) {
          IMasterChef(slpRewardPool()).withdraw(slpPoolId(), bal);
      }
  }

  function claimSLPRewardPool() internal {
      uint256 bal = slpRewardPoolBalance();
      if (bal != 0) {
          IMasterChef(slpRewardPool()).withdraw(slpPoolId(), 0);
      }
  }

  function emergencyExitSLPRewardPool() internal {
      uint256 bal = slpRewardPoolBalance();
      if (bal != 0) {
          IMasterChef(slpRewardPool()).emergencyWithdraw(slpPoolId());
      }
  }

  function enterSLPRewardPool() internal {
    uint256 entireBalance = IERC20(underlying()).balanceOf(address(this));
    if (entireBalance > 0) {
      IERC20(underlying()).safeApprove(slpRewardPool(), 0);
      IERC20(underlying()).safeApprove(slpRewardPool(), entireBalance);
      IMasterChef(slpRewardPool()).deposit(slpPoolId(), entireBalance);
    }
  }

  function stakeOnsenFarm() external onlyNotPausedInvesting restricted {
    enterSLPRewardPool();
  }

  // SushiBar Functions

  function stakeSushiBar() external onlyNotPausedInvesting restricted {
    claimSLPRewardPool();

    uint256 sushiRewardBalance = IERC20(sushi).balanceOf(address(this));
    if (!sell() || sushiRewardBalance < sellFloor()) {
      // Profits can be disabled for possible simplified and rapid exit
      // emit ProfitsNotCollected(sell(), sushiRewardBalance < sellFloor());
      return;
    }

    if (sushiRewardBalance == 0) {
      return;
    }

    IERC20(sushi).safeApprove(xSushi, 0);
    IERC20(sushi).safeApprove(xSushi, sushiRewardBalance);

    SushiBar(xSushi).enter(sushiRewardBalance);
  }

  // Onx Farm Dummy Token Pool functions

  function _enterOnxFarmRewardPool() internal {
    uint256 bal = _onxFarmRewardPoolBalance();
    uint256 entireBalance = IERC20(vault()).totalSupply();
    if (bal == 0) {
      tAlpha.mint(address(this), entireBalance);
      IERC20(tAlpha).safeApprove(onxFarmRewardPool(), 0);
      IERC20(tAlpha).safeApprove(onxFarmRewardPool(), entireBalance);
      IMasterChef(onxFarmRewardPool()).deposit(onxFarmRewardPoolId(), entireBalance);
    }
  }

  function _onxFarmRewardPoolBalance() internal view returns (uint256 bal) {
      (bal,) = IMasterChef(onxFarmRewardPool()).userInfo(onxFarmRewardPoolId(), address(this));
  }

  function exitOnxFarmRewardPool() external restricted {
      uint256 bal = _onxFarmRewardPoolBalance();
      if (bal != 0) {
          IMasterChef(onxFarmRewardPool()).withdraw(onxFarmRewardPoolId(), bal);
          tAlpha.burn(address(this), bal);
      }
  }

  function _claimXSushiRewardPool() internal {
      uint256 bal = _onxFarmRewardPoolBalance();
      if (bal != 0) {
          IMasterChef(onxFarmRewardPool()).withdraw(onxFarmRewardPoolId(), 0);
      }
  }

  function stakeOnxFarm() external onlyNotPausedInvesting restricted {
    _enterOnxFarmRewardPool();
  }

  // Onx Priv Pool functions

  function stakeOnx() external onlyNotPausedInvesting restricted {
    _claimXSushiRewardPool();

    uint256 onxRewardBalance = IERC20(onx).balanceOf(address(this));

    uint256 stakedOnxRewardBalance = IERC20(onxStakingRewardPool()).balanceOf(address(this));
    
    if (!sell() || onxRewardBalance < sellFloor()) {
      return;
    }

    if (onxRewardBalance == 0) {
      return;
    }

    IERC20(onx).safeApprove(onxStakingRewardPool(), 0);
    IERC20(onx).safeApprove(onxStakingRewardPool(), onxRewardBalance);

    SushiBar(onxStakingRewardPool()).enter(onxRewardBalance);
  }

  /**
  * Can completely disable claiming UNI rewards and selling. Good for emergency withdraw in the
  * simplest possible way.
  */
  function setSell(bool s) public onlyGovernance {
    _setSell(s);
  }

  /**
  * Sets the minimum amount of CRV needed to trigger a sale.
  */
  function setSellFloor(uint256 floor) public onlyGovernance {
    _setSellFloor(floor);
  }

  // masterchef rewards pool ID
  function _setSLPPoolId(uint256 _value) internal {
    setUint256(_SLP_POOLID_SLOT, _value);
  }

  // onx masterchef rewards pool ID
  function _setOnxFarmPoolId(uint256 _value) internal {
    setUint256(_ONX_FARM_POOLID_SLOT, _value);
  }

  function slpPoolId() public view returns (uint256) {
    return getUint256(_SLP_POOLID_SLOT);
  }

  function onxFarmRewardPoolId() public view returns (uint256) {
    return getUint256(_ONX_FARM_POOLID_SLOT);
  }

  function setOnxTreasuryFundAddress(address _address) public onlyGovernance {
    treasury = _address;
  }
}
