//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./KissMas.sol";

contract PublicSale is Ownable {

  // slot 0
  uint32 public saleStart;
  uint32 public saleEnd;
  uint96 public price;
  uint16 public maxAmount;

  struct Shareholder {
    address wallet;
    uint96 shares;
  }

  // slot 1
  Shareholder[2] public shareholders;

  KissMas public immutable kissmas;
  uint private constant SHARES_DENOMINATOR = 100;

  error TransferFailed();
  error IncorrectETHAmount();
  error SaleNotStarted();
  error SaleEnded();
  error Soldout();
  error InvalidSaleDates(uint saleStart, uint saleEnd);

  constructor(KissMas _kissmas, Shareholder[2] memory _shareholders) {

    kissmas = _kissmas;
    uint totalShares = 0;

    for (uint i = 0; i < 2; i++) {
      totalShares += _shareholders[i].shares;
      shareholders[i] = _shareholders[i];
    }

    require(totalShares == SHARES_DENOMINATOR);
  }

  function buy(uint amount) external payable {

    uint32 _saleStart = saleStart;
    uint32 _saleEnd = saleEnd;
    uint96 _price = price;

    if (block.timestamp < _saleStart) {
      revert SaleNotStarted();
    }

    if (block.timestamp > _saleEnd) {
      revert SaleEnded();
    }

    uint currentSupply = kissmas.totalSupply();
    uint maxSupply = 254;

    if (currentSupply >= maxSupply) {
      revert Soldout();
    }

    if (currentSupply + amount > maxSupply) {
      amount = maxSupply - currentSupply;
    }

    uint cost = amount * _price;

    if (_price == 0 || msg.value < cost) {
      revert IncorrectETHAmount();
    }

    address[] memory destinations = new address[](1);
    destinations[0] = msg.sender;

    uint[] memory amounts = new uint[](1);
    amounts[0] = amount;

    uint expectedSupply = currentSupply + amount;
    kissmas.mint(destinations, amounts, expectedSupply);

    if (msg.value > cost) {
      uint remainder = msg.value - cost;
      (bool ok,) = msg.sender.call{ value: remainder }("");
      require(ok);
    }
  }

  function setSaleDetails(
    uint32 _saleStart,
    uint32 _saleEnd,
    uint96 _price
  ) external onlyOwner {

    if (_saleStart > _saleEnd) {
      revert InvalidSaleDates(_saleStart, _saleEnd);
    }

    if (_price == 0) {
      revert IncorrectETHAmount();
    }

    saleStart = _saleStart;
    saleEnd = _saleEnd;
    price = _price;
  }

  function ownerMint(
    address[] calldata destinations,
    uint[] calldata amounts,
    uint expectedSupply
  ) external onlyOwner {
    kissmas.mint(destinations, amounts, expectedSupply);
  }

  function updateShareholders(Shareholder[2] calldata _shareholders) external onlyOwner {

    uint totalShares = 0;

    for (uint i = 0; i < 2; i++) {
      totalShares += _shareholders[i].shares;
      shareholders[i] = _shareholders[i];
    }

    require(totalShares == SHARES_DENOMINATOR);
  }

  function withdraw() external onlyOwner {

    uint balance = address(this).balance;

    for (uint i = 0; i < 2; i++) {

      uint amount = balance * shareholders[i].shares / SHARES_DENOMINATOR;
      (bool ok,) = shareholders[i].wallet.call{value : amount}("");

      if (!ok) {
        revert TransferFailed();
      }
    }

  }

}
