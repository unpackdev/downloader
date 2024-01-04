// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuardUpgradeable.sol";

import "./CollateralManager.sol";
import "./FeeBurnManager.sol";
import "./Loan.sol";
import "./Escrow.sol";


interface IRequest
{
  function __Request_init(address borrower, address lendingToken, uint256 principal, uint256 interest, uint256 duration, address collateralToken, uint256 collateral, uint256 feeOnPrincipal) external;

  function fund() external returns (address loan);

  function cancel() external;
}

contract Request is IRequest, Escrow
{
  using SafeMath for uint256;
  using SafeERC20 for IERC20;


  uint256 private _feeOnPrincipal;


  function __Request_init(address borrower, address lendingToken, uint256 principal, uint256 interest, uint256 duration, address collateralToken, uint256 collateral, uint256 feeOnPrincipal) external override initializer
  {
    Escrow._initialize();

    require(ICollateralManager(_collateralMgr()).isSufficientInitialCollateral(lendingToken, principal, collateralToken, collateral), "Inadequate collateral");

    _loanDetails.borrower = borrower;
    _loanDetails.duration = duration;

    _loanDetails.lendingToken = lendingToken;
    _loanDetails.principal = principal;
    _loanDetails.interest = interest;

    _loanDetails.collateralToken = collateralToken;
    _loanDetails.collateral = collateral;

    _feeOnPrincipal = feeOnPrincipal;
  }


  function fund() external override nonReentrant returns (address loan)
  {
    require(msg.sender != _loanDetails.borrower, "Own Request");

    _loanDetails.lender = msg.sender;

    // calculate fee amounts
    uint256 feeOnInterest = IFeeBurnManager(_feeBurnMgr()).getFeeOnInterest(msg.sender, _loanDetails.lendingToken, _loanDetails.principal, _loanDetails.interest);

    // tx principal and fee from lender
    IERC20(_loanDetails.lendingToken).safeTransferFrom(msg.sender, address(this), _loanDetails.principal.add(feeOnInterest));

    return Escrow._accept(feeOnInterest, _feeOnPrincipal, false);
  }

  function cancel() external override nonReentrant
  {
    Escrow._isPending();
    require(msg.sender == _loanDetails.borrower, "!borrower");

    _status = Status.Canceled;

    IERC20(_loanDetails.collateralToken).safeTransfer(msg.sender, _getCollateralBalance());

    emit Cancel(msg.sender);
  }
}
