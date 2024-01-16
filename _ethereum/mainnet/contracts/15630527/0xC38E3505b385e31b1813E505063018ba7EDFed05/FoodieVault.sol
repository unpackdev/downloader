// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./IERC20.sol";

contract FoodieVault is ReentrancyGuard, Ownable {
  uint256 public price;
  address public vault;

  IERC20 public immutable token;

  event PaymentReceived(address indexed sender, uint256 id, uint256 amount, uint256 cost, string email);

  constructor(
    uint256 initPrice_,
    address vault_,
    address token_
  ) {
    price = initPrice_;
    vault = vault_;
    token = IERC20(token_);
  }

  function setPrice(uint256 newPrice_) public onlyOwner {
    price = newPrice_;
  }

  function setVault(address newVault_) public onlyOwner {
    vault = newVault_;
  }

  // Pay with ERC20 token
  function purchase(uint256 id, uint256 amount, string calldata email) external {
    uint256 cost = price * amount;

    require(amount > 0, 'amount must be greater than 0');
    require(
      token.balanceOf(msg.sender) >= cost,
      'USD balance of buyer is not enough'
    );
    require(
      token.allowance(msg.sender, address(this)) >= cost,
      'USD allowance of buyer is not enough'
    );

    token.transferFrom(msg.sender, vault, cost);

    emit PaymentReceived(msg.sender, id, amount, cost, email);
  }
}
