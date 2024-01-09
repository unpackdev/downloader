// SPDX-License-Identifier: UNLICENSED

// Copyright (c) WildCredit - All rights reserved
// https://twitter.com/WildCredit

pragma solidity 0.8.6;

import "TransferHelper.sol";
import "SafeOwnable.sol";

import "IFeeRecipient.sol";

contract FeeRecipient is IFeeRecipient, TransferHelper, SafeOwnable {

  address public feeConverter;

  event FeeDistribution(uint amount);

  modifier onlyConverter() {
    require(msg.sender == feeConverter, "FeeRecipient: caller is not the converter");
    _;
  }

  // Push any ERC20 token to FeeConverter
  function pushToken(address _token, uint _amount) external override onlyConverter {
    _safeTransfer(_token, feeConverter, _amount);
  }

  function setFeeConverter(address _value) external onlyOwner {
    feeConverter = _value;
  }
}
