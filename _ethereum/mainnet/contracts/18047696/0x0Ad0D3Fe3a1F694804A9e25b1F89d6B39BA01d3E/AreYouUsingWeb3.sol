// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.21;

contract AreYouUsingWeb3 {

  event AreYouUsingWEB3(bool _FalseORtrue);
  
  function areYouUsingWEB3(bool FalseORtrue) public {
    emit AreYouUsingWEB3(FalseORtrue);
  }

}