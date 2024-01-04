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


interface IOffer
{
  function __Offer_init(address lender, address lendingToken, uint256 principal, uint256 interest, uint256 duration, uint256 feeOnInterest) external;

  function claim(address collateralToken, uint256 collateral) external returns (address loan);

  function cancel() external;
}

contract Offer is IOffer, Escrow
{
  using SafeMath for uint256;
  using SafeERC20 for IERC20;


  uint256 private _feeOnInterest;


  function __Offer_init(address lender, address lendingToken, uint256 principal, uint256 interest, uint256 duration, uint256 feeOnInterest) external override initializer
  {
    Escrow._initialize();

    _loanDetails.lender = lender;
    _loanDetails.duration = duration;

    _loanDetails.lendingToken = lendingToken;
    _loanDetails.principal = principal;
    _loanDetails.interest = interest;

    _feeOnInterest = feeOnInterest;
  }


  function claim(address collateralToken, uint256 collateral) external override nonReentrant returns (address loan)
  {
    require(msg.sender != _loanDetails.lender, "Own Offer");

    require(ICollateralManager(_collateralMgr()).isSufficientInitialCollateral(_loanDetails.lendingToken, _loanDetails.principal, collateralToken, collateral), "Inadequate collateral");

    // calculate fee amounts
    uint256 feeOnPrincipal = IFeeBurnManager(_feeBurnMgr()).getFeeOnPrincipal(msg.sender, _loanDetails.lendingToken, _loanDetails.principal, collateralToken);

    // tx collateral and fee from borrower
    IERC20(collateralToken).safeTransferFrom(msg.sender, address(this), collateral.add(feeOnPrincipal));

    _loanDetails.borrower = msg.sender;
    _loanDetails.collateralToken = collateralToken;
    _loanDetails.collateral = collateral;

    return Escrow._accept(_feeOnInterest, feeOnPrincipal, true);
  }

  function cancel() external override nonReentrant
  {
    Escrow._isPending();
    require(msg.sender == _loanDetails.lender, "!lender");

    _status = Status.Canceled;

    IERC20(_loanDetails.lendingToken).safeTransfer(msg.sender, _getPrincipalBalance());

    emit Cancel(msg.sender);
  }
}
