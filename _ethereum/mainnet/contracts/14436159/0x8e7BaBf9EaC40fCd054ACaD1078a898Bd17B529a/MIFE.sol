// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Libs.sol";
import "./BaseControl.sol";
import "./ERC20Burnable.sol";

contract MIFE is BaseControl, ERC20Burnable {
  using MapPurchase for MapPurchase.Purchase;
  using MapPurchase for MapPurchase.Record;

  struct Initial {
    address account;
    uint256 amount;
  }

  // constants
  // variables
  uint256 public quantityReleased;
  MapPurchase.Record purchases;


  constructor() ERC20("The Metalife", "MIFE") {
    uint256 maxSupply = 3000000000 * (10 ** decimals());

    uint256 list_a = 300000000 * (10 ** decimals());
    _mint(0x12E36b7D140f8083d2da50F977F5ca8C415193EF, list_a);
    _mint(0x99AD6259C66d32144bCc226b45472C6Def82397B, list_a);

    uint256 list_b = 60000000 * (10 ** decimals());
    _mint(0x3411118a35A1F20e5b45324a50bA24990c667928, list_b);
    _mint(0x9114DE606aAEba34E0AdEABcBdE7F6Aa212A7ee0, list_b);
    _mint(0xFed7EC360e5200F725109fA68917b33Face2B99e, list_b);
    _mint(0xdE906C27793eF5521A3c8F2732dE71Bfd2c14aA9, list_b);
    _mint(0x34abb70836476B9E93Aa516188b0667936b9e36F, list_b);

    // 2100000000
    _mint(0x5B7D2199d748f3fdfB744e7756290b29d4c83FD3, maxSupply - list_a * 2 - list_b * 5);
  }

  /** Public */
  function privateSale(bytes memory _signature) external payable {
    uint16 rate = 12000;
    require(tx.origin == msg.sender, "Not allowed");
    require(privateSaleActive, "Not active");
    require(!purchases.containsValue(msg.sender), "Already purchased");
    require(msg.value >= 2 ether && msg.value <= 20 ether, "Ether value incorrect");
    // check supply
    (uint256 tokenAmount, uint256 bonusAmount, ) = Utilities.computeReward(msg.value, rate, decimals(), Utilities.getPrivateBonus);
    require(quantityReleased + tokenAmount + bonusAmount <= 150000000 * (10 ** decimals()), "Exceed supply");
    // check whitelist
    require(eligibleByWhitelist(msg.sender, msg.value, _signature), "Not eligible");

    purchases.addValue(msg.sender, msg.value, rate, decimals(), Utilities.getPrivateBonus);
    quantityReleased += (tokenAmount + bonusAmount);
  }

  function publicSale() external payable {
    uint16 rate = 10000;
    require(tx.origin == msg.sender, "Not allowed");
    require(publicSaleActive, "Not active");
    require(!purchases.containsValue(msg.sender), "Already purchased");
    require(msg.value >= 0.5 ether && msg.value <= 8 ether, "Ether value incorrect");
    // check supply
    (uint256 tokenAmount, uint256 bonusAmount, ) = Utilities.computeReward(msg.value, rate, decimals(), Utilities.getPublicBonus);
    require(quantityReleased + tokenAmount + bonusAmount <= 450000000 * (10 ** decimals()), "Exceed supply");

    purchases.addValue(msg.sender, msg.value, rate, decimals(), Utilities.getPublicBonus);
    quantityReleased += (tokenAmount + bonusAmount);
  }

  /** Admin */
  function issueBonus(uint256 _start, uint256 _end) external onlyOwner {
    uint256 maxSize = getPurchasersSize();
    _end = _end > maxSize ? maxSize : _end;

    for (uint256 i = _start; i < _end; i++) {
      MapPurchase.Purchase storage record = purchases.values[i];
      if (record.tokenAmount == 0 && record.bonusAmount > 0) {
        IERC20(address(this)).transfer(record.account, record.bonusAmount);
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
        IERC20(address(this)).transfer(record.account, amount);
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
    uint256 balance = IERC20(address(this)).balanceOf(address(this));
    IERC20(address(this)).transfer(msg.sender, balance);
  }

  /** View */
  function eligibleByWhitelist(address _account, uint256 _stakeValue, bytes memory _signature) public view returns (bool) {
    bytes32 message = keccak256(abi.encodePacked(hashKey, 'normal', _account));
    if (_stakeValue >= 19 ether) {
      message = keccak256(abi.encodePacked(hashKey, 'special', _account));
    }
    return validSignature(message, _signature);
  }

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
