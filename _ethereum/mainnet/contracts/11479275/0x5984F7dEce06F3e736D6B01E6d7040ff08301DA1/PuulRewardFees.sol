// SPDX-License-Identifier: Apache-2.0-with-puul-exception
pragma solidity >=0.6.12;
import "./Fees.sol";

contract PuulRewardFees is Fees {
  address constant public PUUL = address(0x897581168bB658954a811a03de8394EBd42852Ef);
  constructor (address helper, address withdrawal, uint256 withdrawalFee, address reward, uint256 rewardFee) public Fees(helper, withdrawal, withdrawalFee, reward, rewardFee) {
    _currency = PUUL;
  }
}
