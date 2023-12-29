// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

contract HowManyENS_DoYouHave {

  event HowManyENSdoYouHave(uint256 aNumber);
  
  function howManyENSdoYouHave(uint256 _aNumber) public {
    emit HowManyENSdoYouHave(_aNumber);
  }

}