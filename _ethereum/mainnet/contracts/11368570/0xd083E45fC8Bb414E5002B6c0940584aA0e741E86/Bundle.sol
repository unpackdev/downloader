// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

import "./IERC20.sol";
import "./Address.sol";
import "./Math.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./IBundle.sol";
import "./IStrategy.sol";
import "./IController.sol";
import "./IVault.sol";
import "./Controllable.sol";
import "./Storage.sol";


contract Bundle is IBundle, Controllable {
  using SafeERC20 for IERC20;
  using Address for address;
  using SafeMath for uint256;

  event Invest(uint256 amount);

  IERC20 public underlying;
  IVault public vault;

  struct StrategyStruct {
    uint256 riskScore;
    uint256 weightage;
    bool isActive;
  }

  mapping(address => StrategyStruct) public strategyStruct;
  address[] public strategyList;

  uint256 vaultFractionToInvestNumerator = 0;
  uint256 vaultFractionToInvestDenominator = 100;
  
  uint256 accountedBalance;

  // These tokens cannot be claimed by the controller
  mapping (address => bool) public unsalvagableTokens;

  constructor(address _storage, address _underlying, address _vault) public
  Controllable(_storage) {
    require(_underlying != address(0), "_underlying cannot be empty");
    require(_vault != address(0), "_vault cannot be empty");
    // We assume that this contract is a minter on underlying
    underlying = IERC20(_underlying);
    vault = IVault(_vault);
  }

  function depositArbCheck() public override view returns(bool) {
    return true;
  }

  modifier restricted() {
    require(msg.sender == address(vault) || msg.sender == address(controller()),
      "The sender has to be the controller or vault");
    _;
  }

  function isActiveStrategy(address _strategy) internal view returns(bool isActive) {
      return strategyStruct[_strategy].isActive;
  }

  function getStrategyCount() internal view returns(uint256 strategyCount) {
    return strategyList.length;
  }

  modifier whenStrategyDefined() {
    require(getStrategyCount() > 0, "Strategies must be defined");
    _;
  }

  function getUnderlying() public override view returns (address) {
    return address(underlying);
  }

  function getVault() public override view returns (address) {
    return address(vault);
  }

  /*
  * Returns the cash balance across all users in this contract.
  */
  function underlyingBalanceInBundle() view public override returns (uint256) {
    return underlying.balanceOf(address(this));
  }

  /* Returns the current underlying (e.g., DAI's) balance together with
   * the invested amount (if DAI is invested elsewhere by the strategy).
  */
  function underlyingBalanceWithInvestment() view public override returns (uint256) {
    uint256 underlyingBalance = underlyingBalanceInBundle();
    if (getStrategyCount() == 0) {
      // initial state, when not set
      return underlyingBalance;
    }
    for (uint256 i=0; i<getStrategyCount(); i++) {
      underlyingBalance = underlyingBalance.add(IStrategy(strategyList[i]).investedUnderlyingBalance());
    }
    return underlyingBalance;
  }

  function availableToInvestOut() public view returns (uint256) {
    uint256 wantInvestInTotal = underlyingBalanceWithInvestment()
        .mul(vaultFractionToInvestNumerator)
        .div(vaultFractionToInvestDenominator);
    uint256 alreadyInvested = 0;
    for (uint256 i=0; i<getStrategyCount(); i++) {
      alreadyInvested = alreadyInvested.add(IStrategy(strategyList[i]).investedUnderlyingBalance());
    }
    if (alreadyInvested >= wantInvestInTotal) {
      return 0;
    } else {
      uint256 remainingToInvest = wantInvestInTotal.sub(alreadyInvested);
      return remainingToInvest <= underlyingBalanceInBundle()
        ? remainingToInvest : underlyingBalanceInBundle();
    }
  }

  function addStrategy(address _strategy, uint256 riskScore, uint256 weightage) public override onlyControllerOrGovernance {
    require(_strategy != address(0), "new _strategy cannot be empty");
    require((IStrategy(_strategy).getUnderlying() == address(underlying)), "Bundle underlying must match Strategy underlying");
    require(IStrategy(_strategy).getBundle() == address(this), "The strategy does not belong to this bundle");
    require(isActiveStrategy(_strategy) == false, "This strategy is already active in this bundle");
    require(vaultFractionToInvestNumerator.add(weightage) <= 90, "Total investment can't be above 90%");
    
    strategyStruct[_strategy].riskScore = riskScore;
    strategyStruct[_strategy].weightage = weightage;
    vaultFractionToInvestNumerator = vaultFractionToInvestNumerator.add(weightage);
    strategyStruct[_strategy].isActive = true;
    strategyList.push(_strategy);

    underlying.safeApprove(_strategy, 0);
    underlying.safeApprove(_strategy, uint256(~0));
  }

  // function removeStrategy(address _strategy) public override onlyControllerOrGovernance {
  //   require(_strategy != address(0), "new _strategy cannot be empty");
  //   require(IStrategy(_strategy).getUnderlying() == address(underlying), "Vault underlying must match Strategy underlying");
  //   require(IStrategy(_strategy).getVault() == address(this), "the strategy does not belong to this vault");

  //   if (address(_strategy) != address(strategy)) {
  //     if (address(strategy) != address(0)) { // if the original strategy (no underscore) is defined
  //       underlying.safeApprove(address(strategy), 0);
  //       strategy.withdrawAllToVault();
  //     }
  //     strategy = IStrategy(_strategy);
  //     underlying.safeApprove(address(strategy), 0);
  //     underlying.safeApprove(address(strategy), uint256(~0));
  //   }
  // }

  function invest() internal whenStrategyDefined {
    uint256 availableAmount = availableToInvestOut();
    for (uint256 i=0; i<getStrategyCount(); i++) {
      if (strategyStruct[strategyList[i]].isActive) {
        uint256 weightage = strategyStruct[strategyList[i]].weightage;
        uint256 availableAmountForStrategy = availableAmount.mul(weightage).div(vaultFractionToInvestNumerator);
        if (availableAmountForStrategy > 0) {
          underlying.safeTransfer(strategyList[i], availableAmountForStrategy);
          emit Invest(availableAmountForStrategy);
        }
      }
    }
  }

  /**
  * Chooses the best strategy and re-invests. If the strategy did not change, it just calls
  * doHardWork on the current strategy. Call this through controller to claim hard rewards.
  */
  function doHardWork() whenStrategyDefined external override restricted{
    // ensure that new funds are invested too
    invest();
    for (uint256 i=0; i<getStrategyCount(); i++) {
      if (strategyStruct[strategyList[i]].isActive) {
        IStrategy(strategyList[i]).doHardWork();
      }
    }
  }

  function rebalance() external override onlyControllerOrGovernance {
    withdrawAll();
    invest();
  }

  function withdrawAll() public override onlyControllerOrGovernance whenStrategyDefined {
    for (uint256 i=0; i<getStrategyCount(); i++) {
      IStrategy(strategyList[i]).withdrawAllToBundle();
    }
  }

  function withdraw(uint256 underlyingAmountToWithdraw, address holder) external override restricted returns (uint256){

    if (underlyingAmountToWithdraw > underlyingBalanceInBundle()) {
      uint256 missing = underlyingAmountToWithdraw.sub(underlyingBalanceInBundle());
      for (uint256 i=0; i<getStrategyCount(); i++) {
        if (strategyStruct[strategyList[i]].isActive) {
          uint256 weightage = strategyStruct[strategyList[i]].weightage;
          uint256 missingforStrategy = missing.mul(weightage).div(vaultFractionToInvestNumerator);
          IStrategy(strategyList[i]).withdrawToBundle(missingforStrategy);
        }
      }
      // recalculate to improve accuracy
      underlyingAmountToWithdraw = Math.min(underlyingAmountToWithdraw, underlyingBalanceInBundle());
    }

    underlying.safeTransfer(holder, underlyingAmountToWithdraw);
    return underlyingAmountToWithdraw;
  }
}
