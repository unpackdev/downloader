pragma solidity 0.5.16;

import "./SafeERC20.sol";
import "./IERC20.sol";
import "./ERC20Detailed.sol";

import "./IVault.sol";
import "./IdleFinanceStrategy.sol";
import "./IBorrowRecipient.sol";

contract IdleBorrowableStrategy is IdleFinanceStrategy {

  using SafeERC20 for IERC20;

  uint256 public borrowedShares;
  uint256 public underlyingUnit;
  address public borrowRecipient;
  uint256 public loanInUnderlying;

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
    underlyingUnit = 10 ** uint256(ERC20Detailed(_vault).decimals());
  }

  function borrowInUnderlying(bool _exitFirst, bool _reinvest, uint256 _amountInUnderlying) external onlyGovernance {
    require(borrowRecipient != address(0), "Borrow recipient is not configured");
    uint256 pricePerShareBefore = IVault(vault).getPricePerFullShare();
    if (_exitFirst) {
      withdrawAll();
    }

    // This mints new shares for the deposit recipient
    // The number of shares is exactly equivalent to the borrowed amount
    uint256 amountInShares = _amountInUnderlying
      .mul(IVault(vault).totalSupply())
      .div(IVault(vault).underlyingBalanceWithInvestment());
    borrowedShares = borrowedShares.add(amountInShares);
    IERC20(underlying).safeApprove(borrowRecipient, 0);
    IERC20(underlying).safeApprove(borrowRecipient, _amountInUnderlying);
    IBorrowRecipient(borrowRecipient).pullLoan(_amountInUnderlying);

    if (_reinvest) {
      investAllUnderlying();
    }

    updateLoanInUnderlying();

    // price per share should not have changed
    require(IVault(vault).getPricePerFullShare() >= pricePerShareBefore, "Share value dropped");
  }

  function repayInUnderlying(uint256 _amountInUnderlying) public {
    uint256 pricePerShareBefore = IVault(vault).getPricePerFullShare();
    IERC20(underlying).safeTransferFrom(msg.sender, address(this), _amountInUnderlying);

    // this repays shares, including their appreciation
    // the withdrawn amount stays here in the strategy and can be invested
    uint256 amountInShares = _amountInUnderlying
      .mul(underlyingUnit)
      .div(pricePerShareBefore);

    if (amountInShares >= borrowedShares) {
      borrowedShares = 0;
    } else {
      borrowedShares = borrowedShares.sub(amountInShares);
    }

    // send the loan back to the vault
    IERC20(underlying).safeTransfer(vault, _amountInUnderlying);
    updateLoanInUnderlying();

    // price per share should not have changed
    require(IVault(vault).getPricePerFullShare() >= pricePerShareBefore, "Share value dropped");
  }

  function investedUnderlyingBalance() public view returns (uint256) {
    // We need to add the borrowed shares in underlying.
    // We do not calculate the amount dynamically as vault's total supply is needed
    // and during the withdrawal, the vault burns vault shares before using this method
    // for calculating the number of tokens to withdraw. This method needs to return
    // stable result, so we need to work with storing the borrowed amount in underlying.
    return super.investedUnderlyingBalance().add(loanInUnderlying);
  }

  function withdrawToVault(uint256 amountUnderlying) public restricted {
    // the following investment balance excludes the loan
    uint256 idleInvestment = super.investedUnderlyingBalance();
    require (amountUnderlying <= idleInvestment, "Loan needs repaying");
    // use the super implementation if there is enough in idle
    super.withdrawToVault(amountUnderlying);
  }

  function doHardWork() public restricted updateVirtualPrice {
    super.doHardWork();
    updateLoanInUnderlying();
  }

  function updateLoanInUnderlying() internal {
    loanInUnderlying = getLoanInUnderlying();
  }

  function getLoanInUnderlying() public view returns(uint256) {
    uint256 inIdleAndStrategy = super.investedUnderlyingBalance();
    uint256 inVault = IERC20(underlying).balanceOf(vault);
    uint256 realPricePerFullShare = inIdleAndStrategy.add(inVault)
      .mul(underlyingUnit)
      .div(IERC20(vault).totalSupply().sub(borrowedShares));
    uint256 loanInUnderlying = borrowedShares
      .mul(realPricePerFullShare)
      .div(underlyingUnit);
    return loanInUnderlying;
  }

  function setBorrowRecipient(address _borrowRecipient) external onlyGovernance {
    require(_borrowRecipient != address(0), "Use removeBorrowRecipient instead");
    borrowRecipient = _borrowRecipient;
  }

  function removeBorrowRecipient() external onlyGovernance {
    require(borrowedShares == 0, "Repay the loan first");
    borrowRecipient = address(0);
  }

  function emergencySetBorrowedShares(uint256 _newBorrowedShares) external {
    // The community multisig is the only allowed called. This is a remedy mechanism
    // for adjusting the loan if the share price changes for un-natural causes,
    // such as a hack, or an accidental send of funds to the vault by someone.
    // The governance does not have the privilege to call this method.
    require(msg.sender == 0xF49440C1F012d041802b25A73e5B0B9166a75c02, "Only community");
    borrowedShares = _newBorrowedShares;
    updateLoanInUnderlying();
  }
}
