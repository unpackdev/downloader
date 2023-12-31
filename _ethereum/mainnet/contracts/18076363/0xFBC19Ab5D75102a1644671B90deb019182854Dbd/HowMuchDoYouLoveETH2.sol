// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;

contract HowMuchDoYouLoveETH2 {

  event HowMuchDoYouLoveEth2(uint8 aNumberBetween0And255);
  
  function howMuchDoYouLoveETH2(uint8 _aNumberBetween0And255) public {
    emit HowMuchDoYouLoveEth2(_aNumberBetween0And255);
  }

}