// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import "./SafeMath.sol";

import "./Loan.sol";
import "./DiscountManager.sol";
import "./RewardManager.sol";

import "./ProxyFactory.sol";
import "./Pausable.sol";
import "./LoanerRole.sol";
import "./VersionManager.sol";


interface ILoanFactory
{
  event NewLoan(address indexed lender, address indexed borrower, address loan);


  function addLoaner(address account) external;

  function createLoan(ILoan.LoanDetails memory loanDetails) external returns (address);
}


contract LoanFactory is ILoanFactory, Pausable, LoanerRole, VersionManager
{
  using SafeMath for uint256;


  address[] private _loans;
  mapping(address => address[]) private _loansOf;


  function getLoans() external view returns (address[] memory)
  {
    return _loans;
  }

  function getLoansOf(address account) external view returns (address[] memory)
  {
    return _loansOf[account];
  }


  function addLoaner(address account) public override(ILoanFactory, LoanerRole)
  {
    LoanerRole.addLoaner(account);
  }

  function createLoan(ILoan.LoanDetails memory loanDetails) external override onlyLoaner returns (address)
  {
    Pausable._isNotPaused();

    bytes memory initData = abi.encodeWithSelector(ILoan.__Loan_init.selector, loanDetails);

    address loan = ProxyFactory._deployMinimal(VersionManager._loanImplementation(), initData);

    require(IRewardManager(VersionManager._rewardMgr()).trackLoan(loan, loanDetails.borrower, loanDetails.lendingToken, loanDetails.principal, loanDetails.interest, loanDetails.duration), "Track err");

    _loans.push(loan);
    _loansOf[loanDetails.lender].push(loan);
    _loansOf[loanDetails.borrower].push(loan);

    IDiscountManager(VersionManager._discountMgr()).updateUnlockTime(loanDetails.lender, loanDetails.borrower, loanDetails.duration);

    emit NewLoan(loanDetails.lender, loanDetails.borrower, loan);

    return loan;
  }
}
