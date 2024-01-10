// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownable.sol";

abstract contract BaseControl is Ownable {
  // variables
  bool public privateSaleActive;
  bool public publicSaleActive;
  address public tokenAddress = 0x8e7BaBf9EaC40fCd054ACaD1078a898Bd17B529a;

  function togglePrivateSale(bool _status) external onlyOwner {
    privateSaleActive = _status;
  }

  function togglePublicSale(bool _status) external onlyOwner {
    publicSaleActive = _status;
  }

  function setTokenAddress(address _address) external onlyOwner {
    tokenAddress = _address;
  }
}
