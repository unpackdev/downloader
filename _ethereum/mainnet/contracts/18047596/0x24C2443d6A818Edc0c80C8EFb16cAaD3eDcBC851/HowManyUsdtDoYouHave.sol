// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

contract HowManyUsdtDoYouHave {

  event HowManyUSDTdoYouHave(uint num);
  
  function howManyUSDTdoYouHave(uint _num) public {
    emit HowManyUSDTdoYouHave(_num);
  }

}