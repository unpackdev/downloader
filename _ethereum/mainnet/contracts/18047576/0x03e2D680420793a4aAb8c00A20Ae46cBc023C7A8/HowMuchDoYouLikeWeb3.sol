// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.18;

contract HowMuchDoYouLikeWeb3 {

  event HowMuchDoYouLikeWEB3(uint8 aNumberBetween0And255);
  
  function howMuchDoYouLikeWEB3(uint8 _aNumberBetween0And255) public {
    emit HowMuchDoYouLikeWEB3(_aNumberBetween0And255);
  }

}