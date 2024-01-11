// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./Ownable.sol";
import "./IERC20.sol";

contract HeroInfinityWallet is Ownable {
  IERC20 public token = IERC20(0x0C4BA8e27e337C5e8eaC912D836aA8ED09e80e78);

  receive() external payable {}

  function transfer(address receipent, uint256 amount) external onlyOwner {
    token.transfer(receipent, amount);
  }

  function withdrawETH(uint256 amount) external onlyOwner {
    payable(msg.sender).transfer(amount);
  }
}
