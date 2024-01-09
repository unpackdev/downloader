// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

import "IInterestRateModel.sol";
import "IPriceOracle.sol";
import "ILendingController.sol";
import "SafeOwnable.sol";
import "AddressLibrary.sol";

contract LendingController is ILendingController, SafeOwnable {

  using AddressLibrary for address;

  uint private constant MAX_COL_FACTOR = 99e18;
  uint private constant MAX_LIQ_FEES   = 50e18;

  IPriceOracle public priceOracle;

  address public override interestRateModel;

  bool public override depositsEnabled;
  bool public override borrowingEnabled;
  uint public liqFeeCallerDefault;
  uint public liqFeeSystemDefault;
  uint public override uniMinOutputPct; // 99e18 = 99%

  mapping(address => bool) public isGuardian;
  mapping(address => mapping(address => uint)) public override depositLimit;
  mapping(address => mapping(address => uint)) public override borrowLimit;
  mapping(address => uint) public liqFeeCallerToken; // 1e18  = 1%
  mapping(address => uint) public liqFeeSystemToken; // 1e18  = 1%
  mapping(address => uint) public override colFactor; // 99e18 = 99%
  mapping(address => uint) public override minBorrow;

  event NewInterestRateModel(address indexed interestRateModel);
  event NewPriceOracle(address indexed priceOracle);
  event NewColFactor(address indexed token, uint value);
  event NewDepositLimit(address indexed pair, address indexed token, uint value);
  event NewBorrowLimit(address indexed pair, address indexed token, uint value);
  event AllowGuardian(address indexed guardian, bool value);
  event DepositsEnabled(bool value);
  event BorrowingEnabled(bool value);
  event NewLiqParamsToken(address indexed token, uint liqFeeSystem, uint liqFeeCaller);
  event NewLiqParamsDefault(uint liqFeeSystem, uint liqFeeCaller);
  event NewUniMinOutputPct(uint value);
  event NewMinBorrow(address indexed token, uint value);

  modifier onlyGuardian() {
    require(isGuardian[msg.sender], "LendingController: caller is not a guardian");
    _;
  }

  constructor(
    address _interestRateModel,
    uint _liqFeeSystemDefault,
    uint _liqFeeCallerDefault,
    uint _uniMinOutputPct
  ) {
    _requireContract(_interestRateModel);
    require(_liqFeeSystemDefault + _liqFeeCallerDefault <= MAX_LIQ_FEES, "LendingController: fees too high");

    interestRateModel   = _interestRateModel;
    liqFeeSystemDefault = _liqFeeSystemDefault;
    liqFeeCallerDefault = _liqFeeCallerDefault;
    uniMinOutputPct     = _uniMinOutputPct;
    depositsEnabled     = true;
    borrowingEnabled    = true;
  }

  function setLiqParamsToken(
    address _token,
    uint    _liqFeeSystem,
    uint    _liqFeeCaller
  ) external onlyOwner {
    require(_liqFeeCaller + _liqFeeSystem <= MAX_LIQ_FEES, "LendingController: fees too high");
    _requireContract(_token);

    liqFeeSystemToken[_token] = _liqFeeSystem;
    liqFeeCallerToken[_token] = _liqFeeCaller;

    emit NewLiqParamsToken(_token, _liqFeeSystem, _liqFeeCaller);
  }

  function setLiqParamsDefault(
    uint    _liqFeeSystem,
    uint    _liqFeeCaller
  ) external onlyOwner {
    require(_liqFeeCaller + _liqFeeSystem <= MAX_LIQ_FEES, "LendingController: fees too high");

    liqFeeSystemDefault = _liqFeeSystem;
    liqFeeCallerDefault = _liqFeeCaller;

    emit NewLiqParamsDefault(_liqFeeSystem, _liqFeeCaller);
  }

  function setInterestRateModel(address _value) external onlyOwner {
    _requireContract(_value);
    interestRateModel = _value;
    emit NewInterestRateModel(_value);
  }

  function setPriceOracle(address _value) external onlyOwner {
    _requireContract(_value);
    priceOracle = IPriceOracle(_value);
    emit NewPriceOracle(address(_value));
  }

  function setMinBorrow(address _token, uint _value) external onlyOwner {
    _requireContract(_token);
    minBorrow[_token] = _value;
    emit NewMinBorrow(_token, _value);
  }

  // Allow immediate emergency shutdown of deposits by the guardian.
  function disableDeposits() external onlyGuardian {
    depositsEnabled = false;
    emit DepositsEnabled(false);
  }

  // Re-enabling deposits can only be done by the owner
  function enableDeposits() external onlyOwner {
    depositsEnabled = true;
    emit DepositsEnabled(true);
  }

  function disableBorrowing() external onlyGuardian {
    borrowingEnabled = false;
    emit BorrowingEnabled(false);
  }

  function enableBorrowing() external onlyOwner {
    borrowingEnabled = true;
    emit BorrowingEnabled(true);
  }

  function setDepositLimit(address _pair, address _token, uint _value) external onlyOwner {
    _requireContract(_pair);
    _requireContract(_token);
    depositLimit[_pair][_token] = _value;
    emit NewDepositLimit(_pair, _token, _value);
  }

  function allowGuardian(address _guardian, bool _value) external onlyOwner {
    isGuardian[_guardian] = _value;
    emit AllowGuardian(_guardian, _value);
  }

  function setBorrowLimit(address _pair, address _token, uint _value) external onlyOwner {
    _requireContract(_pair);
    _requireContract(_token);
    borrowLimit[_pair][_token] = _value;
    emit NewBorrowLimit(_pair, _token, _value);
  }

  function setUniMinOutputPct(uint _value) external onlyOwner {
    uniMinOutputPct = _value;
    emit NewUniMinOutputPct(_value);
  }

  function setColFactor(address _token, uint _value) external onlyOwner {
    require(_value <= MAX_COL_FACTOR, "LendingController: _value <= MAX_COL_FACTOR");
    _requireContract(_token);
    colFactor[_token] = _value;
    emit NewColFactor(_token, _value);
  }

  function liqFeeSystem(address _token) public view override returns(uint) {
    return liqFeeSystemToken[_token] > 0 ? liqFeeSystemToken[_token] : liqFeeSystemDefault;
  }

  function liqFeeCaller(address _token) public view override returns(uint) {
    return liqFeeCallerToken[_token] > 0 ? liqFeeCallerToken[_token] : liqFeeCallerDefault;
  }

  function liqFeesTotal(address _token) external view returns(uint) {
    return liqFeeSystem(_token) + liqFeeCaller(_token);
  }

  function tokenPrice(address _token) external view override returns(uint) {
    return priceOracle.tokenPrice(_token);
  }

  function tokenPrices(address _tokenA, address _tokenB) external view override returns (uint, uint) {
    return (
      priceOracle.tokenPrice(_tokenA),
      priceOracle.tokenPrice(_tokenB)
    );
  }

  function tokenSupported(address _token) external view override returns(bool) {
    return priceOracle.tokenSupported(_token);
  }

  function _requireContract(address _value) internal view {
    require(_value.isContract(), "LendingController: must be a contract");
  }
}
