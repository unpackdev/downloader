// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./IWETH.sol";
import "./Ownable.sol";
import "./Invoke.sol";
import "./AaveCall.sol";
import "./ILeverageStake.sol";
import "./IETF.sol";
import "./IBpool.sol";
import "./IAggregationInterface.sol";

contract LeverageStake is ILeverageStake, Ownable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;
  using AaveCall for IETF;
  using Invoke for IETF;

  uint256 public constant MAX_LEVERAGE = 5000;
  uint256 public borrowRate = 670;
  uint256 public reservedAstEth;
  uint256 public defaultSlippage = 9950;
  uint public flashloanProcess;

  IAaveAddressesProvider public aaveAddressProvider =
    IAaveAddressesProvider(0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5);
  ILendingPool public lendingPool = ILendingPool(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9);
  IERC20 public stETH = IERC20(0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84);
  IWETH public WETH = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
  ILidoCurve public lidoCurve = ILidoCurve(0xDC24316b9AE028F1497c275EB9192a3Ea0f67022);
  IUniswapV3Pool public uniswapV3Pool = IUniswapV3Pool(0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640);

  address public factory;
  IETF public etf;
  IERC20 public astETH; // 0x1982b2F5814301d4e9a8b0201555376e62F82428
  IERC20 public debtToken; // 0xA9DEAc9f00Dc4310c35603FCD9D34d1A750f81Db

  constructor(address _etf, address _factory) public {
    etf = IETF(_etf);
    factory = _factory;

    DataTypes.ReserveData memory reserve = lendingPool.getReserveData(address(stETH));
    astETH = IERC20(reserve.aTokenAddress);

    DataTypes.ReserveData memory reserveDebt = lendingPool.getReserveData(address(WETH));
    debtToken = IERC20(reserveDebt.variableDebtTokenAddress);
  }

  //*********************** events ******************************

  event FactoryUpdated(address old, address newF);
  event BorrowRateChanged(uint256 oldRate, uint256 newRate);
  event BatchLeverIncreased(
    address collateralAsset,
    address borrowAsset,
    uint256 totalBorrowed,
    uint256 leverage
  );
  event BatchLeverDecreased(
    address collateralAsset,
    address repayAsset,
    uint256 totalRepay,
    bool noDebt
  );
  event LeverIncreased(address collateralAsset, address borrowAsset, uint256 borrowed);
  event LeverDecreased(address collateralAsset, address repayAsset, uint256 amount);
  event LeverIncreasedByFlashloan(address curAsset);
  event LeverDecreasedByFlashloan(address curAsset);
  event LendingPoolUpdated(address oldPool, address newPool);
  event SlippageChanged(uint256 oldSlippage, uint256 newSlippage);

  // *********************** view functions ******************************

  /// @dev Returns all the astETH balance
  /// @return balance astETH balance
  function getAstETHBalance() public view override returns (uint256 balance) {
    balance = astETH.balanceOf(etf.bPool());
  }

  function getBalanceSheet() public view override returns (uint256, uint256) {
    uint256 debtTokenBal = debtToken.balanceOf(etf.bPool());
    uint256 wethBal = WETH.balanceOf(etf.bPool());

    return (debtTokenBal, wethBal);
  }

  /// @dev Returns all the stETH balance
  /// @return balance the balance of stETH left
  function getStethBalance() public view override returns (uint256 balance) {
    balance = stETH.balanceOf(etf.bPool());
  }

  /// @dev Returns the user account data across all the reserves
  /// @return totalCollateralETH the total collateral in ETH of the user
  /// @return totalDebtETH the total debt in ETH of the user
  /// @return availableBorrowsETH the borrowing power left of the user
  /// @return currentLiquidationThreshold the liquidation threshold of the user
  /// @return ltv the loan to value of the user
  /// @return healthFactor the current health factor of the user
  function getLeverageInfo()
    public
    view
    override
    returns (
      uint256 totalCollateralETH,
      uint256 totalDebtETH,
      uint256 availableBorrowsETH,
      uint256 currentLiquidationThreshold,
      uint256 ltv,
      uint256 healthFactor
    )
  {
    (
      totalCollateralETH,
      totalDebtETH,
      availableBorrowsETH,
      currentLiquidationThreshold,
      ltv,
      healthFactor
    ) = lendingPool.getUserAccountData(etf.bPool());
  }

  // *********************** external functions ******************************

  function manualUpdatePosition() external {
    _checkTx();

    if (IBpool(etf.bPool()).isBound(address(astETH))) {
      etf.invokeRebind(address(astETH), getAstETHBalance(), 50e18, true);
    }
  }

  /// @dev Deposits an `amount` of underlying asset into the reserve
  /// @param amount The amount to be deposited to aave
  function deposit(uint256 amount) internal returns (uint256) {
    _checkTx();

    uint256 preBal = getAstETHBalance();

    // approve stETH first
    etf.invokeApprove(address(stETH), address(lendingPool), amount.add(1), true);

    // deposit stETH to aave
    etf.invokeDeposit(lendingPool, address(stETH), amount);

    return getAstETHBalance().sub(preBal);
  }

  /// @dev Allows users to borrow a specific `amount` of the reserve underlying asset
  /// @param amount The amount to be borrowed
  /// @param referralCode Code used to register the integrator originating the operation, for potential rewards.
  function borrow(uint256 amount, uint16 referralCode) internal {
    _checkTx();

    // borrow WETH
    etf.invokeBorrow(lendingPool, address(WETH), amount, 2, referralCode);

    // unwrap WETH to ETH
    etf.invokeUnwrapWETH(address(WETH), amount);
  }

  /// @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
  /// @param amount The underlying amount to be withdrawn
  function withdraw(uint256 amount) internal {
    _checkTx();

    etf.invokeWithdraw(lendingPool, address(stETH), amount);
  }

  /// @dev Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
  /// @param amount The amount to repay
  /// @return The final amount repaid
  function repayBorrow(uint256 amount) public override returns (uint256) {
    _checkTx();

    uint256 preRepay = WETH.balanceOf(etf.bPool());

    etf.invokeApprove(address(WETH), address(lendingPool), amount.add(1), true);
    etf.invokeRepay(lendingPool, address(WETH), amount, 2);

    uint256 postRepay = WETH.balanceOf(etf.bPool());

    return preRepay.sub(postRepay);
  }

  /// @dev Allows ETF to enable/disable a specific deposited asset as collateral
  /// @param _asset                The address of the underlying asset deposited
  /// @param _useAsCollateral      true` if the user wants to use the deposit as collateral, `false` otherwise
  function setUserUseReserveAsCollateral(address _asset, bool _useAsCollateral) external {
    _checkTx();

    etf.invokeSetUserUseReserveAsCollateral(lendingPool, _asset, _useAsCollateral);
  }

  /// @dev Achieves the expected leverage in batch actions repeatly
  /// @param collateral The collateral amount to use
  /// @param leverage The expected leverage
  /// @param referralCode Code used to register the integrator originating the operation, for potential rewards
  /// @param isTrade The way to get stETH, if isTrade is true, buying stETH in curve, or depositing ETH to Lido for that
  function batchIncreaseLever(
    uint256 collateral,
    uint256 leverage,
    uint16 referralCode,
    bool isTrade
  ) external override {
    _checkAction(false);

    require(leverage <= MAX_LEVERAGE, 'EXCEEDS_MAX_LEVERAGE');

    uint256 borrowSize = collateral.mul(borrowRate).div(1000);
    uint256 totalBorrowed;

    while (true) {
      uint256 newCollateral = increaseLever(borrowSize, referralCode, isTrade);

      totalBorrowed = totalBorrowed.add(borrowSize);

      borrowSize = newCollateral.mul(borrowRate).div(1000);

      if (totalBorrowed >= collateral.mul(leverage.sub(1000)).div(1000)) break;
    }

    emit BatchLeverIncreased(address(stETH), address(WETH), totalBorrowed, leverage);
  }

  /// @dev Decrease leverage in batch actions repeatly
  /// @param startAmount The start withdrawal amount for deleveraging
  function batchDecreaseLever(uint256 startAmount) external override {
    uint256 newWithdrawal = startAmount;
    uint256 totalRepay;

    bool isRepayAll;
    while (true) {
      (uint256 repay, bool noDebt) = decreaseLever(newWithdrawal);

      isRepayAll = noDebt;

      newWithdrawal = repay.mul(1000).div(borrowRate);

      totalRepay = totalRepay.add(repay);

      if (repay == 0 || noDebt) {
        break;
      }
    }

    emit BatchLeverDecreased(address(stETH), address(WETH), totalRepay, isRepayAll);
  }

  /// @dev Utilizing several DeFi protocols to increase the leverage in batch actions
  /// @param amount The initial borrow amount
  /// @param referralCode Code used to register the integrator originating the operation, for potential rewards.
  function increaseLever(
    uint256 amount,
    uint16 referralCode,
    bool isTrade
  ) public override returns (uint256) {
    _checkAction(false);

    require(amount != 0, 'ZERO AMOUNT');

    (uint256 debt, ) = getBalanceSheet();
    require(debt <= reservedAstEth.mul(MAX_LEVERAGE.sub(1000)).div(1000), 'EXCEEDS_MAX_LEVERAGE');

    // first step: borrow
    borrow(amount, referralCode);

    // second step: convert ETH to stETH
    uint256 preStETH = stETH.balanceOf(etf.bPool());
    if (isTrade) {
      exchange(0, 1, amount);
    } else {
      etf.invokeMint(address(stETH), address(0), amount);
    }

    uint256 receivedStETH = stETH.balanceOf(etf.bPool()).sub(preStETH);

    // third step: deposit stETH to aave
    uint256 astEthGot = deposit(receivedStETH);

    etf.invokeRebind(address(astETH), type(uint256).max, 50e18, true);

    emit LeverIncreased(address(stETH), address(WETH), amount);

    return astEthGot;
  }

  struct FlashCallbackData {
    uint256 curBal;
    uint256 lever;
    uint256 amount0;
    uint256 amount1;
    address caller;
    bool isDecrease;
    bool isTrade;
  }

  /// @dev Increase leverage quickly by flashloan
  /// @param lever Expected leverage to archieve, multiple by 1000
  /// @param isTrade The way to get stETH, if isTrade is true, buying stETH in curve, or depositing ETH to Lido for that
  function increaseLeverByFlashloan(uint256 lever, bool isTrade) external {
    _checkTx();
    _checkAction(false);

    require(lever > 1000, 'lever too small');
    uint256 curBal = WETH.balanceOf(etf.bPool());
    uint256 amount1 = curBal.mul(lever).div(1000).sub(curBal);

    bytes memory data = abi.encode(
      FlashCallbackData({
        curBal: curBal,
        lever: lever,
        amount0: 0,
        amount1: amount1,
        caller: msg.sender,
        isDecrease: false,
        isTrade: isTrade
      })
    );

    flashloanProcess = 1;
    uniswapV3Pool.flash(address(this), 0, amount1, data);
  }

  /// @dev Decrease leverage to zero quickly by flashloan
  function decreaseLeverByFlashloan() external {
    _checkTx();

    (uint256 debt, ) = getBalanceSheet();
    bytes memory data = abi.encode(
      FlashCallbackData({
        curBal: 0,
        lever: 0,
        amount0: 0,
        amount1: debt,
        caller: msg.sender,
        isDecrease: true,
        isTrade: true
      })
    );

    flashloanProcess = 1;
    uniswapV3Pool.flash(address(this), 0, debt, data);
  }

  /// @dev Fallback of flashloan
  /// @param _fee0 The fees of token0 to pay for flashloan
  /// @param fee1 The fees of token1 to pay for flashloan
  /// @param data the bytes data passed to callback function after a flashloan
  function uniswapV3FlashCallback(uint256 _fee0, uint256 fee1, bytes calldata data) external {
    require(msg.sender == address(uniswapV3Pool), 'not authorized');
    require(flashloanProcess == 1, 'mismatch initiated');

    reservedAstEth = 0;

    // flashloan and transfer
    uint256 bal = WETH.balanceOf(address(this));
    WETH.transfer(etf.bPool(), bal);

    FlashCallbackData memory decoded = abi.decode(data, (FlashCallbackData));
    if (decoded.isDecrease) {
      // repay aave debt
      repayBorrow(decoded.amount1);

      // withdraw stETH
      uint256 astETHBal = getAstETHBalance();
      withdraw(astETHBal);

      // convert stETH to WETH
      uint256 receivedETH = exchange(1, 0, astETHBal);
      etf.invokeWrapWETH(address(WETH), receivedETH);

      // transfer weth back
      etf.invokeTransfer(address(WETH), address(this), decoded.amount1.add(fee1), true);
      // repay WETH and fees to uniswapV3 pool
      WETH.transfer(address(uniswapV3Pool), decoded.amount1.add(fee1));

      uint256 wethBal = WETH.balanceOf(etf.bPool());
      _updatePosition(address(astETH), address(WETH), wethBal, 50e18);
      emit LeverDecreasedByFlashloan(address(WETH));
    } else {
      require(
        decoded.curBal.mul(decoded.lever).mul(borrowRate).div(1000).div(1000) >=
          decoded.amount1.add(fee1),
        'EXCEEDS'
      );

      // convert WETH to ETH
      uint256 totalWETH = WETH.balanceOf(etf.bPool());
      etf.invokeUnwrapWETH(address(WETH), totalWETH);

      // deposit to lido to get stETH
      uint256 preStETH = stETH.balanceOf(etf.bPool());
      if (decoded.isTrade) exchange(0, 1, totalWETH);
      else etf.invokeMint(address(stETH), address(0), totalWETH);
      uint256 receivedStETH = stETH.balanceOf(etf.bPool()).sub(preStETH);

      // supply stETH to aave as collateral
      deposit(receivedStETH);

      // borrow and transfer flash loan token with fees back here
      uint256 totalRepay = decoded.amount1.add(fee1);
      etf.invokeBorrow(lendingPool, address(WETH), totalRepay, 2, uint16(0));

      etf.invokeTransfer(address(WETH), address(this), totalRepay, true);
      WETH.transfer(address(uniswapV3Pool), totalRepay);

      _updatePosition(address(WETH), address(astETH), type(uint256).max, 50e18);
      emit LeverIncreasedByFlashloan(address(astETH));
    }

    flashloanProcess = 0;
  }

  /// @dev Decrease leverage in batch actions from several DeFi protocols
  /// @param amount The initial amount to input for first withdrawal
  function decreaseLever(uint256 amount) public override returns (uint256, bool) {
    require(amount != 0, 'ZERO AMOUNT');

    (uint256 debt, ) = getBalanceSheet();

    // uint256 ava = getAstETHBalance().sub(reservedAstEth.mul(99).div(100));
    uint256 ava = getAstETHBalance().sub(reservedAstEth).sub(1);

    if (ava < amount) {
      amount = ava;
    }

    uint256 repayAmount;

    if (amount > 0 && debt > 0) {
      // first step: withdraw available stETH
      withdraw(amount);

      // second step: convert stETH to ETH by curve, cause Lido deposit is irreversible
      uint256 receivedETH = exchange(1, 0, amount);

      // third step: wrap ETH to WETH
      etf.invokeWrapWETH(address(WETH), receivedETH);

      // fourth step: repay WETH to aave
      repayAmount = repayBorrow(receivedETH);

      // etf.invokeRebind(address(astETH), getAstETHBalance(), 50e18, true);

      emit LeverDecreased(address(stETH), address(WETH), amount);
    }

    return (repayAmount, debt.sub(repayAmount) == 0);
  }

  /// @dev Trading between stETH and ETH by curve
  /// @param i trade direction
  /// @param j trade direction
  /// @param dx trade amount
  function exchange(int128 i, int128 j, uint256 dx) internal returns (uint256) {
    // minimum amount expected to receive
    uint256 minDy = dx.mul(defaultSlippage).div(10000);

    uint256 callValue = i == 0 ? dx : 0;
    uint256 preEthBal = etf.bPool().balance;
    uint256 preStEthBal = stETH.balanceOf(etf.bPool());

    if (i == 1) {
      etf.invokeApprove(address(stETH), address(lidoCurve), dx, true);
    }

    bytes memory methodData = abi.encodeWithSignature(
      'exchange(int128,int128,uint256,uint256)',
      i,
      j,
      dx,
      minDy
    );

    etf.execute(address(lidoCurve), callValue, methodData, true);

    if (i == 0) {
      return stETH.balanceOf(etf.bPool()).sub(preStEthBal);
    } else {
      return (etf.bPool().balance).sub(preEthBal);
    }
  }

  /// @dev convert WETH to astETH by a batch of actions
  /// @param isTrade The way to get stETH, if isTrade is true, buying stETH in curve, or depositing ETH to Lido for that
  function convertToAstEth(bool isTrade) external override {
    _checkTx();

    uint256 convertedAmount = WETH.balanceOf(etf.bPool());

    // convert WETH to ETH
    etf.invokeUnwrapWETH(address(WETH), convertedAmount);

    // convert ETH to stETH
    uint256 receivedStEth;
    if (isTrade) {
      receivedStEth = exchange(0, 1, convertedAmount);
    } else {
      uint256 preStethBal = stETH.balanceOf(etf.bPool());
      etf.invokeMint(address(stETH), address(0), convertedAmount);

      receivedStEth = stETH.balanceOf(etf.bPool()).sub(preStethBal);
    }

    // deposit stETH to aave to get astETH
    uint256 astEthGot = deposit(receivedStEth);

    if (reservedAstEth == 0) {
      reservedAstEth = astEthGot;

      _updatePosition(address(WETH), address(astETH), getAstETHBalance(), 50e18);
    } else {
      reservedAstEth = reservedAstEth.add(astEthGot);

      etf.invokeRebind(address(astETH), getAstETHBalance(), 50e18, true);
    }
  }

  /// @dev convert astETH to WETH by a batch of actions
  function convertToWeth() external override {
    uint256 withdrawnAmount = getAstETHBalance().sub(1);

    // withdraw stETH from aave
    withdraw(withdrawnAmount);

    // convert stETH to ETH
    uint256 receivedETH = exchange(1, 0, withdrawnAmount);

    // wrap ETH to WETH
    etf.invokeWrapWETH(address(WETH), receivedETH);

    reservedAstEth = 0;

    (, uint256 wethBal) = getBalanceSheet();

    _updatePosition(address(astETH), address(WETH), wethBal, 50e18);
  }

  function setFactory(address _factory) external onlyOwner {
    require(_factory != address(0), 'ZERO ADDRESS');

    emit FactoryUpdated(factory, _factory);

    factory = _factory;
  }

  function setBorrowRate(uint256 _rate) external onlyOwner {
    require(_rate > 0 && _rate < 750, 'ZERO_LEVERAGE');

    emit BorrowRateChanged(borrowRate, _rate);

    borrowRate = _rate;
  }

  function setDefaultSlippage(uint256 _slippage) external onlyOwner {
    require(_slippage > 8000, 'INVALID_SLIPPAGE');

    emit SlippageChanged(defaultSlippage, _slippage);

    defaultSlippage = _slippage;
  }

  function updateLendingPoolInfo() external onlyOwner {
    address _lendingpool = aaveAddressProvider.getLendingPool();

    emit LendingPoolUpdated(address(lendingPool), _lendingpool);

    lendingPool = ILendingPool(_lendingpool);

    DataTypes.ReserveData memory reserve = lendingPool.getReserveData(address(stETH));
    astETH = IERC20(reserve.aTokenAddress);

    DataTypes.ReserveData memory reserveDebt = lendingPool.getReserveData(address(WETH));
    debtToken = IERC20(reserveDebt.variableDebtTokenAddress);
  }

  function _updatePosition(address token0, address token1, uint256 amount, uint256 share) internal {
    etf.invokeUnbind(token0);
    etf.invokeRebind(token1, amount, share, false);
  }

  function _checkTx() internal view {
    require(!IFactory(factory).isPaused(), 'PAUSED');

    require(etf.adminList(msg.sender) || msg.sender == address(uniswapV3Pool), 'NOT_ADMIN');

    (, uint256 collectEndTime, , , , , , , , , ) = etf.etfStatus();

    if (etf.etype() == 1) {
      require(etf.isCompletedCollect(), 'COLLECTION_FAILED');
      require(block.timestamp > collectEndTime, 'NOT_REBALANCE_PERIOD');
    }
  }

  function _checkAction(bool isDecrease) internal view {
    (, , , uint256 closureEndTime, , , , , , , ) = etf.etfStatus();

    if (etf.etype() == 1 && !isDecrease) {
      require(block.timestamp < closureEndTime, 'NOT_REBALANCE_PERIOD');
    }
  }
}
