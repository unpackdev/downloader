// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.19;

contract DoYouLoveWeb3 {

  event DoYouLoveWEB3(bool falseOrTrue);
  
  function doYouLoveWEB3(bool _falseOrTrue) public {
    emit DoYouLoveWEB3(_falseOrTrue);
  }

}