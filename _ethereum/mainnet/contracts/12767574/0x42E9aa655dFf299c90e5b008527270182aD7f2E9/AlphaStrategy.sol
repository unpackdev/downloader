pragma solidity 0.7.3;

import "./Math.sol";
import "./BaseUpgradeableStrategy.sol";
import "./SushiBar.sol";
import "./IMasterChef.sol";
import "./TAlphaToken.sol";
import "./IVault.sol";

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

  address private onxTeamVault = address(0xD25C0aDddD858EB291E162CD4CC984f83C8ff26f);
  address private onxTreasuryVault = address(0xe1825EAbBe12F0DF15972C2fDE0297C8053293aA);
  address private strategicWallet = address(0xe1825EAbBe12F0DF15972C2fDE0297C8053293aA);

  // address onxTeamVault;
  // address onxTreasuryVault;
  // address strategicWallet;

  uint256 private pendingTeamFund;
  uint256 private pendingTreasuryFund;

  mapping(address => uint256) public userRewardDebt;

  uint256 public accRewardPerShare;
  uint256 public lastPendingReward;
  uint256 public curPendingReward;

  mapping(address => uint256) public userXSushiDebt;

  uint256 public accXSushiPerShare;
  uint256 public lastPendingXSushi;
  uint256 public curPendingXSushi;

  TAlphaToken public tAlpha;

  constructor() public BaseUpgradeableStrategy() {
    assert(_SLP_POOLID_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.slpPoolId")) - 1));
    assert(_ONX_FARM_POOLID_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.onxFarmRewardPoolId")) - 1));
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
    address _xSushi
  ) public initializer {

    BaseUpgradeableStrategy.initialize(
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

    tAlpha = new TAlphaToken();
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

    // For XSushi

    curPendingXSushi = pendingXSushi();

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

    addedReward = curPendingXSushi.sub(lastPendingXSushi);
    accXSushiPerShare = accXSushiPerShare.add(
      (addedReward.mul(1e36)).div(totalSupply)
    );
  }

  function pendingReward() public view returns (uint256) {
    return IERC20(stakedOnx).balanceOf(address(this));
  }

  function pendingXSushi() public view returns (uint256) {
    return IERC20(xSushi).balanceOf(address(this));
  }

  function pendingRewardOfUser(address user) external view returns (uint256, uint256) {
    uint256 totalSupply = IERC20(vault()).totalSupply();
    uint256 userBalance = IERC20(vault()).balanceOf(user);
    if (totalSupply == 0) return (0, 0);

    uint256 allPendingReward = pendingReward();
    if (allPendingReward < lastPendingReward) return (0, 0);
    uint256 addedReward = allPendingReward.sub(lastPendingReward);
    uint256 newAccRewardPerShare = accRewardPerShare.add(
        (addedReward.mul(1e36)).div(totalSupply)
    );

    uint256 allPendingXSushi = pendingXSushi();
    if (allPendingXSushi < lastPendingXSushi) return (0, 0);
    addedReward = allPendingXSushi.sub(lastPendingXSushi);
    uint256 newAccXSushiPerShare = accXSushiPerShare.add(
        (addedReward.mul(1e36)).div(totalSupply)
    );

    return (
      userBalance.mul(newAccRewardPerShare).div(1e36).sub(
          userRewardDebt[user]
      ), userBalance.mul(newAccXSushiPerShare).div(1e36).sub(
          userXSushiDebt[user]
      )
    );
  }

  function withdrawReward(address user) public onlyVault {
    uint256 _pending = IERC20(vault()).balanceOf(user)
    .mul(accRewardPerShare)
    .div(1e36)
    .sub(userRewardDebt[user]);
    uint256 _balance = IERC20(stakedOnx).balanceOf(address(this));
    if (_balance < _pending) {
      _pending = _balance;
    }
    IERC20(stakedOnx).safeTransfer(user, _pending);
    lastPendingReward = curPendingReward.sub(_pending);

    uint256 _pendingXSushi = IERC20(vault()).balanceOf(user)
    .mul(accXSushiPerShare)
    .div(1e36)
    .sub(userXSushiDebt[user]);
    uint256 _xSushiBalance = IERC20(xSushi).balanceOf(address(this));
    if (_xSushiBalance < _pendingXSushi) {
      _pendingXSushi = _xSushiBalance;
    }
    IERC20(xSushi).safeTransfer(user, _pendingXSushi);
    lastPendingXSushi = curPendingXSushi.sub(_pendingXSushi);
  }

  // Sushiswap slp reward pool functions

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

  // OnsenFarm functions

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
    uint256 entireBalance = IERC20(xSushi).balanceOf(address(this));
    tAlpha.mint(address(this), entireBalance);
    IERC20(tAlpha).safeApprove(onxFarmRewardPool(), 0);
    IERC20(tAlpha).safeApprove(onxFarmRewardPool(), entireBalance);
    IMasterChef(onxFarmRewardPool()).deposit(onxFarmRewardPoolId(), entireBalance);
  }

  function _onxFarmRewardPoolBalance() internal view returns (uint256 bal) {
      (bal,) = IMasterChef(onxFarmRewardPool()).userInfo(onxFarmRewardPoolId(), address(this));
  }

  function _exitOnxFarmRewardPool() internal {
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

  function withdrawPendingTeamFund() external restricted {
    if (pendingTeamFund > 0) {
      uint256 balance = IERC20(stakedOnx).balanceOf(address(this));

      if (pendingTeamFund > balance) {
        pendingTeamFund = balance;
      }

      IERC20(stakedOnx).safeApprove(onxTeamVault, 0);
      IERC20(stakedOnx).safeApprove(onxTeamVault, pendingTeamFund);
      IERC20(stakedOnx).safeTransfer(onxTeamVault, pendingTeamFund);

      pendingTeamFund = 0;
    }
  }

  function withdrawPendingTreasuryFund() external restricted {
    if (pendingTreasuryFund > 0) {
      uint256 balance = IERC20(stakedOnx).balanceOf(address(this));

      if (pendingTreasuryFund > balance) {
        pendingTreasuryFund = balance;
      }

      IERC20(stakedOnx).safeApprove(onxTreasuryVault, 0);
      IERC20(stakedOnx).safeApprove(onxTreasuryVault, pendingTreasuryFund);
      IERC20(stakedOnx).safeTransfer(onxTreasuryVault, pendingTreasuryFund);

      pendingTreasuryFund = 0;
    }
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

  function setOnxTeamFundAddress(address _address) public onlyGovernance {
    onxTeamVault = _address;
  }

  function setOnxTreasuryFundAddress(address _address) public onlyGovernance {
    onxTreasuryVault = _address;
  }

  function setStrategicWalletAddress(address _address) public onlyGovernance {
    strategicWallet = _address;
  }

  function finalizeUpgrade() external onlyGovernance {
    _finalizeUpgrade();
  }
}
