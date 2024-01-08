// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20Mintable.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract PrintServiceV2 is Ownable {

  event PrintOrderReceived(
    uint indexed _orderId,
    bytes32 indexed _orderHash,
    uint256 _productId,
    address _collection, 
    uint256 _tokenId
  );

  struct Product { 
    string id;
    uint256 price;
    bool inStock;
  }

  address constant ETH_ID = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
  uint256 public orderId;

  address payable public treasury;
  mapping (address => mapping (uint256 => Product)) public config;

  constructor (
    address payable _treasury,
    uint256 _orderId
  ) {
    treasury = _treasury;
    orderId = _orderId;
  }

  function setTreasury(address payable _treasury) public onlyOwner {
    treasury = _treasury;
  }

  function setProducts(address _currency, Product[] memory _products) public onlyOwner {
    for (uint index = 0; index < _products.length; index++) {
      config[_currency][index] = _products[index];
    }
  }

  function setInStock(address _currency, uint256 _productIndex, bool _inStock) public onlyOwner {
    config[_currency][_productIndex].inStock = _inStock;
  }

  function setPrice(address _currency, uint256 _productIndex, uint256 _price) public onlyOwner {
    config[_currency][_productIndex].price = _price;
  }

  function buy(address _currency, uint256 _productIndex, address _collection, uint256 _tokenId, bytes32 _orderHash) public payable {
    Product memory product = config[_currency][_productIndex];
    uint256 price = product.price;

    require(product.inStock, "Out of stock");

    if (_currency == ETH_ID) { // if ETH
      uint256 amountPaid = msg.value;
      require(price <= msg.value, "Insufficient payment"); // ensure enough payment
      treasury.call{value: price }(""); // transfer ETH to Treasury
      msg.sender.call{value: amountPaid - price}(""); // transfer any overpayment back to payer
    } else { // is ERC20
      ERC20Mintable(_currency).transferFrom(_msgSender(), treasury, price); // transfer ERC20
    }
    
    orderId += 1;
    emit PrintOrderReceived(orderId, _orderHash, _productIndex, _collection, _tokenId);
  }
}