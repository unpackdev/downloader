// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./Pausable.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./MarketplaceStorage.sol";

import "./console.sol";

contract Marketplace is Pausable, Ownable, MarketplaceStorage, ReentrancyGuard {
	using SafeMath for uint256;
	using Address for address;

	/**
	 * @dev Sets the share cut for the owner of the contract that's
	 *  charged to the seller on a successful sale
	 * @param _ownerCutPerMillion - Share amount, from 0 to 999,999
	 */
	function setOwnerCutPerMillion(uint256 _ownerCutPerMillion)
		external
		onlyOwner
	{
		require(
			_ownerCutPerMillion < 1000000,
			"The owner cut should be between 0 and 999,999"
		);

		ownerCutPerMillion = _ownerCutPerMillion;
		emit ChangedOwnerCutPerMillion(ownerCutPerMillion);
	}

	function _requireERC721(address nftAddress) internal view {
		require(nftAddress.isContract(), "address should be a contract");

		IERC721 nftRegistry = IERC721(nftAddress);
		require(
			nftRegistry.supportsInterface(ERC721_Interface),
			"The NFT contract has an invalid ERC721 implementation"
		);
	}

	/**
	 * @dev Updates price on existing order
	 * @param nftAddress - Non fungible registry address
	 * @param assetId - ID of the published NFT
	 * @param newPrice - Price in Wei for the supported coin
	 */
	function changePrice(
		address nftAddress,
		uint256 assetId,
		uint256 newPrice
	) public whenNotPaused {
		_changePrice(nftAddress, assetId, newPrice);
	}

	/**
	 * @dev Updates price on existing order
	 * @param nftAddress - Non fungible registry address
	 * @param assetId - ID of the published NFT
	 * @param newPrice - Price in Wei for the supported coin
	 */
	function _changePrice(
		address nftAddress,
		uint256 assetId,
		uint256 newPrice
	) internal returns (Order memory) {
		Order memory order = orderByAssetId[nftAddress][assetId];
		require(order.id != 0, "Order hasn't been published");
		require(
			order.seller == msg.sender,
			"Unauthorized user"
		);
		require(block.timestamp < order.expiresAt, "The order is expired");
		require(newPrice > 0, "Price should be more than 0");
		require(
			newPrice != order.price,
			"Price should not be equal to the previous price"
		);

		orderByAssetId[nftAddress][assetId].price = newPrice;

		emit PriceUpdated(
			order.id,
			assetId,
			order.seller,
			nftAddress,
			order.price,
			newPrice,
			order.expiresAt
		);

		return order;
	}

	/**
	 * @dev Creates a new order
	 * @param nftAddress - Non fungible registry address
	 * @param assetId - ID of the published NFT
	 * @param priceInWei - Price in Wei for the supported coin
	 * @param expiresAt - Duration of the order (in hours)
	 */
	function createOrder(
		address nftAddress,
		uint256 assetId,
		uint256 priceInWei,
		uint256 expiresAt
	) public whenNotPaused {
		_createOrder(nftAddress, assetId, priceInWei, expiresAt);
	}

	/**
	 * @dev Creates a new order
	 * @param nftAddress - Non fungible registry address
	 * @param assetId - ID of the published NFT
	 * @param priceInWei - Price in Wei for the supported coin
	 * @param expiresAt - Duration of the order (in hours)
	 */
	function _createOrder(
		address nftAddress,
		uint256 assetId,
		uint256 priceInWei,
		uint256 expiresAt
	) internal {
		_requireERC721(nftAddress);

		IERC721 nftRegistry = IERC721(nftAddress);
		address assetOwner = nftRegistry.ownerOf(assetId);

		require(
			msg.sender == assetOwner,
			"Only the owner can create or update orders"
		);
		require(
			nftRegistry.getApproved(assetId) == address(this) ||
				nftRegistry.isApprovedForAll(assetOwner, address(this)),
			"The contract is not authorized to manage the asset"
		);
		require(priceInWei > 0, "Price should be more than 0");
		require(
			expiresAt > block.timestamp.add(1 minutes),
			"Publication should be more than 1 minute in the future"
		);

		bytes32 orderId = keccak256(
			abi.encodePacked(
				block.timestamp,
				assetOwner,
				assetId,
				nftAddress,
				priceInWei
			)
		);

		orderByAssetId[nftAddress][assetId] = Order({
			id: orderId,
			seller: assetOwner,
			nftAddress: nftAddress,
			price: priceInWei,
			expiresAt: expiresAt
		});

		emit OrderCreated(
			orderId,
			assetId,
			assetOwner,
			nftAddress,
			priceInWei,
			expiresAt
		);
	}

	/**
	 * @dev Cancel an already published order
	 *  can only be canceled by seller or the contract owner
	 * @param nftAddress - Address of the NFT registry
	 * @param assetId - ID of the published NFT
	 */
	function cancelOrder(address nftAddress, uint256 assetId)
		public
		whenNotPaused
	{
		_cancelOrder(nftAddress, assetId);
	}

	/**
	 * @dev Cancel an already published order
	 *  can only be canceled by seller or the contract owner
	 * @param nftAddress - Address of the NFT registry
	 * @param assetId - ID of the published NFT
	 */
	function _cancelOrder(address nftAddress, uint256 assetId)
		internal
		returns (Order memory)
	{
		Order memory order = orderByAssetId[nftAddress][assetId];

		require(order.id != 0, "Asset not published");
		require(
			order.seller == msg.sender || msg.sender == owner(),
			"Unauthorized user"
		);

		bytes32 orderId = order.id;
		address orderSeller = order.seller;
		address orderNftAddress = order.nftAddress;
		delete orderByAssetId[nftAddress][assetId];

		emit OrderCancelled(orderId, assetId, orderSeller, orderNftAddress);

		return order;
	}

	/**
	 * @dev Executes the sale for a published NFT
	 * @param nftAddress - Address of the NFT registry
	 * @param assetId - ID of the published NFT
	 */
	function executeOrder(address nftAddress, uint256 assetId)
		public
		payable
		whenNotPaused
	{
		_executeOrder(nftAddress, assetId);
	}

	/**
	 * @dev Executes the sale for a published NFT
	 * @param nftAddress - Address of the NFT registry
	 * @param assetId - ID of the published NFT
	 */
	function _executeOrder(address nftAddress, uint256 assetId)
		internal
		returns (Order memory)
	{
		_requireERC721(nftAddress);

		IERC721 nftRegistry = IERC721(nftAddress);

		Order memory order = orderByAssetId[nftAddress][assetId];

		require(order.id != 0, "Asset not published");

		address seller = order.seller;

		uint256 saleShareAmount = order.price.mul(ownerCutPerMillion).div(
			1000000
		);

		// add fee on top for buyer.
		uint256 purchasePrice = order.price.add(saleShareAmount);

		require(seller != address(0), "Invalid address");
		require(seller != msg.sender, "Unauthorized user");
		require(msg.value >= purchasePrice, "The price is not correct");
		require(block.timestamp < order.expiresAt, "The order expired");
		require(
			seller == nftRegistry.ownerOf(assetId),
			"The seller is no longer the owner"
		);

		bytes32 orderId = order.id;
		/** Delete existing order */
		delete orderByAssetId[nftAddress][assetId];

		// if (ownerCutPerMillion > 0) {
		// Calculate sale share
		// saleShareAmount = order.price.mul(ownerCutPerMillion).div(1000000);

		// send the ether to "owner"
		// require(
		// 	payable(owner()).send(saleShareAmount),
		// 	"Transfering the cut to the Marketplace owner failed"
		// );

		// console.log("sent ether to the owner :: ", address(this).balance);
		// Transfer share amount for marketplace Owner
		// require(
		// 	acceptedToken.transferFrom(
		// 		msg.sender,
		// 		owner(),
		// 		saleShareAmount
		// 	),
		// 	"Transfering the cut to the Marketplace owner failed"
		// );
		// }

		// send the ether to seller
		require(
			payable(seller).send(order.price.sub(saleShareAmount)),
			"Transfering the sale amount to the seller failed"
		);

		// console.log(
		// 	"sent ether to the seller :: ",
		// 	order.price.sub(saleShareAmount)
		// );
		// console.log("balance", address(this).balance);
		// Transfer sale amount to seller
		// require(
		// 	acceptedToken.transferFrom(
		// 		msg.sender,
		// 		seller,
		// 		price.sub(saleShareAmount)
		// 	),
		// 	"Transfering the sale amount to the seller failed"
		// );

		// Transfer asset owner
		nftRegistry.safeTransferFrom(seller, msg.sender, assetId);

		emit OrderSuccessful(
			orderId,
			assetId,
			seller,
			nftAddress,
			order.price,
			msg.sender
		);

		return order;
	}

	/**
	 * @dev withdraw all balances to the owner
	 */
	function withdraw() public onlyOwner {
		uint256 balances = address(this).balance;
		payable(owner()).transfer(balances);
		emit Withdraw(msg.sender, balances);
	}

	/**
	 * @dev withdraw to specific account
	 * @param _address - Address of account
	 * @param _amountInWei - amount of balances to withdraw in wei
	 */
	function withdrawTo(address _address, uint256 _amountInWei)
		public
		nonReentrant
		onlyOwner
	{
		require(address(this).balance >= _amountInWei, "not enough balances");
		payable(_address).transfer(_amountInWei);
		emit WithdrawTo(_address, _amountInWei);
	}

	/**
	 * Keep all Ether sent.
	 */
	receive() external payable {
		emit Received(msg.sender, msg.value);
	}
}
