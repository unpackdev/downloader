// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "./MarketPlaceCommon.sol";

/**
 * @title MarketPlaceFees
 * @dev A contract for handling marketplace transactions and fees
 */
contract MarketPlaceFees is MarketPlaceCommon {
  /**
   * @dev Initialize the contract
   * @param _dxs Decentrashop's address
   * @param _supplier Supplier's address

   */
  constructor(
    address _dxs,
    address _supplier
  ) MarketPlaceCommon(_dxs, _supplier) {
    minProductPrice = 0.0001 ether;
  }

  /**
   * @dev Buy a product
   * Buyer sends funds and his balance is registred.
   */
  function buyProduct() external payable {
    require(msg.value > minProductPrice, 'Value sent is too low.');

    purchasedBalance[msg.sender] += msg.value;

    emit ProductPurchased(msg.sender, msg.value);
  }

  /**
   * @dev Withdraw all balances
   * Contract funds are distributed between decentrashop and the supplier.
   */
  function withdrawAllBalances() external {
    require(msg.sender == owner, 'You are not the contract Owner.');

    uint valueWithVAT = address(this).balance;
    // Calculate the percentages
    uint valueWithoutVAT = (valueWithVAT * 100) / (100 + maxVAT); //To get the value without VAT in France for instance -> 120(TTC) / 1.2 = 100(HT)
    uint dxsShare = (valueWithoutVAT * 55) / 1000; // 5.5%

    emit BalanceWithdrawn(msg.sender, address(this).balance);

    dxs.transfer(dxsShare);
    supplier.transfer(address(this).balance);
  }
}
