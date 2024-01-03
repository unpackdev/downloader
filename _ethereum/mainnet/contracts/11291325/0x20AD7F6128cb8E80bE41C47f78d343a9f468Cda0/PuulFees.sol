// SPDX-License-Identifier: Apache-2.0-with-puul-exception
pragma solidity >=0.6.12;
import "./Fees.sol";

contract PuulFees is Fees {
  address constant public USDC = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
  constructor (address helper, address withdrawal, uint256 withdrawalFee, address reward, uint256 rewardFee) public Fees(helper, withdrawal, withdrawalFee, reward, rewardFee) {
    _currency = USDC;
  }
}
