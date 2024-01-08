//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./KissMas.sol";

contract PrivateSale is Ownable {

  // slot 0
  uint32 public saleStart;
  uint32 public saleEnd;
  uint96 public price;

  struct Shareholder {
    address wallet;
    uint96 shares;
  }

  // slot 1
  Shareholder[2] public shareholders;

  // slot 2
  mapping(address => bool) public hasBought;

  // slot 3
  bytes32 public walletsHash;

  KissMas public immutable kissmas;
  uint private constant SHARES_DENOMINATOR = 100;

  error AccessDenied(address expectedCaller);
  error TransferFailed();
  error IncorrectPrice();
  error SaleNotStarted();
  error SaleEnded();
  error InvalidWalletsHash();
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

  function buy(address[] calldata wallets) external payable {

    uint32 _saleStart = saleStart;
    uint32 _saleEnd = saleEnd;
    uint96 _price = price;

    if (walletsHash != keccak256(abi.encode(wallets))) {
      revert InvalidWalletsHash();
    }

    bool inList = false;

    for (uint i = 0; i < wallets.length; i++) {
      if (wallets[i] == msg.sender) {
        inList = true;
      }
    }

    if (!inList || hasBought[msg.sender]) {
      revert AccessDenied(msg.sender);
    }

    hasBought[msg.sender] = true;

    if (block.timestamp < _saleStart) {
      revert SaleNotStarted();
    }

    if (block.timestamp > _saleEnd) {
      revert SaleEnded();
    }

    // revert if price is zero or msg.value is incorrect
    if (_price == 0 || msg.value != _price) {
      revert IncorrectPrice();
    }

    address[] memory destinations = new address[](1);
    destinations[0] = msg.sender;

    uint[] memory amounts = new uint[](1);
    amounts[0] = 1;

    uint expectedSupply = kissmas.totalSupply() + 1;

    kissmas.mint(destinations, amounts, expectedSupply);
  }

  function setSaleDetails(
    uint32 _saleStart,
    uint32 _saleEnd,
    uint96 _price,
    address[] memory wallets
  ) external onlyOwner {

    if (_saleStart > _saleEnd) {
      revert InvalidSaleDates(_saleStart, _saleEnd);
    }

    saleStart = _saleStart;
    saleEnd = _saleEnd;
    price = _price;
    walletsHash = keccak256(abi.encode(wallets));
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
