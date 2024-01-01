pragma solidity 0.8.4; //Do not change the solidity version as it negativly impacts submission grading
// SPDX-License-Identifier: MIT

import "./Ownable.sol";
import "./RidleyScottFun.sol";

contract Vendor is Ownable {
  event BuyTokens(address buyer, uint256 amountOfETH, uint256 amountOfTokens);
  event SellTokens(address seller, uint256 amountOfTokens, uint256 amountOfETH);

  RidleyScottFun public rsfToken;
  uint256 public constant tokensPerEth = 9000;

  constructor(address tokenAddress) {
    rsfToken = RidleyScottFun(tokenAddress);
  }

  // ToDo: create a payable buyTokens() function:
  function buyTokens() public payable {
        // Calculate the number of tokens based on the amount of Ether sent
        uint256 calculateAmount = tokensPerEth * msg.value;

        // Transfer the tokens to the buyer (assuming rsfToken is the token contract)
        rsfToken.transfer(msg.sender, calculateAmount);

        // Emit the BuyTokens event
        emit BuyTokens(msg.sender,msg.value, calculateAmount);
  }

  // ToDo: create a withdraw() function that lets the owner withdraw ETH
  function withdraw() public onlyOwner {
    require(address(this).balance>0, "Nothing to withdraw!");
    payable(msg.sender).transfer(address(this).balance);
  }

  // ToDo: create a sellTokens(uint256 _amount) function:
  function sellTokens(uint256 _amount) public {
    require(rsfToken.balanceOf(msg.sender) >= _amount, "Insufficient Funds");

    uint256 ethAmount = _amount / tokensPerEth;
    // Token transfer
    rsfToken.transferFrom(msg.sender, address(this), _amount);
    // Ether transfer
    payable(msg.sender).transfer(ethAmount);

    emit SellTokens(msg.sender, _amount, ethAmount);
  }

}
