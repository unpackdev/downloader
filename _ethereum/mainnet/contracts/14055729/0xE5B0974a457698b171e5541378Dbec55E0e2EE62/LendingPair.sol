// SPDX-License-Identifier: UNLICENSED

// Copyright (c) WildCredit - All rights reserved
// https://twitter.com/WildCredit

pragma solidity 0.8.6;

import "IERC20.sol";
import "IERC721.sol";
import "ICallee.sol";
import "ILendingPair.sol";
import "ILPTokenMaster.sol";
import "ILendingController.sol";
import "IUniswapV3Helper.sol";
import "INonfungiblePositionManagerSimple.sol";

import "Math.sol";
import "Clones.sol";
import "ReentrancyGuard.sol";
import "AddressLibrary.sol";

import "LPTokenMaster.sol";

import "ERC721Receivable.sol";
import "TransferHelper.sol";

contract LendingPair is ILendingPair, ReentrancyGuard, TransferHelper, ERC721Receivable {

  INonfungiblePositionManagerSimple internal constant positionManager = INonfungiblePositionManagerSimple(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);
  IERC721 internal constant uniPositions = IERC721(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);
  uint    public   constant LIQ_MIN_HEALTH = 1e18;
  uint    private  constant MIN_DECIMALS = 6;

  using AddressLibrary for address;
  using Clones for address;

  mapping (address => mapping (address => uint)) public override supplySharesOf;
  mapping (address => mapping (address => uint)) public debtSharesOf;
  mapping (address => uint) public override pendingSystemFees;
  mapping (address => uint) public lastBlockAccrued;
  mapping (address => uint) public override totalSupplyShares;
  mapping (address => uint) public override totalSupplyAmount;
  mapping (address => uint) public override totalDebtShares;
  mapping (address => uint) public override totalDebtAmount;
  mapping (address => uint) public uniPosition;
  mapping (address => uint) private decimals;
  mapping (address => address) public override lpToken;

  IUniswapV3Helper   private uniV3Helper;
  ILendingController public  lendingController;

  address public feeRecipient;
  address public override tokenA;
  address public override tokenB;

  event Liquidation(
    address indexed account,
    address indexed repayToken,
    address indexed supplyToken,
    uint repayAmount,
    uint supplyAmount
  );

  event Deposit(address indexed account, address indexed token, uint amount);
  event Withdraw(address indexed account, address indexed token, uint amount);
  event Borrow(address indexed account, address indexed token, uint amount);
  event Repay(address indexed account, address indexed token, uint amount);
  event CollectSystemFee(address indexed token, uint amount);
  event DepositUniPosition(address indexed account, uint positionID);
  event WithdrawUniPosition(address indexed account, uint positionID);

  modifier onlyLpToken() {
    require(lpToken[tokenA] == msg.sender || lpToken[tokenB] == msg.sender, "LendingController: caller must be LP token");
    _;
  }

  function initialize(
    address _lpTokenMaster,
    address _lendingController,
    address _uniV3Helper,
    address _feeRecipient,
    address _tokenA,
    address _tokenB
  ) external override {
    require(tokenA == address(0), "LendingPair: already initialized");

    lendingController = ILendingController(_lendingController);
    uniV3Helper       = IUniswapV3Helper(_uniV3Helper);
    feeRecipient      = _feeRecipient;
    tokenA = _tokenA;
    tokenB = _tokenB;
    lastBlockAccrued[tokenA] = block.number;
    lastBlockAccrued[tokenB] = block.number;

    decimals[tokenA] = IERC20(tokenA).decimals();
    decimals[tokenB] = IERC20(tokenB).decimals();

    require(decimals[tokenA] >= MIN_DECIMALS && decimals[tokenB] >= MIN_DECIMALS, "LendingPair: MIN_DECIMALS");

    lpToken[tokenA] = _createLpToken(_lpTokenMaster, tokenA);
    lpToken[tokenB] = _createLpToken(_lpTokenMaster, tokenB);
  }

  function operate(
    uint[] calldata _actions,
    bytes[] calldata _data
  ) external override payable nonReentrant {

    if (msg.value > 0) {
      _depositWeth();
      _safeTransfer(address(WETH), msg.sender, msg.value);
    }

    bool needReserveCheck = false;

    for (uint i = 0; i < _actions.length; i++) {

      if (_actions[i] == 0) {
        (address account, uint positionID) = abi.decode(_data[i], (address, uint));
        _depositUniPosition(account, positionID);
      }

      else if (_actions[i] == 1) {
        _withdrawUniPosition();
        needReserveCheck = true;
      }

      else if (_actions[i] == 2) {
        (address account, address token, uint amount) = abi.decode(_data[i], (address, address, uint));
        _deposit(account, token, amount);
      }

      else if (_actions[i] == 3) {
        (address recipient, address token, uint amount) = abi.decode(_data[i], (address, address, uint));
        _withdraw(recipient, token, amount);
        needReserveCheck = true;
      }

      else if (_actions[i] == 4) {
        (address recipient, address token) = abi.decode(_data[i], (address, address));
        _withdrawAll(recipient, token);
        needReserveCheck = true;
      }

      else if (_actions[i] == 5) {
        (address recipient, address token, uint amount) = abi.decode(_data[i], (address, address, uint));
        _borrow(recipient, token, amount);
        needReserveCheck = true;
      }

      else if (_actions[i] == 6) {
        (address account, address token, uint maxAmount) = abi.decode(_data[i], (address, address, uint));
        _repay(account, token, maxAmount);
      }

      else if (_actions[i] == 7) {
        (address account, address repayToken, uint repayAmount) = abi.decode(_data[i], (address, address, uint));
        _liquidateAccount(account, repayToken, repayAmount);
        needReserveCheck = true;
      }

      else if (_actions[i] == 8) {
        (address callee, bytes memory data) = abi.decode(_data[i], (address, bytes));
        _call(callee, data);
      }

      else {
        revert("LendingPair: unknown action");
      }
    }

    if (needReserveCheck) {
      checkAccountHealth(msg.sender);
      _checkReserve(tokenA);
      _checkReserve(tokenB);
    }
  }

  function depositUniPosition(address _account, uint _positionID) external nonReentrant {
    _depositUniPosition(_account, _positionID);
  }

  function withdrawUniPosition() external nonReentrant {
    _withdrawUniPosition();
    checkAccountHealth(msg.sender);
  }

  function deposit(address _account, address _token, uint _amount) external nonReentrant {
    _deposit(_account, _token, _amount);
  }

  function withdraw(address _recipient, address _token, uint _amount) external nonReentrant {
    _withdraw(_recipient, _token, _amount);
    checkAccountHealth(msg.sender);
    _checkReserve(_token);
  }

  function withdrawAll(address _recipient, address _token) external nonReentrant {
    _withdrawAll(_recipient, _token);
    checkAccountHealth(msg.sender);
    _checkReserve(_token);
  }

  function borrow(address _recipient, address _token, uint _amount) external nonReentrant {
    _borrow(_recipient, _token, _amount);
    checkAccountHealth(msg.sender);
    _checkReserve(_token);
  }

  function repay(address _account, address _token, uint _maxAmount) external nonReentrant {
    _repay(_account, _token, _maxAmount);
  }

  function liquidateAccount(address _account, address _repayToken, uint _repayAmount) external nonReentrant {
    _liquidateAccount(_account, _repayToken, _repayAmount);
    checkAccountHealth(msg.sender);
    _checkReserve(tokenA);
    _checkReserve(tokenB);
  }

  function accrue(address _token) public {
    if (lastBlockAccrued[_token] < block.number) {
      uint newDebt   = _accrueDebt(_token);
      uint newSupply = newDebt * _lpRate() / 100e18;
      totalSupplyAmount[_token] += newSupply;

      // '-1' helps prevent _checkReserve fails due to rounding errors
      uint newFees = (newDebt - newSupply) == 0 ? 0 : (newDebt - newSupply - 1);
      pendingSystemFees[_token] += newFees;

      lastBlockAccrued[_token] = block.number;
    }
  }

  function collectSystemFee(address _token, uint _amount) external nonReentrant {
    _validateToken(_token);
    pendingSystemFees[_token] -= _amount;
    _safeTransfer(_token, feeRecipient, _amount);
    _checkReserve(_token);
    emit CollectSystemFee(_token, _amount);
  }

  function transferLp(address _token, address _from, address _to, uint _amount) external override onlyLpToken {
    require(debtSharesOf[_token][_to] == 0, "LendingPair: cannot receive borrowed token");
    supplySharesOf[_token][_from] -= _amount;
    supplySharesOf[_token][_to]   += _amount;
    checkAccountHealth(_from);
  }

  function accountHealth(address _account) external view returns(uint) {
    (uint priceA, uint priceB) = lendingController.tokenPrices(tokenA, tokenB);
    return _accountHealth(_account, priceA, priceB);
  }

  function debtOf(address _token, address _account) external view override returns(uint) {
    _validateToken(_token);
    return _debtOf(_token, _account);
  }

  function supplyOf(address _token, address _account) external view override returns(uint) {
    _validateToken(_token);
    return _supplyOf(_token, _account);
  }

  // Get borow balance converted to the units of _returnToken
  function borrowBalanceConverted(
    address _account,
    address _borrowedToken,
    address _returnToken
  ) external view returns(uint) {

    _validateToken(_borrowedToken);
    _validateToken(_returnToken);

    (uint borrowPrice, uint returnPrice) = lendingController.tokenPrices(_borrowedToken, _returnToken);
    return _borrowBalanceConverted(_account, _borrowedToken, _returnToken, borrowPrice, returnPrice);
  }

  function supplyBalanceConverted(
    address _account,
    address _suppliedToken,
    address _returnToken
  ) external view override returns(uint) {

    _validateToken(_suppliedToken);
    _validateToken(_returnToken);

    (uint supplyPrice, uint returnPrice) = lendingController.tokenPrices(_suppliedToken, _returnToken);
    return _supplyBalanceConverted(_account, _suppliedToken, _returnToken, supplyPrice, returnPrice);
  }

  function supplyRatePerBlock(address _token) external view returns(uint) {
    _validateToken(_token);
    if (totalSupplyAmount[_token] == 0 || totalDebtAmount[_token] == 0) { return 0; }
    return _interestRatePerBlock(_token) * utilizationRate(_token) * _lpRate() / 100e18 / 100e18;
  }

  function borrowRatePerBlock(address _token) external view returns(uint) {
    _validateToken(_token);
    return _interestRatePerBlock(_token);
  }

  function utilizationRate(address _token) public view returns(uint) {
    uint totalSupply = totalSupplyAmount[_token];
    uint totalDebt = totalDebtAmount[_token];
    if (totalSupply == 0 || totalDebt == 0) { return 0; }
    return Math.min(totalDebt * 100e18 / totalSupply, 100e18);
  }

  function checkAccountHealth(address _account) public view {
    (uint priceA, uint priceB) = lendingController.tokenPrices(tokenA, tokenB);
    uint health = _accountHealth(_account, priceA, priceB);
    require(health >= LIQ_MIN_HEALTH, "LendingPair: insufficient accountHealth");
  }

  function convertTokenValues(
    address _fromToken,
    address _toToken,
    uint    _inputAmount
  ) external view returns(uint) {

    _validateToken(_fromToken);
    _validateToken(_toToken);

    (uint fromPrice, uint toPrice) = lendingController.tokenPrices(_fromToken, _toToken);
    return _convertTokenValues(_fromToken, _toToken, _inputAmount, fromPrice, toPrice);
  }

  // Deposit limits do not apply to Uniswap positions
  function _depositUniPosition(address _account, uint _positionID) internal {
    _validateUniPosition(_positionID);
    require(_positionID > 0, "LendingPair: invalid position");
    require(uniPosition[_account] == 0, "LendingPair: one position per account");

    uniPositions.safeTransferFrom(msg.sender, address(this), _positionID);
    uniPosition[_account] = _positionID;

    emit DepositUniPosition(_account, _positionID);
  }

  function _withdrawUniPosition() internal {
    uint positionID = uniPosition[msg.sender];
    require(positionID > 0, "LendingPair: nothing to withdraw");
    uniPositions.safeTransferFrom(address(this), msg.sender, positionID);
    uniPosition[msg.sender] = 0;

    accrue(tokenA);
    accrue(tokenB);

    emit WithdrawUniPosition(msg.sender, positionID);
  }

  function _deposit(address _account, address _token, uint _amount) internal {
    _validateToken(_token);
    accrue(_token);

    require(debtSharesOf[_token][_account] == 0, "LendingPair: cannot deposit borrowed token");

    _checkDepositLimit(_token, _amount);
    _mintSupplyAmount(_token, _account, _amount);
    _safeTransferFrom(_token, msg.sender, _amount);

    emit Deposit(_account, _token, _amount);
  }

  function _withdraw(address _recipient, address _token, uint _amount) internal {
    _validateToken(_token);
    accrue(_token);

    _withdrawShares(_token, _supplyToShares(_token, _amount));
    _transferAsset(_token, _recipient, _amount);
  }

  function _borrow(address _recipient, address _token, uint _amount) internal {
    _validateToken(_token);
    accrue(_token);

    require(supplySharesOf[_token][msg.sender] == 0, "LendingPair: cannot borrow supplied token");

    _mintDebtAmount(_token, msg.sender, _amount);
    _checkBorrowLimits(_token, msg.sender);
    _transferAsset(_token, _recipient, _amount);

    emit Borrow(msg.sender, _token, _amount);
  }

  function _withdrawAll(address _recipient, address _token) internal {
    _validateToken(_token);
    accrue(_token);

    uint shares = supplySharesOf[_token][msg.sender];
    uint amount = _sharesToSupply(_token, shares);
    _withdrawShares(_token, shares);
    _transferAsset(_token, _recipient, amount);
  }

  function _repay(address _account, address _token, uint _maxAmount) internal {
    _validateToken(_token);
    accrue(_token);

    uint maxShares    = _debtToShares(_token, _maxAmount);
    uint sharesAmount = Math.min(debtSharesOf[_token][_account], maxShares);
    uint repayAmount  = _repayShares(_account, _token, sharesAmount);

    _checkBorrowLimits(_token, _account);
    _safeTransferFrom(_token, msg.sender, repayAmount);
  }

  // Sell collateral to reduce debt and increase accountHealth
  // Set _repayAmount to type(uint).max to repay all debt, inc. pending interest
  function _liquidateAccount(
    address _account,
    address _repayToken,
    uint    _repayAmount
  ) internal {

    // Input validation and adjustments

    _validateToken(_repayToken);

    address supplyToken = _repayToken == tokenA ? tokenB : tokenA;

    // Check account is underwater after interest

    accrue(supplyToken);
    accrue(_repayToken);

    (uint priceA, uint priceB) = lendingController.tokenPrices(tokenA, tokenB);

    uint health = _accountHealth(_account, priceA, priceB);
    require(health < LIQ_MIN_HEALTH, "LendingPair: account health < LIQ_MIN_HEALTH");

    // Fully unwrap Uni position - withdraw & mint supply

    _unwrapUniPosition(_account, priceA, priceB);

    // Calculate balance adjustments

    _repayAmount = Math.min(_repayAmount, _debtOf(_repayToken, _account));

    // Avoiding stack too deep error
    uint supplyDebt = _convertTokenValues(
      _repayToken,
      supplyToken,
      _repayAmount,
      _repayToken == tokenA ? priceA : priceB, // repayPrice
      supplyToken == tokenA ? priceA : priceB  // supplyPrice
    );

    uint callerFee    = supplyDebt * lendingController.liqFeeCaller(_repayToken) / 100e18;
    uint systemFee    = supplyDebt * lendingController.liqFeeSystem(_repayToken) / 100e18;
    uint supplyBurn   = supplyDebt + callerFee + systemFee;
    uint supplyOutput = supplyDebt + callerFee;

    // Adjust balances

    _burnSupplyShares(supplyToken, _account, _supplyToShares(supplyToken, supplyBurn));
    pendingSystemFees[supplyToken] += systemFee;
    _burnDebtShares(_repayToken, _account, _debtToShares(_repayToken, _repayAmount));

    // Uni position unwrapping can mint supply of already borrowed tokens

    _repayDebtFromSupply(_account, tokenA);
    _repayDebtFromSupply(_account, tokenB);

    // Settle token transfers

    _safeTransferFrom(_repayToken, msg.sender, _repayAmount);
    _mintSupplyAmount(supplyToken, msg.sender, supplyOutput);

    _checkBorrowLimits(_repayToken, _account);

    emit Liquidation(_account, _repayToken, supplyToken, _repayAmount, supplyOutput);
  }

  function _call(address _callee, bytes memory _data) internal {
    ICallee(_callee).wildCall(_data);
  }

  // Uses price oracle to estimate min outputs to reduce MEV
  // Liquidation might be temporarily unavailable due to this
  function _unwrapUniPosition(address _account, uint _priceA, uint _priceB) internal {

    if (uniPosition[_account] > 0) {

      (uint amount0, uint amount1) = _positionAmounts(uniPosition[_account], _priceA, _priceB);
      uint uniMinOutput = lendingController.uniMinOutputPct();

      uniPositions.approve(address(uniV3Helper), uniPosition[_account]);
      (uint amountA, uint amountB) = uniV3Helper.removeLiquidity(
        uniPosition[_account],
        amount0 * uniMinOutput / 100e18,
        amount1 * uniMinOutput / 100e18
      );
      uniPosition[_account] = 0;

      _mintSupplyAmount(tokenA, _account, amountA);
      _mintSupplyAmount(tokenB, _account, amountB);
    }
  }

  // Ensure we never have borrow + supply balances of the same token on the same account
  function _repayDebtFromSupply(address _account, address _token) internal {

    uint burnAmount = Math.min(_debtOf(_token, _account), _supplyOf(_token, _account));

    if (burnAmount > 0) {
      _burnDebtShares(_token, _account, _debtToShares(_token, burnAmount));
      _burnSupplyShares(_token, _account, _supplyToShares(_token, burnAmount));
    }
  }

  function _mintSupplyAmount(address _token, address _account, uint _amount) internal returns(uint shares) {
    if (_amount > 0) {
      shares = _supplyToShares(_token, _amount);
      supplySharesOf[_token][_account] += shares;
      totalSupplyShares[_token] += shares;
      totalSupplyAmount[_token] += _amount;
    }
  }

  function _burnSupplyShares(address _token, address _account, uint _shares) internal returns(uint amount) {
    if (_shares > 0) {
      // Fix rounding error which can make issues during depositRepay / withdrawBorrow
      if (supplySharesOf[_token][_account] - _shares == 1) { _shares += 1; }
      amount = _sharesToSupply(_token, _shares);
      supplySharesOf[_token][_account] -= _shares;
      totalSupplyShares[_token] -= _shares;
      totalSupplyAmount[_token] -= amount;
    }
  }

  function _mintDebtAmount(address _token, address _account, uint _amount) internal returns(uint shares) {
    if (_amount > 0) {
      shares = _debtToShares(_token, _amount);
      debtSharesOf[_token][_account] += shares;
      totalDebtShares[_token] += shares;
      totalDebtAmount[_token] += _amount;
    }
  }

  function _burnDebtShares(address _token, address _account, uint _shares) internal returns(uint amount) {
    if (_shares > 0) {
      // Fix rounding error which can make issues during depositRepay / withdrawBorrow
      if (debtSharesOf[_token][_account] - _shares == 1) { _shares += 1; }
      amount = _sharesToDebt(_token, _shares);
      debtSharesOf[_token][_account] -= _shares;
      totalDebtShares[_token] -= _shares;
      totalDebtAmount[_token] -= amount;
    }
  }

  function _accrueDebt(address _token) internal returns(uint newDebt) {
    if (totalDebtAmount[_token] > 0) {
      uint blocksElapsed = block.number - lastBlockAccrued[_token];
      uint pendingInterestRate = _interestRatePerBlock(_token) * blocksElapsed;
      newDebt = totalDebtAmount[_token] * pendingInterestRate / 100e18;
      totalDebtAmount[_token] += newDebt;
    }
  }

  function _withdrawShares(address _token, uint _shares) internal {
    uint amount = _burnSupplyShares(_token, msg.sender, _shares);
    emit Withdraw(msg.sender, _token, amount);
  }

  function _repayShares(address _account, address _token, uint _shares) internal returns(uint amount) {
    amount = _burnDebtShares(_token, _account, _shares);
    emit Repay(_account, _token, amount);
  }

  function _transferAsset(address _asset, address _to, uint _amount) internal {
    if (_asset == address(WETH)) {
      _wethWithdrawTo(_to, _amount);
    } else {
      _safeTransfer(_asset, _to, _amount);
    }
  }

  function _createLpToken(address _lpTokenMaster, address _underlying) internal returns(address) {
    ILPTokenMaster newLPToken = ILPTokenMaster(_lpTokenMaster.clone());
    newLPToken.initialize(_underlying, address(lendingController));
    return address(newLPToken);
  }

  // Compare all supply & borrow balances converted into the the same token - tokenA
  function _accountHealth(address _account, uint _priceA, uint _priceB) internal view returns(uint) {

    if (debtSharesOf[tokenA][_account] == 0 && debtSharesOf[tokenB][_account] == 0) {
      return LIQ_MIN_HEALTH;
    }

    uint colFactorA = lendingController.colFactor(tokenA);
    uint colFactorB = lendingController.colFactor(tokenB);

    uint creditA   = _supplyOf(tokenA, _account) * colFactorA / 100e18;
    uint creditB   = _supplyBalanceConverted(_account, tokenB, tokenA, _priceB, _priceA) * colFactorB / 100e18;
    uint creditUni = _convertedCreditAUni(_account, _priceA, _priceB, colFactorA, colFactorB);

    uint totalAccountSupply = creditA + creditB + creditUni;

    uint totalAccountBorrow = _debtOf(tokenA, _account) + _borrowBalanceConverted(_account, tokenB, tokenA, _priceB, _priceA);

    return totalAccountSupply * 1e18 / totalAccountBorrow;
  }

  function _amountToShares(uint _totalShares, uint _totalAmount, uint _inputSupply) internal view returns(uint) {
    if (_totalShares > 0 && _totalAmount > 0) {
      return _inputSupply * _totalShares / _totalAmount;
    } else {
      return _inputSupply;
    }
  }

  function _sharesToAmount(uint _totalShares, uint _totalAmount, uint _inputShares) internal view returns(uint) {
    if (_totalShares > 0 && _totalAmount > 0) {
      return _inputShares * _totalAmount / _totalShares;
    } else {
      return _inputShares;
    }
  }

  function _debtToShares(address _token, uint _amount) internal view returns(uint) {
    return _amountToShares(totalDebtShares[_token], totalDebtAmount[_token], _amount);
  }

  function _sharesToDebt(address _token, uint _shares) internal view returns(uint) {
    return _sharesToAmount(totalDebtShares[_token], totalDebtAmount[_token], _shares);
  }

  function _supplyToShares(address _token, uint _amount) internal view returns(uint) {
    return _amountToShares(totalSupplyShares[_token], totalSupplyAmount[_token], _amount);
  }

  function _sharesToSupply(address _token, uint _shares) internal view returns(uint) {
    return _sharesToAmount(totalSupplyShares[_token], totalSupplyAmount[_token], _shares);
  }

  function _debtOf(address _token, address _account) internal view returns(uint) {
    return _sharesToDebt(_token, debtSharesOf[_token][_account]);
  }

  function _supplyOf(address _token, address _account) internal view returns(uint) {
    return _sharesToSupply(_token, supplySharesOf[_token][_account]);
  }

  // Get borrow balance converted to the units of _returnToken
  function _borrowBalanceConverted(
    address _account,
    address _borrowedToken,
    address _returnToken,
    uint    _borrowPrice,
    uint    _returnPrice
  ) internal view returns(uint) {

    return _convertTokenValues(
      _borrowedToken,
      _returnToken,
      _debtOf(_borrowedToken, _account),
      _borrowPrice,
      _returnPrice
    );
  }

  // Get supply balance converted to the units of _returnToken
  function _supplyBalanceConverted(
    address _account,
    address _suppliedToken,
    address _returnToken,
    uint    _supplyPrice,
    uint    _returnPrice
  ) internal view returns(uint) {

    return _convertTokenValues(
      _suppliedToken,
      _returnToken,
      _supplyOf(_suppliedToken, _account),
      _supplyPrice,
      _returnPrice
    );
  }

  function _convertedCreditAUni(
    address _account,
    uint    _priceA,
    uint    _priceB,
    uint    _colFactorA,
    uint    _colFactorB
  ) internal view returns(uint) {

    if (uniPosition[_account] > 0) {

      (uint amountA, uint amountB) = _positionAmounts(uniPosition[_account], _priceA, _priceB);

      uint creditA = amountA * _colFactorA / 100e18;
      uint creditB = _convertTokenValues(tokenB, tokenA, amountB, _priceB, _priceA) * _colFactorB / 100e18;

      return (creditA + creditB);

    } else {
      return 0;
    }
  }

  function _positionAmounts(
    uint _position,
    uint _priceA,
    uint _priceB
  ) internal view returns(uint, uint) {

    uint priceA = 1 * 10 ** decimals[tokenB];
    uint priceB = _priceB * 10 ** decimals[tokenA] / _priceA;

    return uniV3Helper.positionAmounts(_position, priceA, priceB);
  }

  // Not calling priceOracle.convertTokenValues() to save gas by reusing already fetched prices
  function _convertTokenValues(
    address _fromToken,
    address _toToken,
    uint    _inputAmount,
    uint    _fromPrice,
    uint    _toPrice
  ) internal view returns(uint) {

    uint fromPrice = _fromPrice * 1e18 / 10 ** decimals[_fromToken];
    uint toPrice   = _toPrice   * 1e18 / 10 ** decimals[_toToken];

    return _inputAmount * fromPrice / toPrice;
  }

  // To convert time rate to block rate, use this formula:
  // annualRate * BLOCK_TIME / (365 * 86400 * 1e18)
  // where annualRate is in format: 1e18 = 1%
  function _interestRatePerBlock(address _token) internal view returns(uint) {
    uint minRate  = 0;
    uint lowRate  = 8371385083713;   // 20%
    uint highRate = 418569254185692; // 1,000%
    uint targetUtilization = 80e18;

    uint totalSupply = totalSupplyAmount[_token];
    uint totalDebt = totalDebtAmount[_token];

    if (totalSupply == 0 || totalDebt == 0) { return minRate; }

    // Same as: (totalDebt * 100e18 / totalSupply) * 100e18 / targetUtilization
    uint utilization = totalDebt * 100e18 * 100e18 / totalSupply / targetUtilization;

    if (utilization < 100e18) {
      uint rate = lowRate * utilization / 100e18;
      return Math.max(rate, minRate);
    } else {
      utilization = 100e18 * ( totalDebt - (totalSupply * targetUtilization / 100e18) ) / (totalSupply * (100e18 - targetUtilization) / 100e18);
      utilization = Math.min(utilization, 100e18);
      return lowRate + (highRate - lowRate) * utilization / 100e18;
    }
  }

  function _checkReserve(address _token) internal view {
    IERC20 token = IERC20(_token);

    uint balance = token.balanceOf(address(this));
    uint debt    = totalDebtAmount[_token];
    uint supply  = totalSupplyAmount[_token];
    uint fees    = pendingSystemFees[_token];

    require(int(balance) + int(debt) - int(supply) - int(fees) >= 0, "LendingPair: reserve check failed");
  }

  function _validateToken(address _token) internal view {
    require(_token == tokenA || _token == tokenB, "LendingPair: invalid token");
  }

  function _validateUniPosition(uint _positionID) internal view {
    (, , address uniTokenA, address uniTokenB, , , , uint liquidity, , , ,) = positionManager.positions(_positionID);
    require(liquidity > 0, "LendingPair: liquidity > 0");
    _validateToken(uniTokenA);
    _validateToken(uniTokenB);
  }

  function _checkDepositLimit(address _token, uint _amount) internal view {
    uint depositLimit = lendingController.depositLimit(address(this), _token);

    if (depositLimit > 0) {
      require(
        totalSupplyAmount[_token] + _amount <= depositLimit,
        "LendingPair: deposit limit reached"
      );
    }
  }

  function _checkBorrowLimits(address _token, address _account) internal view {
    uint accountDebt = _debtOf(_token, _account);

    require(
      accountDebt == 0 || accountDebt >= lendingController.minBorrow(_token),
      "LendingPair: borrow amount below minimum"
    );

    uint borrowLimit = lendingController.borrowLimit(address(this), _token);

    if (borrowLimit > 0) {
      require(totalDebtAmount[_token] <= borrowLimit, "LendingPair: borrow limit reached");
    }
  }

  function _lpRate() internal view returns(uint) {
    return 50e18;
  }
}
