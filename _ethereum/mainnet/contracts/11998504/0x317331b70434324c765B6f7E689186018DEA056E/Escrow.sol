// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuardUpgradeable.sol";

import "./FeeBurnManager.sol";
import "./LoanFactory.sol";
import "./Loan.sol";

import "./VersionManager.sol";


interface IEscrow
{
  enum Status {Pending, Accepted, Canceled}


  event Accept(address lender, address borrower, address loan);
  event Cancel(address caller);


  function getLoanDetails() external view returns (ILoan.LoanDetails memory details);
}

contract Escrow is IEscrow, ReentrancyGuardUpgradeable, VersionManager
{
  using SafeERC20 for IERC20;


  Status internal _status;
  ILoan.LoanDetails internal _loanDetails;


  function _initialize() internal initializer
  {
    ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
  }

  function _isPending() internal view
  {
    require(_status == Status.Pending, "!pending");
  }

  function _getBurner() internal view returns (address)
  {
    return IFeeBurnManager(VersionManager._feeBurnMgr()).burner();
  }

  function _getPrincipalBalance() internal view returns (uint256)
  {
    return IERC20(_loanDetails.lendingToken).balanceOf(address(this));
  }

  function _getCollateralBalance() internal view returns (uint256)
  {
    return IERC20(_loanDetails.collateralToken).balanceOf(address(this));
  }

  function getStatus () external view returns (Status)
  {
    return _status;
  }

  function getLoanDetails() external view override returns (ILoan.LoanDetails memory details)
  {
    return _loanDetails;
  }


  function _accept(uint256 feeOnInterest, uint256 feeOnPrincipal, bool isOffer) internal returns (address loan)
  {
    _isPending();

    _status = Status.Accepted;

    // tx burn fees
    IERC20(_loanDetails.lendingToken).safeTransfer(Escrow._getBurner(), feeOnInterest);
    IERC20(_loanDetails.collateralToken).safeTransfer(Escrow._getBurner(), feeOnPrincipal);


    if (isOffer)
    {
      _loanDetails.principal = _getPrincipalBalance();
    }
    else
    {
      _loanDetails.collateral = _getCollateralBalance();
    }


    loan = ILoanFactory(VersionManager._loanFactory()).createLoan(_loanDetails);

    // tx collateral to loan
    IERC20(_loanDetails.collateralToken).safeTransfer(loan, _loanDetails.collateral);

    // tx principal to borrower
    IERC20(_loanDetails.lendingToken).safeTransfer(_loanDetails.borrower, _loanDetails.principal);

    emit Accept(_loanDetails.lender, _loanDetails.borrower, loan);

    return loan;
  }
}
