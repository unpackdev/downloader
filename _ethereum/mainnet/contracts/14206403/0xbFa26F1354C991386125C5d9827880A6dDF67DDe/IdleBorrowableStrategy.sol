pragma solidity 0.5.16;

import "./SafeERC20.sol";
import "./IERC20.sol";
import "./IdleFinanceStrategy.sol";
import "./IBorrowRecipient.sol";

contract IdleBorrowableStrategy is IdleFinanceStrategy {

  using SafeERC20 for IERC20;

  uint256 public borrowed;
  address public borrowRecipient;

  constructor(
    address _storage,
    address _underlying,
    address _idleUnderlying,
    address _vault,
    address _stkaave
  )
  IdleFinanceStrategy(
    _storage,
    _underlying,
    _idleUnderlying,
    _vault,
    _stkaave
  )
  public {
  }

  function borrow(bool _exitFirst, bool _reinvest, uint256 _amount) external onlyGovernance {
    require(borrowRecipient != address(0), "Borrow recipient is not configured");
    if (_exitFirst) {
      withdrawAll();
    }
    IERC20(underlying).safeApprove(borrowRecipient, 0);
    IERC20(underlying).safeApprove(borrowRecipient, _amount);
    IBorrowRecipient(borrowRecipient).pullLoan(_amount);
    borrowed = borrowed.add(_amount);
    if (_reinvest) {
      investAllUnderlying();
    }
  }

  function repayFrom(address _from, bool _reinvest, uint256 _amount) public onlyGovernance {
    IERC20(underlying).safeTransferFrom(_from, address(this), _amount);
    borrowed = borrowed.sub(_amount);
    if (_reinvest) {
      investAllUnderlying();
    }
  }

  function repay(bool _reinvest, uint256 _amount) external onlyGovernance {
    repayFrom(borrowRecipient, _reinvest, _amount);
  }

  function investedUnderlyingBalance() public view returns (uint256) {
    return super.investedUnderlyingBalance().add(borrowed);
  }

  function withdrawToVault(uint256 amountUnderlying) public restricted {
    // the following investment balance excludes the loan
    uint256 idleInvestment = super.investedUnderlyingBalance();
    require (amountUnderlying <= idleInvestment, "Loan needs repaying");
    // use the super implementation if there is enough in idle
    super.withdrawToVault(amountUnderlying);
  }

  function setBorrowRecipient(address _borrowRecipient) external onlyGovernance {
    require(_borrowRecipient != address(0), "Use removeBorrowRecipient instead");
    borrowRecipient = _borrowRecipient;
  }

  function removeBorrowRecipient() external onlyGovernance {
    require(borrowed == 0, "Repay the loan first");
    borrowRecipient = address(0);
  }
}
