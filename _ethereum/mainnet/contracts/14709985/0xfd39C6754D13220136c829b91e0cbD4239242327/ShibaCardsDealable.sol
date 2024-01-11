// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./ShibaCardsAccessible.sol";

import "./IDealer.sol";

abstract contract ShibaCardsDealable is ShibaCardsAccessible {
  IDealer public dealer;

  function setDealer(address _dealer) public onlyAdmin {
    dealer = IDealer(_dealer);
  }
}
