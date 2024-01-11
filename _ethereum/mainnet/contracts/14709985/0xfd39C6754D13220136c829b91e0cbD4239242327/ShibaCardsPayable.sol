// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./ShibaCardsAccessible.sol";

import "./IBank.sol";
import "./IMinter.sol";

abstract contract ShibaCardsPayable is ShibaCardsAccessible {
  IBank public bank;

  uint256 private fees;

  event FeesChanged(uint256 fees);

  function getFees() public view returns (uint256) {
    return fees;
  }

  function setFees(uint256 _fees) public onlyAdmin {
    fees = _fees;
    emit FeesChanged(_fees);
  }

  function setBank(address _bank) public onlyAdmin {
    bank = IBank(_bank);
  }
}
