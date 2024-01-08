// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract FeeBase {
  address public feeToSetter;
  address public feeTo;
  uint256 public feeDivisor;

  constructor(address _feeToSetter) {
    // Initialize with a 1% fee to the feeToSetter
    feeToSetter = _feeToSetter;
    feeTo = _feeToSetter;
    feeDivisor = 10;
  }

  function setFeeToSetter(address nextFeeToSetter) external {
    require(msg.sender == feeToSetter, "Sender not authorized to update feeToSetter");
    feeToSetter = nextFeeToSetter;
  }

  function setFeeTo(address nextFeeTo) external {
    require(msg.sender == feeToSetter, "Sender not authorized to update feeTo");
    feeTo = nextFeeTo;
  }

  function setFeeDivisor(uint256 nextFeeDivisor) external {
    require(msg.sender == feeToSetter, "Sender not authorized to update feeDivisor");
    feeDivisor = nextFeeDivisor;
  }

  function hasFee() public view returns (bool) {
    return feeTo != address(0) && feeDivisor > 0;
  }
}
