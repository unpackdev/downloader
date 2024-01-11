// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

// Contract by technopriest#0760
contract CCLCrowdsale is Ownable {
  using SafeMath for uint256;

  ERC20 public token;
  uint256 public rate = 20000;
  address payable public wallet;

  event TokenPurchase(
    address indexed purchaser,
    uint256 amount
  );

  constructor(ERC20 _token, address payable _wallet) {
    token = _token;
    wallet = _wallet;
  }

  function buyTokens() public payable {
    uint256 weiAmount = msg.value;
    require(weiAmount != 0);

    uint256 tokenAmount = weiAmount.mul(rate);
    require(tokenAmount <= token.balanceOf(address(this)), "Crowdsale does not have enough CCL");

    token.transfer(msg.sender, tokenAmount);

    emit TokenPurchase(
      msg.sender,
      tokenAmount
    );
  }

  function withdrawFunds(uint256 amount) public onlyOwner {
    require(amount <= address(this).balance);
    wallet.transfer(amount);
  }

  function withdrawToken(uint256 amount) public onlyOwner {
    require(amount <= token.balanceOf(address(this)));
    token.transfer(wallet, amount);
  }
}
