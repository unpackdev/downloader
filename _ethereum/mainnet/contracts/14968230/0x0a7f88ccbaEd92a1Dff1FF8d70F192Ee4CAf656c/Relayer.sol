// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Address.sol";

interface IERC20 {
  function balanceOf(address account) external view returns (uint256);
  function transfer(address to, uint256 amount) external returns (bool);
}

contract StardustRelay is Ownable{
  using Address for address;

  address public RECIPIENT = 0xf32604743a19c7854Be5b377f2384B83edc090Ab;

  receive() external payable{
    withdraw();
  }

  function withdraw() public {
    require(address(this).balance >= 0, "No funds available");
    Address.sendValue(payable(RECIPIENT), address(this).balance);
  }

  function withdraw(address token) external {
    IERC20 erc20 = IERC20(token);
    erc20.transfer(RECIPIENT, erc20.balanceOf(address(this)) );
  }

  function setRecipient( address recipient ) external onlyOwner {
    RECIPIENT = recipient;
  }
}