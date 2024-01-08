// SPDX-License-Identifier: Unlicense
pragma solidity =0.6.8;
import "./IERC1155.sol";
import "./ERC1155Holder.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./ReentrancyGuard.sol";


contract EddaNFTMarket is ERC1155Holder, Ownable, Pausable, ReentrancyGuard {
	using Address for address payable;
	using SafeMath for uint256;
	using SafeERC20 for IERC20;

	struct Order {
		address orderOwner;
		uint256 tokenId;
		uint256 amount;
		uint256 pricePerToken;
		address paymentToken;
	}

	IERC1155 public immutable eddaNFT;
	address public eddaTreasury;
	uint256 public totalOrder;
	mapping(uint256 => Order) public orders;
	mapping(uint256 => bool) public orderMap;

	event NewNFTListing(uint256 indexed orderId, address indexed owner, address indexed paymentMethod, uint256 tokenId, uint256 tokenAmount, uint256 price);
	event Cancel(uint256 indexed orderId);
	event Sold(uint256 indexed orderId, uint256 indexed tokenId, uint256 indexed amount);

	constructor(address _eddaNFT, address _eddaTreasury) public {
		eddaNFT = IERC1155(_eddaNFT);
		eddaTreasury = _eddaTreasury;
	}

	function updateTreasury(address _eddaTreasury) external onlyOwner() {
		eddaTreasury = _eddaTreasury;
	}

	function stop() external onlyOwner() {
		require(!paused(), 'Already-paused');
		_pause();
	}

	function start() external onlyOwner() {
		require(paused(), 'Not-pause-yet');
		_unpause();
	}

	function _incrementOrderId() private {
		totalOrder++;
	}

	function listOnMarket(
		uint256 tokenId,
		uint256 amount,
		uint256 price,
		address paymentToken
	) external whenNotPaused() onlyOwner() {
		require(amount > 0, 'Invalid-amount');
		require(price > 0, 'Invalid-price');
		eddaNFT.safeTransferFrom(msg.sender, address(this), tokenId, amount, '0x');
		Order memory newOrder;
		newOrder.orderOwner = msg.sender;
		newOrder.tokenId = tokenId;
		newOrder.amount = amount;
		newOrder.pricePerToken = price;
		newOrder.paymentToken = paymentToken;
		orders[totalOrder] = newOrder;
		emit NewNFTListing(totalOrder, msg.sender, paymentToken, tokenId, amount, price);
		_incrementOrderId();
	}
	
	function cancelOrder(uint256 orderId) external whenNotPaused() {
		Order memory order = orders[orderId];
		require(order.orderOwner == msg.sender, 'Only-owner-can-cancel');
		// transfer back NFTs
		eddaNFT.safeTransferFrom(address(this), msg.sender, order.tokenId, order.amount, abi.encodePacked(keccak256('onERC1155Received(address,address,uint256,uint256,bytes)')));
		delete orders[orderId];
		emit Cancel(orderId);
	}

	function buy(
		uint256 orderId,
		uint256 amount
	) external payable whenNotPaused() nonReentrant() {
		require(amount > 0, 'Invalid-amount');
		Order memory order = orders[orderId];
		require(amount <= order.amount, 'Invalid-amount');
		uint256 orderAmount = order.pricePerToken.mul(amount);
		if (order.paymentToken  == address(0)) {
			// paid in ETH
			require(msg.value >= orderAmount);
			payable(eddaTreasury).sendValue(msg.value);
		} else {
			IERC20(order.paymentToken).safeTransferFrom(msg.sender, eddaTreasury, orderAmount);
		} 
		eddaNFT.safeTransferFrom(address(this), msg.sender, order.tokenId, amount, abi.encodePacked(keccak256('onERC1155Received(address,address,uint256,uint256,bytes)')));
		order.amount = order.amount.sub(amount);
		orders[orderId] = order;
		emit Sold(orderId, order.tokenId, amount);
	}

	function withDrawToken(address _token) external onlyOwner() {
		if (_token != address(0)) {
			uint256 tokenBalance = IERC20(_token).balanceOf(address(this));
			IERC20(_token).safeTransfer(msg.sender, tokenBalance);
			return;
		}
		payable(msg.sender).sendValue(address(this).balance);
	}

	receive() external payable { }
}
