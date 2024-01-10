// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Libs.sol";
import "./BaseControl.sol";

contract MIFE is BaseControl {
  using MapPurchase for MapPurchase.Purchase;
  using MapPurchase for MapPurchase.Record;

  // constants
  // variables
  uint256 public quantityReleased;
  MapPurchase.Record purchases;

  // verified
  constructor() {}

  /** Public */
  function privateSale() external payable {
    uint16 rate = 12000;
    require(tx.origin == msg.sender, "Not allowed");
    require(privateSaleActive, "Not active");
    require(!purchases.containsValue(msg.sender), "Already purchased");
    require(msg.value >= 2 ether && msg.value <= 20 ether, "Ether value incorrect");
    // check supply
    (uint256 tokenAmount, uint256 bonusAmount, ) = Utilities.computeReward(msg.value, rate, 18, Utilities.getPrivateBonus);
    require(quantityReleased + tokenAmount + bonusAmount <= 150000000 * (10 ** 18), "Exceed supply");

    purchases.addValue(msg.sender, msg.value, rate, 18, Utilities.getPrivateBonus);
    quantityReleased += (tokenAmount + bonusAmount);
  }

  function publicSale() external payable {
    uint16 rate = 10000;
    require(tx.origin == msg.sender, "Not allowed");
    require(publicSaleActive, "Not active");
    require(!purchases.containsValue(msg.sender), "Already purchased");
    require(msg.value >= 0.5 ether && msg.value <= 8 ether, "Ether value incorrect");
    // check supply
    (uint256 tokenAmount, uint256 bonusAmount, ) = Utilities.computeReward(msg.value, rate, 18, Utilities.getPublicBonus);
    require(quantityReleased + tokenAmount + bonusAmount <= 450000000 * (10 ** 18), "Exceed supply");

    purchases.addValue(msg.sender, msg.value, rate, 18, Utilities.getPublicBonus);
    quantityReleased += (tokenAmount + bonusAmount);
  }

  /** Admin */
  function issueBonus(uint256 _start, uint256 _end) external onlyOwner {
    uint256 maxSize = getPurchasersSize();
    _end = _end > maxSize ? maxSize : _end;

    for (uint256 i = _start; i < _end; i++) {
      MapPurchase.Purchase storage record = purchases.values[i];
      if (record.tokenAmount == 0 && record.bonusAmount > 0) {
        IERC20(tokenAddress).transfer(record.account, record.bonusAmount);
        record.bonusAmount = 0;
      }
    }
  }

  function issueTokens(uint256 _start, uint256 _end, uint8 _issueTh) external onlyOwner {
    require(_issueTh >= 1, "Incorrect Input");

    uint256 maxSize = getPurchasersSize();
    _end = _end > maxSize ? maxSize : _end;

    for (uint256 i = _start; i < _end; i++) {
      MapPurchase.Purchase storage record = purchases.values[i];
      if (record.divisor + _issueTh > 12) {
        uint256 amount = record.tokenAmount / record.divisor;
        record.tokenAmount -= amount;

        if (record.divisor > 1) {
          record.divisor -= 1;
        }
        IERC20(tokenAddress).transfer(record.account, amount);
      }
    }
  }

  function withdraw() external onlyOwner {
    uint256 balance = address(this).balance;
    uint256 balanceA = balance * 85 / 100;

    uint256 balanceB = balance - balanceA;
    payable(0x95a881D2636a279B0F51a2849844b999E0E52fa8).transfer(balanceA);
    payable(0x0dF5121b523aaB2b238f5f03094f831348e6b5C3).transfer(balanceB);
  }

  function withdrawMIFE() external onlyOwner {
    uint256 balance = IERC20(tokenAddress).balanceOf(address(this));
    IERC20(tokenAddress).transfer(msg.sender, balance);
  }

  /** View */
  function getPurchasersSize() public view returns (uint256) {
    return purchases.values.length;
  }

  function getPurchaserAt(uint256 _index) public view returns (MapPurchase.Purchase memory) {
    return purchases.values[_index];
  }

  function getPurchasers(uint256 _start, uint256 _end) public view returns (MapPurchase.Purchase[] memory) {
    uint256 maxSize = getPurchasersSize();
    _end = _end > maxSize ? maxSize : _end;

    MapPurchase.Purchase[] memory records = new MapPurchase.Purchase[](_end - _start);
    for (uint256 i = _start; i < _end; i++) {
      records[i - _start] = purchases.values[i];
    }
    return records;
  }

  function getPersonaAllocated(address _account) public view returns (uint8) {
    MapPurchase.Purchase memory purchase = purchases.getValue(_account);
    return purchase.personaAmount;
  }

  function getPurchasedByAccount(address _account) public view returns (MapPurchase.Purchase memory) {
    return purchases.getValue(_account);
  }
}

interface IERC20 {
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
}
