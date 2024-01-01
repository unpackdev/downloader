// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "./SafeERC20.sol";

import "./StratFeeManagerInitializable.sol";
import "./ILendingPoolV3.sol";
import "./UniswapV3Utils.sol";
import "./ISDai.sol";
import "./IDssPsm.sol";
import "./IWrappedNative.sol";
import "./IOdyseaVault.sol";
import "./ERC20Lib.sol";
import "./AaveLib.sol";

contract StrategySDaiLeverage is StratFeeManagerInitializable {
  using SafeERC20 for IERC20;
  using {ERC20Lib._balanceOfThis, ERC20Lib._approve} for IERC20;
  using {AaveLib._deposit, AaveLib._borrow, AaveLib._repay, AaveLib._withdraw} for ILendingPool;

  address public immutable override want;
  address public immutable sDai;
  address public immutable usdc;
  address public immutable native;
  address public immutable lendingPool;
  address public immutable priceOracle;
  address public immutable dataProvider;
  address public immutable psm;
  uint256 public immutable ltv;
  uint256 public immutable decimalsDiff;

  uint256 public constant INTEREST_RATE_MODE = 2;

  uint256 public lastReserves;
  int256 public pendingRewards;

  event Deposit(uint256 tvl);
  event Withdraw(uint256 tvl);
  event ChargedFees(uint256 beefyFees);

  constructor(
    address _want,
    address _sDai,
    address _usdc,
    address _native,
    address _lendingPool,
    address _priceOracle,
    address _dataProvider,
    address _psm,
    uint256 _ltv,
    uint256 _decimalsDiff
  ) {
    want = _want;
    sDai = _sDai;
    usdc = _usdc;
    native = _native;
    lendingPool = _lendingPool;
    priceOracle = _priceOracle;
    dataProvider = _dataProvider;
    psm = _psm;
    ltv = _ltv;
    decimalsDiff = _decimalsDiff;
  }

  function initialize(
    CommonAddresses calldata _commonAddresses
  ) external initializer {
    __StratFeeManager_init(_commonAddresses);

    _setAllowances(type(uint).max);
  }

  /******************************************************
   *                                                    *
   *                  PUBLIC FUNCTIONS                  *
   *                                                    *
   ******************************************************/

  function deposit() public whenNotPaused {
    uint256 wantBal = IERC20(want)._balanceOfThis();

    if(wantBal > 0) {
      // Track pending rewards
      pendingRewards += (int(_calcBalance()) - int(lastReserves));

      // Deposit DAI on DSR
      uint256 sDaiBal = ISDai(sDai).deposit(wantBal, address(this));

      // Deposit sDAI on Aave
      ILendingPool(lendingPool)._deposit(sDai, sDaiBal);

      (,,,,uint256 ltvMax,) = ILendingPool(lendingPool).getUserAccountData(address(this));
      for(uint256 i = 0; i < 4;) {
        // Borrow USDC
        uint256 usdcBal = wantBal * ((ltvMax / 100) - 1) / 100 / decimalsDiff;
        wantBal = usdcBal * decimalsDiff;
        ILendingPool(lendingPool)._borrow(usdc, usdcBal, INTEREST_RATE_MODE);

        // Swap USDC by DAI (Uniswap V3, 0.01% fee)
        IDssPsm(psm).sellGem(address(this), usdcBal);

        // Deposit DAI on DSR
        sDaiBal = ISDai(sDai).deposit(wantBal, address(this));

        // Deposit sDAI on Aave
        ILendingPool(lendingPool)._deposit(sDai, sDaiBal);

        unchecked { ++i; }
      }

      lastReserves = _calcBalance();

      emit Deposit(_balanceOf());
    }
  }

  function withdraw(uint256 _amount) external {
    require(msg.sender == vault, "!vault");

    bool isFullWithdrawal = _amount >= _balanceOf();

    // Track pending rewards
    pendingRewards += (int(_calcBalance()) - int(lastReserves));

    uint256 wantBal = IERC20(want)._balanceOfThis();

    if(wantBal < _amount) {
      // Calculate amount to repay in want
      uint256 loanWantAmount = (_amount * ltv) / (1 ether - ltv);

      // Calculate loanAmount in USDC
      uint256 loanAmount = loanWantAmount / decimalsDiff;

      // Flashloan to repay debt
      ILendingPool(lendingPool).flashLoanSimple(
        address(this),
        usdc,
        loanAmount,
        abi.encode(isFullWithdrawal ? type(uint).max : loanAmount * 1 ether / ltv),
        0
      );

      wantBal = IERC20(want)._balanceOfThis();
    }

    unchecked {
      IERC20(want).safeTransfer(vault, wantBal);
    }

    lastReserves = _calcBalance();

    emit Withdraw(_balanceOf());
  }

  function executeOperation(
    address asset,
    uint256 amount,
    uint256 premium,
    address initiator,
    bytes calldata params
  ) external returns (bool) {
    require(msg.sender == lendingPool, "Only Aave Pool");
    require(initiator == address(this), "Only strategy can initiate");

    // Repay debt
    ILendingPool(lendingPool)._repay(asset, amount, INTEREST_RATE_MODE);

    // Withdraw
    (uint256 withdrawAmount) = abi.decode(params, (uint256));
    if(withdrawAmount != type(uint).max) {
      withdrawAmount = ISDai(sDai).convertToShares((withdrawAmount + 2) * decimalsDiff);
    }

    uint256 sDaiAmount = ILendingPool(lendingPool)._withdraw(
      sDai, 
      withdrawAmount,
      address(this)
    );

    // Redeem sDai by Dai (want)
    ISDai(sDai).redeem(sDaiAmount, address(this), address(this));

    // Swap what's needed in USDC to payback flashloan
    IDssPsm(psm).buyGem(address(this), amount + premium);
    
    return true;
  }

  function beforeDeposit() external override {}


  /******************************************************
   *                                                    *
   *                 INTERNAL FUNCTIONS                 *
   *                                                    *
   ******************************************************/

  function _chargeManagement(uint256 _chargeAmount) internal {
    if(_chargeAmount > 0) {
      uint256 sDaiAmount = ILendingPool(lendingPool)._withdraw(
        sDai, 
        AaveLibPub.quoteReserves(
          native, 
          18, 
          _chargeAmount,
          sDai,
          18,
          priceOracle
        ),
        address(this)
      );

      uint256 wantAmount = ISDai(sDai).redeem(sDaiAmount, address(this), address(this));
      uint256 wethAmount = UniswapV3Utils.swapSingleInput(unirouter, want, native, 3000, wantAmount);
      IWrappedNative(native).withdraw(wethAmount);
      payable(msg.sender).transfer(wethAmount);
    }
  }

  function _calcBalance() internal view returns (uint256 wantWithdrawn) {
    // Get supply and debt
    (uint256 supplyBal,,) = AaveLib.userReserves(sDai, dataProvider);
    (,,uint256 debtBal) = AaveLib.userReserves(usdc, dataProvider);

    // Calculate supply in DAI (convertToAssets)
    uint256 supplyBalWant = ISDai(sDai).convertToAssets(supplyBal);

    // Calculate debt in DAI (aaveLibPub)
    uint256 debtBalWant = debtBal * decimalsDiff;

    // Calculate pending fees
    uint256 pendingFees = pendingRewards > 0 ? uint(pendingRewards) * getFees().total / DIVISOR : 0;

    // Supply - Debt - pending Fees
    return supplyBalWant > debtBalWant + pendingFees ? supplyBalWant - debtBalWant - pendingFees : 0;
  }

  function _withdrawAll() internal {
    // Get total debt
    (,,uint256 debtBal) = AaveLib.userReserves(usdc, dataProvider);

    // Flashloan to repay debt
    ILendingPool(lendingPool).flashLoanSimple(
      address(this),
      usdc,
      debtBal,
      abi.encode(type(uint).max),
      0
    );

    // Last reserves set to 0
    lastReserves = 0;
    pendingRewards = 0;
  }


  function _setAllowances(uint256 amount) internal {
    IERC20(sDai)._approve(lendingPool, amount);
    IERC20(usdc)._approve(lendingPool, amount);
    IERC20(want)._approve(sDai, amount);
    IERC20(usdc)._approve(IDssPsm(psm).gemJoin(), amount);
    IERC20(want)._approve(psm, amount);
    IERC20(usdc)._approve(unirouter, amount);
    IERC20(want)._approve(unirouter, amount);
  }

  /******************************************************
   *                                                    *
   *                   VIEW FUNCTIONS                   *
   *                                                    *
   ******************************************************/

  function balanceOf() external view returns (uint256) {
    return _balanceOf();
  }

  function balanceOfPrecise() external view returns (uint256) {
    return _balanceOf();
  }
  function _balanceOf() internal view returns (uint256) {
    return IERC20(want)._balanceOfThis() + _calcBalance();
  }
  function balanceOfWant() external view returns (uint256) {
    return IERC20(want)._balanceOfThis();
  }
  
  
  function callReward() external view returns (uint256) {
    int pendingRewardsUpdated = pendingRewards + int(_calcBalance()) - int(lastReserves);
    uint256 nativeOut;
    if (pendingRewardsUpdated > 0) {
      nativeOut = AaveLibPub.quoteReserves(want, 18, uint(pendingRewardsUpdated), native, 18, priceOracle);
    }

    IFeeConfig.FeeCategory memory fees = getFees();
    return nativeOut * fees.total / DIVISOR;
  }

  /******************************************************
   *                                                    *
   *                  ADMIN FUNCTIONS                   *
   *                                                    *
   ******************************************************/

  function work(uint256 _chargeAmount) external onlyManager {
    // Charge
    _chargeManagement(_chargeAmount);

    IOdyseaVault(vault).work();
  }
  
  function chargeFees(uint256 _chargeAmount) external onlyManager {
    pendingRewards += (int(_calcBalance()) - int(lastReserves));

    if(pendingRewards <= 0) return;

    // Charge
    _chargeManagement(_chargeAmount);
    
    // Apply the fee percentage to the difference
    IFeeConfig.FeeCategory memory fees = getFees();

    uint256 wantToCharge = uint(pendingRewards) * fees.total / DIVISOR;

    uint256 wantBal = IERC20(want)._balanceOfThis();

    if(wantBal < wantToCharge) {
      // Calculate amount to repay in want
      uint256 loanWantAmount = ((wantToCharge) * ltv) / (1 ether - ltv);

      // Calculate loanAmount in USDC
      uint256 loanAmount = loanWantAmount / decimalsDiff;

      // Flashloan to repay debt
      ILendingPool(lendingPool).flashLoanSimple(
        address(this),
        usdc,
        loanAmount,
        abi.encode(loanAmount * 1 ether / ltv),
        0
      );

      wantBal = IERC20(want)._balanceOfThis();
    }


    IERC20(want).safeTransfer(beefyFeeRecipient, wantBal);

    pendingRewards = 0;
    lastReserves = _calcBalance();

    emit ChargedFees(wantBal);
  }

  function rebalancePosition(uint256 _chargeAmount) external onlyManager {
    // Track pending rewards
    pendingRewards += (int(_calcBalance()) - int(lastReserves));

    // Charge
    _chargeManagement(_chargeAmount);
    
    (uint256 collateral, uint256 debt,,,,) = ILendingPool(lendingPool).getUserAccountData(address(this));
    uint256 currentLtv = debt * 1 ether / collateral;
    if(currentLtv < ltv) {
      // Leverage
      uint256 desiredDebt = ltv * collateral / 1 ether;
      uint256 toBorrow = AaveLibPub.quoteReserveFromBase(desiredDebt - debt, usdc, 6, priceOracle);
      ILendingPool(lendingPool)._borrow(usdc, toBorrow, INTEREST_RATE_MODE);

      IDssPsm(psm).sellGem(address(this), toBorrow);

      deposit();
    }

    if(currentLtv > ltv) {
      // Deleverage
      uint256 flashLoanAmount = AaveLibPub.quoteReserveFromBase((1 ether * debt - ltv * collateral) / (1 ether - ltv), usdc, 6, priceOracle);
      ILendingPool(lendingPool).flashLoanSimple(
        address(this),
        usdc,
        flashLoanAmount,
        abi.encode(flashLoanAmount +  (flashLoanAmount * (ILendingPool(lendingPool).FLASHLOAN_PREMIUM_TOTAL()) / 10000)),
        0
      );
    }

    // Update lastReserves
    lastReserves = _calcBalance();
  }
  
  function retireStrat() external {
    require(msg.sender == vault, "!vault");

    _withdrawAll();

    uint256 wantBal = IERC20(want)._balanceOfThis();
    IERC20(want).safeTransfer(vault, wantBal);
  }

  function panic() external onlyManager {
    _withdrawAll();
    pause();
  }

  function pause() public onlyManager {
    _pause();
    _setAllowances(0);
  }

  function unpause() external onlyManager {
    _unpause();

    _setAllowances(type(uint).max);

    deposit();
  }
  
  receive() external payable {}
}