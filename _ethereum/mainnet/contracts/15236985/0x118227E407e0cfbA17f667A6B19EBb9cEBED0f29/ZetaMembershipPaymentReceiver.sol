//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Context.sol";

error PurchaseQuantityExceeded();
error PurchaseNoQuantity();
error PurchaserOverpaid();
error PurchaserUnderpaid();
error NotPurchasable();

contract ZetaMembershipPaymentReceiver is
  Context,
  Ownable
{
  struct PurchaseData {
    uint256 purchaseId;
    uint256 purchaseDate;
    uint256 quantity;
    string memo;
  }

  bool public isPurchasable = true;
  uint256 public maxPurchasableQuantity;
  uint256 public price;
  uint256 public purchasesCounter;
  address[] public purchasers;
  mapping(address => PurchaseData[]) public purchases;

  // keep the event data unstructured to make serialization easier
  event Purchase(
    uint256 purchaseId,
    address purchaser,
    uint256 purchaseDate,
    uint256 quantity,
    uint256 price,
    string memo
  );

  constructor(uint256 _price, uint256 _maxPurchasableQuantity, uint256 _purchasesCounter) {
    price = _price;
    maxPurchasableQuantity = _maxPurchasableQuantity;
    purchasesCounter = _purchasesCounter;
  }

  // limit malicious attacks by calling non-existent functions
  fallback() external payable {
    // TODO Log event that someone was trying to call a non-existent function
  }

  // transfer funds if someone pays the contract directly
  // this is *not* a purchase operation
  receive() external payable {
    if (msg.value != 0) {
      payable(owner()).transfer(msg.value);
    }
  }

  function purchase(uint256 quantity, string calldata memo) public payable {
    if (!isPurchasable) {
      revert NotPurchasable();
    }

    if (quantity == 0) {
      revert PurchaseNoQuantity();
    }

    if (quantity > maxPurchasableQuantity) {
      revert PurchaseQuantityExceeded();
    }

    if (msg.value > price * quantity) {
      revert PurchaserOverpaid();
    }

    if (msg.value < price * quantity) {
      revert PurchaserUnderpaid();
    }

    PurchaseData memory data;
    // increment after save
    data.purchaseId = purchasesCounter++;
    // solhint-disable-next-line not-rely-on-time
    data.purchaseDate = block.timestamp;
    data.quantity = quantity;
    data.memo = memo;

    if (purchases[_msgSender()].length == 0) {
      purchasers.push(_msgSender());
    }
    purchases[_msgSender()].push(data);

    // solhint-disable-next-line not-rely-on-time
    emit Purchase(data.purchaseId, _msgSender(), block.timestamp, quantity, price, memo);
  }

  function getPurchasers()
    public
    view
    returns (address[] memory)
  {
    if (purchasers.length == 0) {
      return new address[](0);
    }
    return getPurchasers(0, purchasers.length - 1);
  }

  function getPurchasers(uint256 start)
    public
    view
    returns (address[] memory)
  {
    if (purchasers.length == 0) {
      return new address[](0);
    }
    return getPurchasers(start, purchasers.length - 1);
  }

  function getPurchasers(uint256 start, uint256 end)
    public
    view
    returns (address[] memory)
  {
    require(
      start <= end,
      "InvalidRange"
    );
    require(
      start < purchasers.length &&
      end < purchasers.length,
      "IndexOutOfBounds"
    );
    uint256 count = end - start + 1;
    address[] memory slice = new address[](count);
    for (uint i = 0; i < count; i++) {
      slice[i] = purchasers[start + i];
    }

    return slice;
  }

  function getPurchasersLength()
    public
    view
    returns (uint256)
  {
    return purchasers.length;
  }

  function getPurchaserPurchases(address _address)
    public
    view
    returns (PurchaseData[] memory)
  {
    if (purchases[_address].length == 0) {
      return new PurchaseData[](0);
    }
    return getPurchaserPurchases(_address, 0, purchases[_address].length - 1);
  }

  function getPurchaserPurchases(address _address, uint256 start)
    public
    view
    returns (PurchaseData[] memory)
  {
    if (purchases[_address].length == 0) {
      return new PurchaseData[](0);
    }
    return getPurchaserPurchases(_address, start, purchases[_address].length - 1);
  }

  function getPurchaserPurchases(address _address, uint256 start, uint256 end)
    public
    view
    returns (PurchaseData[] memory)
  {
    require(
      start <= end,
      "InvalidRange"
    );
    require(
      start < purchases[_address].length &&
      end < purchases[_address].length,
      "IndexOutOfBounds"
    );
    uint256 count = end - start + 1;
    PurchaseData[] memory slice = new PurchaseData[](count);
    for (uint i = 0; i < count; i++) {
      slice[i] = purchases[_address][start + i];
    }

    return slice;
  }

  function getPurchaserPurchasesLength(address _address)
    public
    view
    returns (uint256)
  {
    return purchases[_address].length;
  }

  function setPrice(uint256 _price) public onlyOwner {
    price = _price;
  }

  function setIsPurchasable(bool _isPurchasable) public onlyOwner {
    isPurchasable = _isPurchasable;
  }

  function setMaxPurchasableQuantity(uint256 _maxPurchasableQuantity) public onlyOwner {
    maxPurchasableQuantity = _maxPurchasableQuantity;
  }

  function withdraw() external onlyOwner {
    payable(owner()).transfer(address(this).balance);
  }
}
