// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

interface IERC20 {
  function transferFrom(address from, address to, uint256 amount) external;
  function transfer(address to, uint256 amount) external;
  function balanceOf(address user) external view returns (uint256);
}

contract TribeBotDeposits {
  address public owner;

  event Deposit(uint256 user, uint256 amount);
  event Withdraw(uint256 user, address receiver, uint256 amount);
  event WithdrawFeees(address receiver, uint256 amount);
  event FeeChanged(uint256 feeOnDeposit, uint256 feeOnWithdraw);

  IERC20 public immutable TRIBE;
  uint256 public constant feeBase = 10000;
  uint256 public feeOnDeposit = 100;
  uint256 public feeOnWithdraw = 100;
  uint256 public userBalances = 0;

  constructor(address tribe, address newOwner){
    TRIBE = IERC20(tribe);
    owner = newOwner;
    emit FeeChanged(feeOnDeposit, feeOnWithdraw);
  }

  modifier onlyOwner(){
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address _new) external onlyOwner {
    owner = _new;
  }

  function deposit(uint256 user, uint256 amount) external {
    uint256 balanceBefore = TRIBE.balanceOf(address(this));
    TRIBE.transferFrom(msg.sender, address(this), amount);
    // check actual deposit, which can vary from amount due to fee on transfer
    uint256 deposited = TRIBE.balanceOf(address(this)) - balanceBefore;

    // deduct fees, amount added to user balance is received tribe minus fees
    if (feeOnDeposit > 0) {
      uint256 fee = deposited * feeOnDeposit / feeBase;
      deposited = deposited - fee;
    }

    userBalances += deposited;

    emit Deposit(user, deposited);
  }

  function withdraw(uint256 user, address receiver, uint256 amount) external onlyOwner {
    // deduct fees, amount to withdraw from user balance is amount minus fees. Received amount will depend on transfer tax.
    uint256 withdrawAmount = amount;
    if (feeOnWithdraw > 0) {
      uint256 fee = amount * feeOnWithdraw / feeBase;
      withdrawAmount = withdrawAmount - fee;
    }

    TRIBE.transfer(receiver, withdrawAmount);

    userBalances -= withdrawAmount;

    emit Withdraw(user, receiver, amount);
  }

  function recover(address token, address to, uint256 amount) external onlyOwner {
    IERC20(token).transfer(to, amount);
  }

  function changeFees(uint256 _feeOnDeposit, uint256 _feeOnWithdraw) external onlyOwner {
    feeOnDeposit = _feeOnDeposit;
    feeOnWithdraw = _feeOnWithdraw;
    emit FeeChanged(_feeOnDeposit, _feeOnWithdraw);
  }

  function withdrawFeeAndReflection(address receiver) external onlyOwner {
    uint256 feesAndReflection = TRIBE.balanceOf(address(this)) - userBalances;
    TRIBE.transfer(receiver, feesAndReflection);
    emit WithdrawFeees(receiver, feesAndReflection);
  }
}