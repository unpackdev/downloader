// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./OwnableUpgradeable.sol";

import "./IXanaliaNFT.sol";
import "./IXanaliaAddressesStorage.sol";


contract MarketDex is Initializable, OwnableUpgradeable {

	uint256 public totalOrders;
	IXanaliaAddressesStorage public xanaliaAddressesStorage;

	struct Order {
		address owner;
		address collectionAddress;
		address paymentToken;
		uint256 tokenId;
		uint256 price;
		bool isOnsale; // true: on sale, false: cancel
	}

	mapping(uint256 => Order) public orders;
	mapping(bytes32 => uint256) private orderID;

	function initialize(address _xanaliaAddressesStorage) public initializer {
		__Ownable_init_unchained();
		xanaliaAddressesStorage = IXanaliaAddressesStorage(_xanaliaAddressesStorage);
	}

	modifier onlyXanaliaDex() {
        require(
            msg.sender == xanaliaAddressesStorage.xanaliaDex(),
            "Xanalia: caller is not xanalia dex"
        );
        _;
    }

	/**
	 * @dev Allow user create order on market
	 * @param _collectionAddress is address of NFTs
	 * @param _paymentToken is payment method (USDT, ETH, ...)
	 * @param _tokenId is id of NFTs
	 * @param _price is price per item in payment method (example 50 USDT)
	 */
	function createOrder(
		address _collectionAddress,
		address _paymentToken,
		address _itemOwner,
		uint256 _tokenId,
		uint256 _price
	) external onlyXanaliaDex returns (uint256 _orderId) {	
		totalOrders ++;
		_orderId = totalOrders;

		Order memory newOrder;
		newOrder.isOnsale = true;
		newOrder.owner = _itemOwner;
		newOrder.price = _price;
		newOrder.tokenId = _tokenId;
		newOrder.collectionAddress = _collectionAddress;
		newOrder.paymentToken = _paymentToken;

		orders[_orderId] = newOrder;

		return _orderId;
	}

	function editOrder(
		address _orderOwner,
		uint256 _orderId,
		uint256 _price
	) external onlyXanaliaDex returns (uint256, uint256) {	
		Order storage oldOrder = orders[_orderId];
		require(oldOrder.price > 0, "Order-not-exist");
		require(_orderOwner == oldOrder.owner, "Not-owner-of-order");
		require(oldOrder.isOnsale, "Order-cancelled");
		
		oldOrder.isOnsale = false;
		uint256 oldOrderId = _orderId;
		totalOrders++;
		_orderId = totalOrders;

		orders[_orderId] = oldOrder;
		orders[_orderId].price = _price;
		orders[_orderId].isOnsale = true;

		return (_orderId, oldOrderId);
	}

	function buy(uint256 _orderId, address _paymentToken) external onlyXanaliaDex returns (uint256, address, uint256, address) {
		Order memory order = orders[_orderId];
		require(order.owner != address(0), "Invalid-order-id");
		require(_paymentToken == order.paymentToken, "Payment-token-invalid");
		require(order.isOnsale, "Not-on-sale");

		// Update sale status
		orders[_orderId].isOnsale = false;

		return (order.price, order.collectionAddress, order.tokenId, order.owner);
	}

	function cancelOrder(uint256 _orderId, address _orderOwner) external onlyXanaliaDex returns (address, address, uint256) {
		Order memory order = orders[_orderId];
		require(order.owner == _orderOwner && order.isOnsale, "Oops!Wrong-order-owner-or-cancelled");

		orders[_orderId].isOnsale = false;

		return (order.collectionAddress, order.owner, order.tokenId);
	}
	
	function setAddressesStorage (address _xanaliaAddressesStorage) external onlyOwner {
		xanaliaAddressesStorage = IXanaliaAddressesStorage(_xanaliaAddressesStorage);
	}
}
