// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "./PausableNFT.sol";
import "./Ownable.sol";

/**
 * It aint much, but it's honest work.
 */
contract KryptoWriteAd is PausableNFT, Ownable {
  using Address for address;
  using SafeMath for uint256;

  // uint256 constant CONTRACT_SHARE_TENTHS = 1; // implicit
  uint256 constant MINTER_SHARE_TENTHS = 2;
  uint256 constant PREVIOUS_OWNER_SHARE_TENTHS = 7;

  uint256 public discountLimit = 5; // x -> every x is free.
  uint256 public mintingCost;

  bool private reEntrancyLocked = false;

  constructor(
    uint88 _gasCompensation,
    uint96 _initialTokenPrice,
    uint256 _mintingCost,
    uint8 _priceIncreaseTenths
  ) {
    gasCompensation = _gasCompensation;
    initialTokenPrice = _initialTokenPrice;
    mintingCost = _mintingCost;
    priceIncreaseTenths = _priceIncreaseTenths;
  }

  function buy(uint256 _id) external payable {
    require(!reEntrancyLocked);
    reEntrancyLocked = true;

    require(_id < nextTokenId);

    TokenInfo storage info = tokenInfo[_id];

    uint256 newPrice = _multiplyByTenths(uint256(info.previousPrice), uint256(info.previousPriceIncrease));
    uint256 total = newPrice.add(uint256(info.previousGasCompensation));
    _bought(info.owner, msg.sender, _id, total);
    require(msg.value >= total);

    uint256 refund = msg.value.sub(total);

    if (refund > 0) {
      (bool refundSuccess, ) = msg.sender.call{value: refund}('');
      require(refundSuccess);
    }

    uint256 previousPrice = uint256(info.previousPrice);
    uint256 previousGasCompensation = uint256(info.previousGasCompensation);
    address previousOwner = info.owner;
    uint256 priceIncrease = newPrice.sub(previousPrice);

    info.owner = msg.sender;
    info.previousPrice = _toUint96(newPrice);
    info.previousPriceIncrease = priceIncreaseTenths;
    info.previousGasCompensation = gasCompensation;

    info.minter.call{value: _multiplyByTenths(priceIncrease, MINTER_SHARE_TENTHS)}('');
    previousOwner.call{
      value: previousPrice.add(_multiplyByTenths(priceIncrease, PREVIOUS_OWNER_SHARE_TENTHS)).add(
        previousGasCompensation
      )
    }('');

    reEntrancyLocked = false;
  }

  function buyMany(uint256[] memory ids) external payable {
    require(!reEntrancyLocked);
    reEntrancyLocked = true;
    require(ids.length > 0);

    uint256 totalCost = 0;

    for (uint256 i = 0; i < ids.length; i++) {
      require(ids[i] < nextTokenId);
      TokenInfo storage info = tokenInfo[ids[i]];

      uint256 newPrice = _multiplyByTenths(uint256(info.previousPrice), uint256(info.previousPriceIncrease));
      uint256 total = newPrice.add(uint256(info.previousGasCompensation));
      _bought(info.owner, msg.sender, ids[i], total);
      totalCost = totalCost.add(total);

      uint256 previousPrice = info.previousPrice;
      uint256 previousGasCompensation = uint256(info.previousGasCompensation);
      address previousOwner = info.owner;
      uint256 priceIncrease = newPrice.sub(previousPrice);

      info.owner = msg.sender;
      info.previousPrice = _toUint96(newPrice);
      info.previousPriceIncrease = priceIncreaseTenths;
      info.previousGasCompensation = gasCompensation;

      info.minter.call{value: _multiplyByTenths(priceIncrease, MINTER_SHARE_TENTHS)}('');
      previousOwner.call{
        value: previousPrice.add(_multiplyByTenths(priceIncrease, PREVIOUS_OWNER_SHARE_TENTHS)).add(
          previousGasCompensation
        )
      }('');
    }
    require(msg.value >= totalCost, 'payment too low');

    uint256 refund = msg.value.sub(totalCost);
    if (refund > 0) {
      (bool refundSuccess, ) = msg.sender.call{value: refund}('');
      require(refundSuccess, 'could not refund');
    }

    reEntrancyLocked = false;
  }

  function calcBuyCost(uint256 id) external view returns (uint256) {
    TokenInfo storage info = tokenInfo[id];
    return
      _multiplyByTenths(uint256(info.previousPrice), uint256(info.previousPriceIncrease)).add(
        uint256(info.previousGasCompensation)
      );
  }

  function calcMintManyCost(uint256 amount) public view returns (uint256) {
    if (mintingCost == 0) {
      return 0;
    }
    if (amount < discountLimit) {
      return amount.mul(mintingCost);
    }

    return amount.sub(amount.div(discountLimit)).mul(mintingCost);
  }

  function mint() external payable {
    require(msg.value == mintingCost, 'payment / token price mismatch');
    _mint(msg.sender);
  }

  function mintMany(uint256 amount) external payable {
    require(amount > 0);
    uint256 cost = calcMintManyCost(amount);
    require(msg.value == cost); // must pay exact. so no refunds necessary.

    for (uint256 i = 0; i < amount; i++) {
      _mint(msg.sender);
    }
  }

  function setGasCompensation(uint88 amount) external onlyOwner {
    require(amount < 2**88);
    gasCompensation = amount;
  }

  function setInitialTokenPrice(uint96 price) external onlyOwner {
    require(price > 0);
    initialTokenPrice = price;
  }

  function setMinterAddress(uint256 id, address newAddress) external {
    TokenInfo storage info = tokenInfo[id];
    require(msg.sender == info.minter && msg.sender != address(0));
    info.minter = newAddress;
  }

  function setMintingCost(uint256 cost) external onlyOwner {
    mintingCost = cost;
  }

  function setMintingDiscountLimit(uint256 limit) external onlyOwner {
    require(limit > 0);
    discountLimit = limit;
  }

  function setPaused(bool status) external onlyOwner {
    if (status) {
      _pause();
    } else {
      _unpause();
    }
  }

  function setPriceIncreaseTenths(uint8 tenths) external onlyOwner {
    require(tenths < 2**8 && tenths >= 11); // price guaranteed to increase by 1.1x or more
    priceIncreaseTenths = tenths;
  }

  function withdraw() external onlyOwner {
    msg.sender.transfer(address(this).balance);
  }

  function _multiplyByTenths(uint256 value, uint256 tenths) internal pure returns (uint256) {
    return value.div(10).mul(tenths);
  }
}
