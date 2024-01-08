pragma solidity 0.7.3;

import "./Math.sol";
// import "./ERC20Detailed.sol";
import "./BaseUpgradeableStrategy.sol";
import "./SushiBar.sol";
import "./IMasterChef.sol";

contract AlphaStrategy is BaseUpgradeableStrategy {

  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  // additional storage slots (on top of BaseUpgradeableStrategy ones) are defined here
  bytes32 internal constant _SLP_POOLID_SLOT = 0x8956ecb40f9dfb494a392437d28a65bb0ddc57b20a9b6274df098a6daa528a72;
  bytes32 internal constant _ONX_XSUSHI_POOLID_SLOT = 0x3a59bce91ecc6237acab7341062d132e6dcb920d0fe2ca5f3a8e08755ef691e7;

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

  constructor() public BaseUpgradeableStrategy() {
    assert(_SLP_POOLID_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.slpPoolId")) - 1));
    assert(_ONX_XSUSHI_POOLID_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.onxXSushiPoolId")) - 1));
  }

  function initializeAlphaStrategy(
    address _storage,
    address _underlying,
    address _vault,
    address _slpRewardPool,
    uint256 _slpPoolID,
    address _onxXSushiFarmRewardPool,
    uint256 _onxXSushiPoolId,
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
      _onxXSushiFarmRewardPool,
      _stakedOnx,
      true, // sell
      0, // sell floor
      12 hours // implementation change delay
    );

    address _lpt;
    (_lpt,,,) = IMasterChef(slpRewardPool()).poolInfo(_slpPoolID);
    require(_lpt == underlying(), "Pool Info does not match underlying");
    _setSLPPoolId(_slpPoolID);
    _setOnxXSushiPoolId(_onxXSushiPoolId);

    onx = _onx;
    sushi = _sushi;
    xSushi = _xSushi;
    stakedOnx = _stakedOnx;
  }

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

  function stakeOnsenFarm() external onlyNotPausedInvesting restricted {
    enterSLPRewardPool();
  }

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

  function _enterXSushiRewardPool() internal {
    uint256 entireBalance = IERC20(xSushi).balanceOf(address(this));
    IERC20(xSushi).safeApprove(onxXSushiRewardPool(), 0);
    IERC20(xSushi).safeApprove(onxXSushiRewardPool(), entireBalance);
    IMasterChef(onxXSushiRewardPool()).deposit(onxXSushiPoolId(), entireBalance);
  }

  function _xSushiRewardPoolBalance() internal view returns (uint256 bal) {
      (bal,) = IMasterChef(onxXSushiRewardPool()).userInfo(onxXSushiPoolId(), address(this));
  }

  function _exitXSushiRewardPool() internal {
      uint256 bal = _xSushiRewardPoolBalance();
      if (bal != 0) {
          IMasterChef(onxXSushiRewardPool()).withdraw(onxXSushiPoolId(), bal);
      }
  }

  function _claimXSushiRewardPool() internal {
      uint256 bal = _xSushiRewardPoolBalance();
      if (bal != 0) {
          IMasterChef(onxXSushiRewardPool()).withdraw(onxXSushiPoolId(), 0);
      }
  }

  function stakeXSushiFarm() external onlyNotPausedInvesting restricted {
    _enterXSushiRewardPool();
  }

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

  function harvest(uint256 _denom, address sender) external onlyNotPausedInvesting restricted {
    require(_denom <= 1, "Denom can't be bigger than 1");

    uint256 onxBalance = IERC20(onx).balanceOf(address(this));
    uint256 stakedOnxBalance = IERC20(stakedOnx).balanceOf(address(this));
    uint256 stakedOnxAmountToHarvest = stakedOnxBalance.mul(_denom);

    if (stakedOnxAmountToHarvest > stakedOnxBalance) {
      stakedOnxAmountToHarvest = stakedOnxBalance;
    }

    // Withdraw from onx staking pool
    if (stakedOnxAmountToHarvest > 0) {
      SushiBar(onxStakingRewardPool()).leave(stakedOnxAmountToHarvest);
    }

    uint256 newOnxBalance = IERC20(onx).balanceOf(address(this));
    uint256 addedOnxAmount = newOnxBalance.sub(onxBalance);

    // Add onx amount in the startegy and withdrawn onx amount
    uint256 onxAmountToHarvest = onxBalance
      .sub(pendingTeamFund)
      .sub(pendingTreasuryFund)
      .mul(_denom)
      .add(addedOnxAmount.mul(_denom));

    // Add team fund and treasury fund
    uint256 teamFund = onxAmountToHarvest.div(20); // for team fund, 5%
    uint256 treasuryFund = onxAmountToHarvest.div(20); // for treasury fund, 5%

    pendingTeamFund = pendingTeamFund.add(teamFund);
    pendingTreasuryFund = pendingTreasuryFund.add(treasuryFund);

    // Send real amount to the sender
    uint256 realOnxAmountToHarvest = onxAmountToHarvest.sub(teamFund).sub(treasuryFund);

    IERC20(onx).safeApprove(sender, 0);
    IERC20(onx).safeApprove(sender, realOnxAmountToHarvest);
    IERC20(onx).safeTransfer(sender, realOnxAmountToHarvest);
  }

  function withdrawPendingTeamFund() external restricted {
    if (pendingTeamFund > 0) {
      uint256 balance = IERC20(onx).balanceOf(address(this));

      if (pendingTeamFund > balance) {
        pendingTeamFund = balance;
      }

      IERC20(onx).safeApprove(onxTeamVault, 0);
      IERC20(onx).safeApprove(onxTeamVault, pendingTeamFund);
      IERC20(onx).safeTransfer(onxTeamVault, pendingTeamFund);

      pendingTeamFund = 0;
    }
  }

  function withdrawPendingTreasuryFund() external restricted {
    if (pendingTreasuryFund > 0) {
      uint256 balance = IERC20(onx).balanceOf(address(this));

      if (pendingTreasuryFund > balance) {
        pendingTreasuryFund = balance;
      }

      IERC20(onx).safeApprove(onxTreasuryVault, 0);
      IERC20(onx).safeApprove(onxTreasuryVault, pendingTreasuryFund);
      IERC20(onx).safeTransfer(onxTreasuryVault, pendingTreasuryFund);

      pendingTreasuryFund = 0;
    }
  }

  function withdrawXSushiToStrategicWallet() external restricted {
    uint256 xSushiBalance = IERC20(xSushi).balanceOf(address(this));
    // Withdraw xsushi from master chef
    _exitXSushiRewardPool();
    uint256 newXSushiBalance = IERC20(xSushi).balanceOf(address(this));
    uint256 xSushiAmountToWithdraw = newXSushiBalance.sub(xSushiBalance);

    if (xSushiAmountToWithdraw != 0) {
      IERC20(xSushi).safeApprove(strategicWallet, 0);
      IERC20(xSushi).safeApprove(strategicWallet, xSushiAmountToWithdraw);
      IERC20(xSushi).safeTransfer(strategicWallet, xSushiAmountToWithdraw);
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
  function _setOnxXSushiPoolId(uint256 _value) internal {
    setUint256(_ONX_XSUSHI_POOLID_SLOT, _value);
  }

  function slpPoolId() public view returns (uint256) {
    return getUint256(_SLP_POOLID_SLOT);
  }

  function onxXSushiPoolId() public view returns (uint256) {
    return getUint256(_ONX_XSUSHI_POOLID_SLOT);
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
