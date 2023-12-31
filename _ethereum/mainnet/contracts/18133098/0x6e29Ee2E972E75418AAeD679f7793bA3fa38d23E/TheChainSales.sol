//SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./IERC721.sol";

import "./OwnableOperators.sol";

import "./ITheChainCollection.sol";
import "./ITheChainSales.sol";

contract TheChainSales is ITheChainSales, OwnableOperators {
	error InvalidOrder();
	error TooEarly();
	error InvalidPayment();
	error FailedPayment();

	error TokenNotEscrowed();
	error UnknownOrder();
	error OrderExpired();

	struct ShareHolder {
		address account;
		uint96 share;
	}

	address public immutable THE_CHAIN;

	mapping(uint256 => Order) public orders;

	ShareHolder public theChainShare;

	uint256 private _lastOrderId;

	uint256 public startsAt;

	constructor(address theChain, ShareHolder memory initShare) {
		THE_CHAIN = theChain;
		theChainShare = initShare;
	}

	function getOrders(uint256[] calldata orderIds) external view override returns (Order[] memory) {
		uint256 length = orderIds.length;
		Order[] memory results = new Order[](length);
		for (uint i; i < length; i++) {
			results[i] = orders[orderIds[i]];
		}

		return results;
	}

	// =============================================================
	//                       	   Interactions
	// =============================================================

	function fulfillOrder(uint256 orderId) external payable override {
		Order memory order = _requireOrderExists(orderId);

		if (order.startsAt > block.timestamp || startsAt > block.timestamp) {
			revert TooEarly();
		}

		if (msg.value != order.price) {
			revert InvalidPayment();
		}

		// we delete the order
		delete orders[orderId];

		// we close it
		emit OrderClosed(orderId, msg.sender, false);

		ShareHolder memory theChainShare_ = theChainShare;

		// the chain
		uint256 share = (msg.value * theChainShare_.share) / 10000;
		if (share > 0) {
			_transferValue(theChainShare_.account, share);
		}

		// creator
		_transferValue(order.creator, msg.value - share);

		// transfer
		IERC721(THE_CHAIN).transferFrom(address(this), msg.sender, order.tokenId);
	}

	function createOrder(address creator, uint96 price, uint128 tokenId, uint128 saleStartsAt) external onlyOperator {
		_requireEscrowed(tokenId);

		uint256 orderId = ++_lastOrderId;

		orders[orderId] = Order(creator, price, tokenId, saleStartsAt);

		emit NewOrder(orderId, creator, tokenId, price, saleStartsAt);
	}

	// =============================================================
	//                    	Creators & Owner
	// =============================================================

	function cancelOrder(uint256 orderId, address recipient) external {
		// only the contract owner or the creator can cancel an order
		if (msg.sender != owner()) {
			if (msg.sender != orders[orderId].creator) {
				revert NotAuthorized();
			}
		}

		_cancelOrder(orderId, recipient);
	}

	function cancelOrders(uint256[] memory orderIds, address recipient) external onlyOwner {
		uint256 length = orderIds.length;
		for (uint256 i; i < length; i++) {
			_cancelOrder(orderIds[i], recipient);
		}
	}

	// =============================================================
	//                       	 Owner
	// =============================================================

	function editTheChainShares(ShareHolder calldata newShares) external onlyOwner {
		theChainShare = newShares;
	}

	/// @notice Allows owner to update when the sales starts
	/// @param newStartsAt the new timestamp (in seconds)
	function setStartsAt(uint256 newStartsAt) external onlyOwner {
		startsAt = newStartsAt;
	}

	// =============================================================
	//                       	 Internals
	// =============================================================

	function _transferValue(address payee, uint256 value) internal {
		(bool success, ) = payee.call{value: value, gas: 30_000}("");
		if (!success) {
			revert FailedPayment();
		}
	}

	function _requireOrderExists(uint256 orderId) internal view returns (Order memory) {
		Order memory order = orders[orderId];

		if (order.creator == address(0)) {
			if (orderId <= _lastOrderId) {
				revert OrderExpired();
			} else {
				revert UnknownOrder();
			}
		}

		_requireEscrowed(order.tokenId);

		return order;
	}

	function _requireEscrowed(uint256 tokenId) internal view {
		if (IERC721(THE_CHAIN).ownerOf(tokenId) != address(this)) {
			revert TokenNotEscrowed();
		}
	}

	function _cancelOrder(uint256 orderId, address recipient) internal {
		Order memory order = _requireOrderExists(orderId);

		// we delete the order
		delete orders[orderId];

		// we close it
		emit OrderClosed(orderId, msg.sender, true);

		// transfer to recipient
		IERC721(THE_CHAIN).transferFrom(address(this), recipient, order.tokenId);
	}
}
