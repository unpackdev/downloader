// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuardUpgradeable.sol";

import "./CollateralManager.sol";
import "./FeeBurnManager.sol";
import "./TokenManager.sol";
import "./Oracle.sol";
import "./VersionManager.sol";


interface ILoan
{
  enum Status {Active, Repaid, Defaulted}

  struct LoanDetails
  {
    address lender;
    address borrower;
    address lendingToken;
    address collateralToken;
    uint256 principal;
    uint256 interest;
    uint256 duration;
    uint256 collateral;
  }

  struct LoanMetadata
  {
    ILoan.Status status;
    uint256 timestampStart;
    uint256 timestampRepaid;
    uint256 liquidatableTimeAllowance;
  }


  event Repay(address indexed lender, address indexed borrower, address loan);
  event Default(address indexed lender, address indexed borrower, address loan);
  event Liquidate(address indexed loan, address liquidator, uint256 amountRepaid);


  function __Loan_init(LoanDetails memory loanDetails) external;


  function isDefaulted() external view returns (bool);

  function getLoanDetails() external view returns (LoanDetails memory details);

  function getLoanMetadata() external view returns (LoanMetadata memory metadata);
}


contract Loan is ILoan, ReentrancyGuardUpgradeable, VersionManager
{
  using SafeMath for uint256;
  using SafeERC20 for IERC20;


  uint256 private constant _COMPENSATION_THRESHOLD = 10650; // 106.5%
  uint256 private constant _BASIS_POINT = 10000;

  LoanDetails private _loanDetails;
  LoanMetadata private _loanMetadata;


  modifier onlyLender
  {
    require(msg.sender == _loanDetails.lender, "!lender");
    _;
  }

  modifier onlyBorrower
  {
    require(msg.sender == _loanDetails.borrower, "!borrower");
    _;
  }



  function __Loan_init(LoanDetails memory loanDetails) external override initializer
  {
    ReentrancyGuardUpgradeable.__ReentrancyGuard_init();

    _loanDetails = loanDetails;

    _loanMetadata.timestampStart = block.timestamp;
  }

  function _calcPercentOf(uint256 amount, uint256 percent) private pure returns (uint256)
  {
    return amount.mul(percent).div(_BASIS_POINT);
  }

  function _isActive() private view
  {
    require(_loanMetadata.status == ILoan.Status.Active, "!active");
  }

  function isDefaulted() public view override returns (bool)
  {
    (bool sufficient,) = ICollateralManager(VersionManager._collateralMgr()).isSufficientCollateral(_loanDetails.borrower, _loanDetails.lendingToken, _loanDetails.principal, _loanDetails.collateralToken, _getCollateralBalance());

    return !sufficient || block.timestamp > getTimestampDue();
  }

  function _hasDefaulted() private view
  {
    require(isDefaulted(), "!defaulted");
  }

  function _hasNotDefaulted() private view
  {
    require(!isDefaulted(), "Defaulted");
  }

  function getTimestampDue() public view returns (uint256)
  {
    return _loanMetadata.timestampStart.add(_loanDetails.duration);
  }

  function getCollateralBalance() public view returns (uint256)
  {
    return _getCollateralBalance();
  }

  function _getFullCollateralBalance() private view returns (uint256)
  {
    return IERC20(_loanDetails.collateralToken).balanceOf(address(this));
  }

  function _getCollateralBalance() private view returns (uint256)
  {
    if (ITokenManager(VersionManager._tokenMgr()).isDynamicToken(_loanDetails.collateralToken))
    {
      return _getFullCollateralBalance();
    }

    return _loanDetails.collateral;
  }

  function _repaymentAmount() private view returns (uint256 amount)
  {
    return _loanDetails.principal.add(_calcPercentOf(_loanDetails.principal, _loanDetails.interest));
  }

  function getLoanDetails() public view override returns (LoanDetails memory details)
  {
    return _loanDetails;
  }

  function getLoanMetadata() public view override returns (LoanMetadata memory metadata)
  {
    return _loanMetadata;
  }


  function _increaseCollateralBalance (uint amount) private
  {
    if (!ITokenManager(VersionManager._tokenMgr()).isDynamicToken(_loanDetails.collateralToken))
    {
      _loanDetails.collateral = _loanDetails.collateral.add(amount);
    }
  }

  function topUpCollateral(uint256 amount) external nonReentrant onlyBorrower
  {
    _isActive();
    _hasNotDefaulted();
    require(amount > 0 && amount < type(uint256).max, "Invalid val");

    _increaseCollateralBalance(amount);

    // deposit tokens
    IERC20(_loanDetails.collateralToken).safeTransferFrom(_loanDetails.borrower, address(this), amount);
  }

  function _handleRepayment() private
  {
    LoanDetails memory loanDetails = getLoanDetails();

    _loanMetadata.status = ILoan.Status.Repaid;

    IERC20(loanDetails.lendingToken).safeTransferFrom(loanDetails.borrower, loanDetails.lender, _repaymentAmount());

    IERC20(loanDetails.collateralToken).safeTransfer(loanDetails.borrower, _getFullCollateralBalance());

    _loanMetadata.timestampRepaid = block.timestamp;

    emit Repay(loanDetails.lender, loanDetails.borrower, address(this));
  }

  function repay() external nonReentrant onlyBorrower
  {
    require(block.timestamp > _loanMetadata.timestampStart.add(5 minutes), "fresh");

    _isActive();
    _hasNotDefaulted();
    _handleRepayment();
  }

  function _txDefaultingFee() internal
  {
    IERC20(_loanDetails.collateralToken).safeTransfer(IFeeBurnManager(VersionManager._feeBurnMgr()).burner(), IFeeBurnManager(VersionManager._feeBurnMgr()).getDefaultingFee(_getFullCollateralBalance()));
  }

  function _handleDefault() private
  {
    _loanMetadata.status = ILoan.Status.Defaulted;

    _txDefaultingFee();

    IERC20(_loanDetails.collateralToken).safeTransfer(_loanDetails.lender, _getFullCollateralBalance());

    emit Default(_loanDetails.lender, _loanDetails.borrower, address(this));
  }

  function setLiquidatableTimeAllowance() public nonReentrant
  {
    _isActive();
    _hasDefaulted();
    require(_loanMetadata.liquidatableTimeAllowance == 0, "Set");

    _loanMetadata.liquidatableTimeAllowance = block.timestamp.add(10 minutes);
  }

  function seizeCollateral() external nonReentrant onlyLender
  {
    _isActive();
    _hasDefaulted();
    _handleDefault();
  }

  function seizeForLender() public nonReentrant
  {
    _isActive();
    _hasDefaulted();
    require(_loanMetadata.liquidatableTimeAllowance != 0 && block.timestamp >= _loanMetadata.liquidatableTimeAllowance, "Liquidatable");

    // ~$5; 5 * 10^18 DAI (USD)
    uint256 compensation = IOracle(VersionManager._oracle()).convertFromUSD(_loanDetails.collateralToken, 5 * 1e18);

    IERC20(_loanDetails.collateralToken).safeTransfer(msg.sender, compensation);

    _handleDefault();
  }

  function liquidate() external nonReentrant
  {
    _isActive();
    _hasDefaulted();

    LoanDetails memory loanDetails = getLoanDetails();

    _loanMetadata.status = ILoan.Status.Defaulted;

    _txDefaultingFee();

    uint256 collateralBalance = _getFullCollateralBalance();
    uint256 amountToRepay = loanDetails.principal.add(_repaymentAmount().sub(loanDetails.principal).div(2));

    // calculate principal + half of interest equivalent + kicker
    uint256 maxCompensation = IOracle(VersionManager._oracle()).convert(loanDetails.lendingToken, loanDetails.collateralToken, _calcPercentOf(amountToRepay, _COMPENSATION_THRESHOLD));

    // calculate min(collateral, principal + half of interest)
    uint256 compensation = collateralBalance > maxCompensation ? maxCompensation : collateralBalance;


    // return principal + half of interest to lender
    IERC20(loanDetails.lendingToken).safeTransferFrom(msg.sender, loanDetails.lender, amountToRepay);

    // pay min(collateral, principal + half of interest) to liquidator
    IERC20(loanDetails.collateralToken).safeTransfer(msg.sender, compensation);

    if (collateralBalance > maxCompensation)
    {
      IERC20(loanDetails.collateralToken).safeTransfer(loanDetails.lender, _getFullCollateralBalance());
    }

    emit Default(loanDetails.lender, loanDetails.borrower, address(this));
    emit Liquidate(address(this), msg.sender, amountToRepay);
  }
}
