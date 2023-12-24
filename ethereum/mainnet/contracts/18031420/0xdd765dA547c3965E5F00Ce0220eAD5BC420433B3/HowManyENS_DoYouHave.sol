// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.11;

contract HowManyENS_DoYouHave {

  event HowManyENSdoYouHave(uint256 aNumber);
  
  function howManyENSdoYouHave(uint256 _aNumber) public {
    emit HowManyENSdoYouHave(_aNumber);
  }

}