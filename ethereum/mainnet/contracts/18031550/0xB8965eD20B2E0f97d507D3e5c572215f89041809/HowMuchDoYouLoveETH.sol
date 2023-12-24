// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;

contract HowMuchDoYouLoveETH {

  event HowMuchDoYouLoveEth(uint8 aNumberBetween0And255);
  
  function howMuchDoYouLoveETH(uint8 _aNumberBetween0And255) public {
    emit HowMuchDoYouLoveEth(_aNumberBetween0And255);
  }

}