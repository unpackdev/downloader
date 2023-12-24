// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.20;

contract DoYouHaveBtc {

  event DoYouHaveBTC(bool trueORfalse);
  
  function doYouHaveBTC(bool _trueORfalse) public {
    emit DoYouHaveBTC(_trueORfalse);
  }

}