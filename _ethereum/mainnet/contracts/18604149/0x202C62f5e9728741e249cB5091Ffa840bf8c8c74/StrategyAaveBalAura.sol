// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./SafeERC20.sol";
import "./Math.sol";

import "./IDataProvider.sol";
import "./IBalancerVault.sol";
import "./IAuraBooster.sol";
import "./IBaseRewards.sol";
import "./IRewardsController.sol";
import "./IStablePool.sol";
import "./IUniswapRouter.sol";
import "./StratFeeManagerInitializable.sol";
import "./BalancerLib.sol";
import "./ERC20Lib.sol";
import "./AaveLib.sol";
import "./AuraLib.sol";
import "./ImmutableStorage.sol";
import "./ConfigAaveBalAura.sol";
import "./ILendingPoolV3.sol";
import "./IWrappedNative.sol";

contract StrategyAaveBalAura is StratFeeManagerInitializable {
  using {ERC20Lib._balanceOfThis, ERC20Lib._approve} for IERC20;
  using {AaveLib._deposit, AaveLib._borrow, AaveLib._repay, AaveLib._withdraw} for ILendingPool;
  using {AaveLib._getReserveTokensAddresses} for IDataProvider;
  using SafeERC20 for IERC20;

  address internal immutable configData;
  address internal configExtData;

  address public immutable override want;

  uint256 public lastHarvest;

  event StratHarvest(address indexed harvester, uint256 wantHarvested, uint256 tvl);
  event Deposit(uint256 tvl);
  event Withdraw(uint256 tvl);
  event ChargedFees(uint256 callFees, uint256 beefyFees, uint256 strategistFees);

  constructor(
     Config.Data memory config
  ) {
    configData = ImmutableStoragePub.saveStruct(abi.encode(config));
    want = config.want;
  }

  function initialize (
    ConfigExt.Data memory configExt,
    CommonAddresses calldata _commonAddresses
  ) external initializer {
    __StratFeeManager_init(_commonAddresses);

    setConfigExt(configExt);
    
    _setAllowances(getConfigs(), type(uint).max);
  }

  /******************************************************
   *                                                    *
   *                  PUBLIC FUNCTIONS                  *
   *                                                    *
   ******************************************************/
  
  // Put the funds to work
  function deposit() external whenNotPaused {
    _deposit(getConfigs());
  }

  function _deposit(Configs memory configs) internal {
    Config.Data memory config = configs.base;
    uint256 wantBal = IERC20(want)._balanceOfThis();

    if (wantBal > 0) {
      // Deposit on Aave
      ILendingPool(config.aaveContracts.lendingPool)._deposit(want, wantBal);

      // Borrow From Aave
      uint256[] memory amounts = new uint256[](2);
      unchecked {
        for(uint i = 0; i < WANT_INDEX; i++) {
          uint borrowAmountRef = wantBal * config.borrowRate / 1 ether;
          borrowAmountRef = borrowAmountRef * getProportion(configs, i) / 1 ether;
          amounts[i] = AaveLibPub.borrowQuoted(
            config.aaveContracts.priceOracle,
            config.aaveContracts.lendingPool, 
            want,
            uint8(config.decimals[WANT_INDEX]),
            borrowAmountRef,
            getTokenAddress(configs, i),
            uint8(config.decimals[i]),
            INTEREST_RATE_MODE
          );
        }
      }
      

      // Add liquidity on Balancer (vault1 and vault2)
      BalancerLibPub.balancerJoinMany(config.balancerContracts.balancerVault, config.poolIds.poolId1, amounts);
      BalancerLibPub.balancerJoin(
        config.balancerContracts.balancerVault, 
        config.poolIds.poolId2, 
        config.balancerContracts.bptPool1,
        IERC20(config.balancerContracts.bptPool1)._balanceOfThis()
      );

      // Stake on Aura
      IAuraBooster(config.auraContracts.booster).deposit(
        config.poolIds.pidAura, 
        IERC20(config.balancerContracts.bptPool2)._balanceOfThis(), 
        true
      );

      emit Deposit(_balanceOfPrecise(configs));
    }
  }

  // Withdraw funds
  function withdraw(uint256 _amount) external {
    require(msg.sender == vault, "!vault");

    Configs memory configs = getConfigs();

    unchecked {
      uint256 wantBal = IERC20(want)._balanceOfThis();
      bool depositNeeded = false;

      if(wantBal < _amount) {
        uint256 toWithdraw = _amount - wantBal;

        Config.Data memory config = configs.base;
        uint256 stakingAmount = IERC20(config.auraContracts.stakingToken)._balanceOfThis();
        AuraLib.removeLiqAuraBal2Pools(
          config,
          configs.ext.withdrawMin,
          stakingAmount * toWithdraw / _balanceOfSupply(configs)
        );

        // Repay debt
        ILendingPool(config.aaveContracts.lendingPool)._repay(config.loanToken0, IERC20(config.loanToken0)._balanceOfThis(), INTEREST_RATE_MODE);
        ILendingPool(config.aaveContracts.lendingPool)._repay(config.loanToken1, IERC20(config.loanToken1)._balanceOfThis(), INTEREST_RATE_MODE);

        uint256 toWithdrawMax = getMaxWithdraw(config);
        
        // Withdraw want tokens
        if (toWithdrawMax < toWithdraw) {
          // in rare cases of big withdrawals
          _withdrawAll(configs);
          depositNeeded = true;
        } else {
          toWithdraw = Math.min(toWithdraw, _balanceOfSupply(configs));
          ILendingPool(config.aaveContracts.lendingPool)._withdraw(want, toWithdraw, address(this));
        }

        wantBal = IERC20(want)._balanceOfThis();
      }

      if (wantBal > _amount) {
        wantBal = _amount;
      } else {
        depositNeeded = false;
      }

      IERC20(want).safeTransfer(vault, wantBal);

      emit Withdraw(_balanceOfPrecise(configs));

      if (depositNeeded) {
        _deposit(configs);
      }
    }
  }

  function beforeDeposit() external override {
    Configs memory configs = getConfigs();
    
    require(msg.sender == vault, "!vault");
    
    _harvest(configs, tx.origin);
  }

  function harvest() external virtual whenNotPaused {
    _harvest(getConfigs(), tx.origin);
  }

  function harvest(address callFeeRecipient) external virtual whenNotPaused {
    _harvest(getConfigs(), callFeeRecipient);
  }  

  /******************************************************
   *                                                    *
   *                 INTERNAL FUNCTIONS                 *
   *                                                    *
   ******************************************************/
  
  // compounds earnings and charges performance fee
  function _harvest(Configs memory configs, address callFeeRecipient) internal {
    Config.Data memory config = configs.base;
    // Claim rewards from Aura
    AuraLib.harvest(config.auraContracts.booster, config.auraContracts.auraClaimZapV3, config.poolIds.pidAura);

    // Claim rewards from Aave
    unchecked {
      address[] memory aaveTokens = new address[](WANT_INDEX + 1);
      for (uint i = 0; i <= WANT_INDEX; i++) {
        aaveTokens[i] = getTokenAddress(configs, i);
      }

      AaveLibPub.harvest(config.aaveContracts.dataProvider, config.aaveContracts.rewardsController, aaveTokens);

      // Swap rewards by want token
      uint rewardTokensCount = getRewardTokensCount(configs);
      bool hasReward;
      for(uint256 i = 0; i < rewardTokensCount; i++) {
        hasReward = hasReward || _swap(configs, type(uint).max,  getRewardToken(configs, i), WANT_INDEX) > 0;
      }
    
      // Deposit
      if(hasReward) {
        chargeFees(callFeeRecipient);
        uint256 wantHarvested = IERC20(want)._balanceOfThis();
        _deposit(configs);
        lastHarvest = block.timestamp;

        emit StratHarvest(msg.sender, wantHarvested, _balanceOfPrecise(configs));
      }
    }
  }

  // performance fees
  function chargeFees(address callFeeRecipient) internal {
    IFeeConfig.FeeCategory memory fees = getFees();
    uint256 wantToCharge = IERC20(want)._balanceOfThis() * fees.total / DIVISOR;
    
    uint256 callFeeAmount = _payFee(want, wantToCharge, fees.call, callFeeRecipient);
    uint256 beefyFeeAmount = _payFee(want, wantToCharge, fees.beefy, beefyFeeRecipient);
    uint256 strategistFeeAmount = _payFee(want, wantToCharge, fees.strategist, strategist);

    emit ChargedFees(callFeeAmount, beefyFeeAmount, strategistFeeAmount);
  }

  function _payFee(address wantAddress, uint256 wantBal, uint feeRate, address feeReceiver) internal returns (uint256 feeAmount) {
    unchecked {
      feeAmount = wantBal * feeRate / DIVISOR;
    }
    IERC20(wantAddress).safeTransfer(feeReceiver, feeAmount);
  }


  function _calcBalance(Configs memory configs) internal view returns (int256 balance, int256[WANT_INDEX] memory excessDebt) {
    Config.Data memory config = configs.base;
    uint256 stakingAmount = IERC20(config.auraContracts.stakingToken)._balanceOfThis();
    if(stakingAmount == 0) {
      return (0, [int(0), 0]);
    }

    uint256[] memory withdrawAmounts = AuraLibPub.calcRemoveLiqAuraBal2Pools(
      config.balancerContracts.balancerVault,
      config.poolIds.poolId1,
      config.poolIds.poolId2,
      config.balancerContracts.bptPool1,
      config.balancerContracts.bptPool2,
      stakingAmount
    );

    unchecked {
      balance = int(IERC20(want)._balanceOfThis());
      balance += int(_balanceOfSupply(configs));

      for(uint i = 0; i < WANT_INDEX; i++) {
        address token = getTokenAddress(configs, i);

        // Get debt of each token
        (,,uint256 debtBal) = AaveLib.userReserves(token, config.aaveContracts.dataProvider);
        uint256 bal = IERC20(token)._balanceOfThis() + withdrawAmounts[i];
        excessDebt[i] = int(debtBal) - int(bal);
      }
    }
  }

  // Withdraw all funds from contracts and store them in strategy contract
  // Make sure the whole debt is repaid
  function _withdrawAll(Configs memory configs) internal returns (uint256 wantWithdrawn) {   
    Config.Data memory config = configs.base;
    uint256 stakingAmount = IERC20(config.auraContracts.stakingToken)._balanceOfThis();
    AuraLib.removeLiqAuraBal2Pools(
      config,
      configs.ext.withdrawMin,
      stakingAmount
    );

    unchecked {
      for(uint i = 0; i < WANT_INDEX; i++) {
        address token = getTokenAddress(configs, i);

        // Get debt of each token
        (,,uint256 debtAmount) = AaveLib.userReserves(token, config.aaveContracts.dataProvider);
        uint256 bal = IERC20(token)._balanceOfThis();

        if(debtAmount > bal) {
          // Withdraw some want from Aave
          uint256 wantToWithdraw = _quoteWantAave(
            configs,
            i, 
            uint8(config.decimals[i]), 
            debtAmount - bal
          ) * 105 / 100;
          
          ILendingPool(config.aaveContracts.lendingPool)._withdraw(want, wantToWithdraw, address(this));

          // Swap by debt token
          _swap(configs, wantToWithdraw, WANT_INDEX, i);
        }

        // Repay the whole debt
        ILendingPool(config.aaveContracts.lendingPool)._repay(token, debtAmount, INTEREST_RATE_MODE);

        // Swap excess by want
        _swap(configs, type(uint).max, i, WANT_INDEX);
      }
    }

    // Withdraw all want token
    wantWithdrawn =  _balanceOfSupply(configs);
    ILendingPool(config.aaveContracts.lendingPool)._withdraw(want, wantWithdrawn, address(this));
  }

  function _rebalancePosition(Configs memory configs, uint256 _chargeAmount) internal {   
    unchecked {
      Config.Data memory config = configs.base;

      if(_chargeAmount > 0) {
        _chargeForRebalance(configs, _chargeAmount);
      }
 
      // Calculate Aave position
      uint[BASE_TOKENS_COUNT] memory debtBal;
      for(uint i = 0; i < WANT_INDEX; i++) {
        (,,debtBal[i]) = AaveLib.userReserves(getTokenAddress(configs, i), config.aaveContracts.dataProvider);
      }
      
      uint256 supplyBal = _balanceOfSupply(configs);

      // Rebalance debt ratio of each token
      for(uint i = 0; i < WANT_INDEX; i++) {
        uint256 wantAmount = supplyBal * config.borrowRate / 1 ether * getProportion(configs, i)  / 1 ether;
        debtBal[i] = _rebalanceDebtRatio(
          config, 
         getTokenAddress(configs, i), 
         debtBal[i], 
         _quoteFromWantAave(configs, i, uint8(config.decimals[i]), wantAmount), 
         i,
         configs.ext.withdrawMin
        );
      }
    
      // Calculate Liquidity position
      (uint256 liquidity0,) = AuraLib.getUnderlyingAuraBal2Pools(
        config.balancerContracts.bptPool1,
        config.balancerContracts.bptPool2,
        config.auraContracts.stakingToken,
        config.poolIds.poolId1,
        config.poolIds.poolId2,
        config.balancerContracts.balancerVault
      );

      // Rebalance liquidity ratio
      _rebalanceLiqRatio0(configs, liquidity0, debtBal[0]);


      // Swap excess by want
      _swap(configs, type(uint).max, 0, WANT_INDEX);
      _swap(configs, type(uint).max, 1, WANT_INDEX);
    
      // Deposit all want
      _deposit(configs);
    }
  }

  function _chargeForRebalance(Configs memory configs, uint256 _chargeAmount) internal {
    uint256 wantAmount = ILendingPool(configs.base.aaveContracts.lendingPool)._withdraw(
      want, 
      _quoteWantAave(configs, 1, 18, _chargeAmount * 1025 / 1000), 
      address(this)
    );
    uint256 wethAmount = _swap(configs, wantAmount, 2, 1);
    IERC20(configs.base.loanToken1).safeTransfer(msg.sender, wethAmount);
    // IWrappedNative(configs.base.loanToken1).withdraw(wethAmount);
    // payable(msg.sender).transfer(wethAmount);
  }

  function _rebalanceDebtRatio(Config.Data memory config, address _token, uint _debt, uint _debtExpected, uint256 tokenIndex, uint256 _withdrawMin) internal returns(uint256) {
    unchecked {
      if(_debtExpected > _debt) {
        ILendingPool(config.aaveContracts.lendingPool)._borrow(_token, _debtExpected - _debt, INTEREST_RATE_MODE);
      }

      if(_debt > _debtExpected) {
        // Check token balance of this contract
        uint256 tokenBal = IERC20(_token)._balanceOfThis();

        // Repay if there is balance enough, if not withdraw liq. from Balancer and repay
        if(tokenBal < _debt - _debtExpected) {
          uint256 amountToUnstake = _getStakedFromUnderlying(config, _debt - _debtExpected - tokenBal, tokenIndex);
          AuraLib.removeLiqAuraBal2Pools(
            config,
            _withdrawMin,
            amountToUnstake * 105 / 100
          );
        }

        ILendingPool(config.aaveContracts.lendingPool)._repay(_token, _debt - _debtExpected, INTEREST_RATE_MODE);
      }
    }
    
    return _debtExpected;
  }

  function _rebalanceLiqRatio0(Configs memory configs,  uint256 _liquidity0, uint256 _debt0) internal {   
    Config.Data memory config = configs.base;
    unchecked {
      if(_liquidity0 > _debt0) {
        // Remove liquidity from Balancer
        AuraLib.removeLiqAuraBal2Pools(
          config,
          configs.ext.withdrawMin,
          _getStakedFromUnderlying(config, _liquidity0 - _debt0, 0)
        );
      }

      if(_debt0 > _liquidity0) {
        uint256[BASE_TOKENS_COUNT] memory excessDebtUsd;

        // Calculate USDC amount to withdraw
        excessDebtUsd[0] = _quoteWantAave(configs, 0, uint8(config.decimals[0]), _debt0 - _liquidity0);
        excessDebtUsd[1] = excessDebtUsd[0] * getProportion(configs, 1) / getProportion(configs, 0);

        while(true) {
          uint256 toWithdraw = (excessDebtUsd[0] + excessDebtUsd[1]) * 1 ether / config.borrowRate;
          if (toWithdraw == 0) {
            break;
          }

          // Calculate the max amount which can be withdrawn
          uint256 toWithdrawMax = getMaxWithdraw(config);
        
          // Withdraw USDC
          ILendingPool(config.aaveContracts.lendingPool)._withdraw(want, Math.min(toWithdraw, toWithdrawMax), address(this));

          for(uint i = 0; i < WANT_INDEX; i++) {
            // Calculate the max amounts which can be repaid
            uint toRepayMax = toWithdrawMax * config.borrowRate / 1 ether * getProportion(configs, i) / 1 ether;
            uint toRepayUsd = Math.min(excessDebtUsd[i], toRepayMax);

            // Swap USDC by BAL and ETH in the right proportions
            uint256 toRepay = _swap(configs, toRepayUsd, WANT_INDEX, i);
          
            // Repay both amounts
            ILendingPool(config.aaveContracts.lendingPool)._repay(getTokenAddress(configs, i), toRepay, INTEREST_RATE_MODE);
            excessDebtUsd[i] -= toRepayUsd;
          } 

        }

      } 
    }
  }

  function _swap(Configs memory configs, uint amountIn, uint tokenInIndex, uint tokenOutIndex) internal returns (uint amountOut) {    
    (address[] memory route, bytes32[] memory pools) = getRouteAddresses(configs, tokenInIndex, tokenOutIndex);
    
    if (amountIn == type(uint).max) {
      amountIn = IERC20(route[0])._balanceOfThis();
    }

    if(amountIn > 0) {
      address pool0 = BalancerLib.getPoolAddress(pools[0]);
      address _vault = IStablePool(pool0).getVault();

      (int256[] memory diffs) = BalancerLibPub.balancerBatchSwap(
        _vault,
        IBalancerVault.SwapKind.GIVEN_IN,
        route,
        pools,
        IBalancerVault.FundManagement(address(this), false, payable(address(this)), false),
        amountIn
      );

      amountOut = uint(-diffs[route.length - 1]);
    }
  }

  // Get stakedAmount (Aura) given the desired liquidity to withdraw
  function _getStakedFromUnderlying(Config.Data memory config, uint256 _underlyingAmount, uint256 _tokenIndex) internal view returns(uint256) {
    uint[2] memory underlyingPositionAmounts;
    (underlyingPositionAmounts[0], underlyingPositionAmounts[1]) = AuraLib.getUnderlyingAuraBal2Pools(
      config.balancerContracts.bptPool1,
      config.balancerContracts.bptPool2,
      config.auraContracts.stakingToken,
      config.poolIds.poolId1,
      config.poolIds.poolId2,
      config.balancerContracts.balancerVault
    );
    uint256 stakedAmount = IERC20(config.auraContracts.stakingToken)._balanceOfThis() * _underlyingAmount / underlyingPositionAmounts[_tokenIndex];

    return stakedAmount;
  }

  function _quoteWantUniswap(Configs memory configs, uint tokenInIndex, uint amountIn) internal view returns(uint256) {
    (address[] memory path,) = getRouteAddresses(configs, tokenInIndex, WANT_INDEX);
    
    return IUniswapRouter(unirouter).getAmountsOut(amountIn, path)[0];
  }

  
  function _quoteWantAave(Configs memory configs, uint tokenInIndex, uint decimalsIn, uint amountIn) internal view returns (uint amountOut) {
    return AaveLibPub.quoteReserves(
      getTokenAddress(configs, tokenInIndex), 
      decimalsIn, 
      amountIn,
      want,
      uint8(configs.base.decimals[WANT_INDEX]),
      configs.base.aaveContracts.priceOracle
    );
  }

  function _quoteFromWantAave(Configs memory configs, uint tokenOutIndex, uint decimalsOut, uint amountIn) internal view returns (uint amountOut) {
    return AaveLibPub.quoteReserves(
      want, 
      uint8(configs.base.decimals[WANT_INDEX]), 
      amountIn,
      getTokenAddress(configs, tokenOutIndex),
      decimalsOut,
      configs.base.aaveContracts.priceOracle
    );
  }
 
  function _quoteWantBalancer(Configs memory configs, uint tokenInIndex, uint amountIn) internal returns(uint256 amountOut) {
    (address[] memory route, bytes32[] memory pools) = getRouteAddresses(configs, tokenInIndex, WANT_INDEX);

    if(amountIn > 0) {
      address pool0 = BalancerLib.getPoolAddress(pools[0]);
      address _vault = IStablePool(pool0).getVault();

      (int256[] memory diffs) = BalancerLibPub.balancerBatchQuote(
        _vault,
        IBalancerVault.SwapKind.GIVEN_IN,
        route,
        pools,
        IBalancerVault.FundManagement(address(this), false, payable(address(this)), false),
        amountIn
      );

      amountOut = uint(-diffs[route.length - 1]);
    }
  }

  function _setAllowances(Configs memory configs, uint amount) internal {
    Config.Data memory config = configs.base;
    IERC20(want)._approve(config.aaveContracts.lendingPool, amount);
    
    unchecked{
      for(uint256 i = 0; i < WANT_INDEX; i++) {
        address token = getTokenAddress(configs, i);
        IERC20(token)._approve(config.balancerContracts.balancerVault, amount);
        IERC20(token)._approve(config.aaveContracts.lendingPool, amount);

        (, bytes32[] memory pools) = getRoute(configs, i, WANT_INDEX);
        address pool = BalancerLib.getPoolAddress(pools[0]);
        IERC20(want)._approve(IStablePool(pool).getVault(), amount);
        IERC20(token)._approve(IStablePool(pool).getVault(), amount);
      }
      
      uint rewardTokensCount = getRewardTokensCount(configs);
      for(uint256 i = 0; i < rewardTokensCount; i++) {
        uint rewardTokenIndex = getRewardToken(configs, i);
        (, bytes32[] memory pools) = getRoute(configs, rewardTokenIndex, WANT_INDEX);
        
        address rewardToken = getTokenAddress(configs, rewardTokenIndex);
        address pool = BalancerLib.getPoolAddress(pools[0]);
        IERC20(rewardToken)._approve(IStablePool(pool).getVault(), amount);
      }

    }

    IERC20(config.balancerContracts.bptPool1)._approve(config.balancerContracts.balancerVault, amount);
    IERC20(config.balancerContracts.bptPool2)._approve(config.auraContracts.booster, amount);
  }

  /******************************************************
   *                                                    *
   *                   VIEW FUNCTIONS                   *
   *                                                    *
   ******************************************************/

  function getConfig() internal view returns (Config.Data memory config){
    config = Config(configData).get();
  }

  function getConfigExt() internal view returns (ConfigExt.Data memory configExt){
    configExt = ConfigExt(configExtData).get();    
  }

  function getConfigs() public view returns (Configs memory){
    return Configs(getConfig(), getConfigExt());
  }
  
  // calculate the total underlaying 'want' held by the strat.
  function balanceOf() external view returns (uint256) {
    return _balanceOf(getConfigs());
  }

  function balanceOfPrecise() external returns (uint256) {
    return _balanceOfPrecise(getConfigs());
  }

  function _balanceOf(Configs memory configs) internal view returns (uint256) {
    (int balance, int[WANT_INDEX] memory excessDebt) = _calcBalance(configs);
    unchecked {
      for (uint i = 0; i < WANT_INDEX; i++) {
        int excessDebtSign = excessDebt[i] > 0 ? int(1) : -1;
        balance -= excessDebtSign * int(_quoteWantAave(configs, i, uint8(configs.base.decimals[i]), uint(excessDebtSign * excessDebt[i])));
      }
    }

    return uint(balance);
  }

  function _balanceOfPrecise(Configs memory configs) internal returns (uint256) {
    (int balance, int[WANT_INDEX] memory excessDebt) = _calcBalance(configs);
    unchecked {
      for (uint i = 0; i < WANT_INDEX; i++) {
        int excessDebtSign = excessDebt[i] > 0 ? int(1) : -1;
        balance -= excessDebtSign * int(_quoteWantBalancer(configs, i, uint(excessDebtSign * excessDebt[i])));
      }
    }

    return uint(balance);
   }

  // it calculates how much 'want' this contract holds.
  function balanceOfWant() external view returns (uint256) {
    return IERC20(want)._balanceOfThis();
  }

  // it calculates how much 'want' the strategy has working in the farm.
  function _balanceOfSupply(Configs memory configs) internal view returns (uint256 supplyBal) { 
    (supplyBal,,) = AaveLib.userReserves(want, configs.base.aaveContracts.dataProvider);
  }

  function getMaxWithdraw(Config.Data memory config) internal view returns (uint toWithdrawMax) {
    toWithdrawMax = AaveLibPub.getMaxWithdraw(want, uint8(config.decimals[WANT_INDEX]), config.aaveContracts.lendingPool, config.aaveContracts.priceOracle);
    require(toWithdrawMax > 0, "cannot withdraw");
  }

  // returns rewards unharvested
  function rewardsAvailable() external view returns (uint256) {
    return _rewardsAvailable(getConfigs());
  }

  function _rewardsAvailable(Configs memory configs) internal view returns (uint256) {    
    uint256 wantBal = 0;

    // Aura rewards
    address[] memory rewardersAura = configs.ext.rewardersAura;
    unchecked {
      for(uint256 i = 0; i < rewardersAura.length; i++) {
        uint256 rewardAmount = IBaseRewards(rewardersAura[i]).earned(address(this));
        if(rewardAmount > 0) {
          wantBal += _quoteWantUniswap(configs, getRewardToken(configs, i), IBaseRewards(rewardersAura[i]).earned(address(this)));
        }
      }

      // Aave rewards
      (address aWant,,) = IDataProvider(configs.base.aaveContracts.dataProvider)._getReserveTokensAddresses(want);
      (,,address vToken0) = IDataProvider(configs.base.aaveContracts.dataProvider)._getReserveTokensAddresses(configs.base.loanToken0);
      (,,address vToken1) = IDataProvider(configs.base.aaveContracts.dataProvider)._getReserveTokensAddresses(configs.base.loanToken1);

      address[] memory aaveAssets = new address[](WANT_INDEX + 1);
      aaveAssets[0] = aWant;
      aaveAssets[1] = vToken0;
      aaveAssets[2] = vToken1;

      (address[] memory rewardsAaveList, uint256[] memory rewardsAaveAmounts) = IRewardsController(configs.base.aaveContracts.rewardsController).getAllUserRewards(aaveAssets, address(this));

      uint256 aaveLength = rewardsAaveList.length;
      for(uint256 i = 0; i < aaveLength; i++) {
        uint tokenIndex = getTokenIndex(configs, rewardsAaveList[i]);
        if(rewardsAaveAmounts[i] > 0) {
          wantBal += _quoteWantUniswap(configs, tokenIndex, rewardsAaveAmounts[i]);
        }
      }

    }

    return wantBal;
  }

  // native reward amount for calling harvest
  function callReward() external view returns (uint256) {
    Configs memory configs = getConfigs();

    unchecked {
      uint256 wantBal = _rewardsAvailable(configs);
      uint256 nativeOut;
      if (wantBal > 0) {
        (address[] memory route,) = getRouteAddresses(configs, WANT_INDEX, configs.base.nativeIndex);
        uint256[] memory amountOut = IUniswapRouter(unirouter).getAmountsOut(wantBal, route);
        nativeOut = amountOut[amountOut.length - 1];
      }

      IFeeConfig.FeeCategory memory fees = getFees();
      return nativeOut * fees.total / DIVISOR * fees.call / DIVISOR;
    }
  }

  /******************************************************
   *                                                    *
   *                  ADMIN FUNCTIONS                   *
   *                                                    *
   ******************************************************/

  // Rebalance the whole position  in terms of debt ratio (Collateral vs Debt) and liquidity ratio (Debt vs Liquidity Provided)
  function rebalancePosition(uint256 chargeAmount) external onlyManager {
    _rebalancePosition(getConfigs(), chargeAmount);
  }

  // called as part of strat migration. Sends all the available funds back to the vault.
  function retireStrat() external {
    require(msg.sender == vault, "!vault");

    Configs memory configs = getConfigs();
    
    _harvest(configs, tx.origin);

    _withdrawAll(configs);

    uint256 wantBal = IERC20(want)._balanceOfThis();
    IERC20(want).safeTransfer(vault, wantBal);
  }

  // pauses deposits and withdraws all funds from third party systems.
  function panic() external onlyManager {
    _withdrawAll(getConfigs());
    pause();
  }

  function pause() public onlyManager {
    _pause();
    _setAllowances(getConfigs(), 0);
  }

  function unpause() external onlyManager {
    _unpause();

    Configs memory configs = getConfigs();
    _setAllowances(configs, type(uint).max);

    _deposit(configs);
  }

  function managerHarvest() external onlyManager {
    _harvest(getConfigs(), tx.origin);
  }

  function setConfigExt(ConfigExt.Data memory configExt) public onlyManager {
    configExtData = ImmutableStoragePub.saveStruct(abi.encode(configExt));
  }
}

