// SPDX-License-Identifier: Unlicense
pragma solidity =0.6.8;
import "./ERC1155Holder.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./ReentrancyGuard.sol";
import "./IERC1155.sol";
import "./IUniswapRouter.sol";

contract EddaNFTMarket is ERC1155Holder, Ownable, Pausable, ReentrancyGuard {
	using Address for address payable;
	using SafeMath for uint256;
	using SafeERC20 for IERC20;

	struct Order {
		address orderOwner;
		address nftCreator;
		uint256 tokenId;
		uint256 amount;
		uint256 creatorFee;
		uint256 pricePerToken;
		address paymentToken;
	}
	uint256 private constant ZOOM = 10000;
	uint256 public constant deadline = 0xf000000000000000000000000000000000000000000000000000000000000000;
	IERC1155 public immutable eddaNFT;
	address public uniswapRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
	address public WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
	address public eddaTreasury;
	uint256 public totalOrder;
	mapping(uint256 => Order) public orders;
	mapping(address => bool) private isWhiteListPaymentMethod;

	event NewNFTListing(uint256 indexed orderId, address indexed owner, address indexed paymentMethod, uint256 tokenId, uint256 tokenAmount, uint256 price);
	event Sold(uint256 indexed orderId, uint256 indexed tokenId, uint256 indexed amount);

	constructor(address _eddaNFT, address _eddaTreasury) public {
		eddaNFT = IERC1155(_eddaNFT);
		eddaTreasury = _eddaTreasury;
		isWhiteListPaymentMethod[address(0)] = true; // white list for ETH
		isWhiteListPaymentMethod[WETH] = true;
	}

	function whiteListPaymentMethod(address[] calldata _tokens, bool[] calldata _isWhiteList) external onlyOwner() {
		for (uint256 i = 0; i < _tokens.length; i++) {
			isWhiteListPaymentMethod[_tokens[i]] = _isWhiteList[i];
			if (_isWhiteList[i] == true) {
				IERC20(_tokens[i]).safeApprove(uniswapRouter, uint256(-1));
			} else {
				IERC20(_tokens[i]).safeApprove(uniswapRouter, 0);
			}
		}
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

	function getPathFromTokenToToken(address fromToken, address toToken) private view returns (address[] memory) {
		if (fromToken == WETH || toToken == WETH) {
			address[] memory path = new address[](2);
			path[0] = fromToken == WETH ? WETH : fromToken;
			path[1] = toToken == WETH ? WETH : toToken;
			return path;
		} else {
			address[] memory path = new address[](3);
			path[0] = fromToken;
			path[1] = WETH;
			path[2] = toToken;
			return path;
		}
	}

	function estimateSwapAmount(
		address _fromToken,
		address _toToken,
		uint256 _amountOut
	) public view returns (uint256) {
		uint256[] memory amounts;
		address[] memory path;
		path = getPathFromTokenToToken(_fromToken, _toToken);
		amounts = IUniswapRouter(uniswapRouter).getAmountsIn(_amountOut, path);
		return amounts[0];
	}

	function _swapTokenForToken(
		address _tokenIn,
		address _tokenOut,
		uint256 amount
	) private returns (uint256) {
		address[] memory path = getPathFromTokenToToken(_tokenIn, _tokenOut);
		uint256[] memory amounts = IUniswapRouter(uniswapRouter).swapExactTokensForTokens(amount, 0, path, address(this), deadline);
		return amounts[path.length - 1];
	}

	function _swapETHForToken(address _tokenOut) private returns (uint256) {
		address[] memory path = getPathFromTokenToToken(WETH, _tokenOut);
		uint256[] memory amounts = IUniswapRouter(uniswapRouter).swapExactETHForTokens{ value: msg.value }(0, path, address(this), deadline); // amounts[0] = WETH, amounts[1] = DAI
		return amounts[path.length - 1];
	}

	function _swapTokenForETH(address _tokenIn, uint256 amount) private returns (uint256) {
		address[] memory path = getPathFromTokenToToken(_tokenIn, WETH);
		uint256[] memory amounts = IUniswapRouter(uniswapRouter).swapExactTokensForETH(amount, 0, path, address(this), deadline);
		return amounts[path.length - 1];
	}

	function listOnMarket(
		uint256 tokenId,
		uint256 amount,
		uint256 price,
		uint256 creatorFee,
		address paymentToken,
		address nftCreator
	) external whenNotPaused() onlyOwner() {
		require(amount > 0, 'Invalid-amount');
		require(price > 0, 'Invalid-price');
		Order memory newOrder;
		newOrder.orderOwner = msg.sender;
		newOrder.tokenId = tokenId;
		newOrder.nftCreator = nftCreator;
		newOrder.creatorFee = creatorFee;
		newOrder.amount = amount;
		newOrder.pricePerToken = price;
		newOrder.paymentToken = paymentToken;
		orders[totalOrder] = newOrder;
		emit NewNFTListing(totalOrder, msg.sender, paymentToken, tokenId, amount, price);
		_incrementOrderId();
	}

	function buy(
		uint256 orderId,
		uint256 amount,
		address paymentToken
	) external payable whenNotPaused() nonReentrant() {
		require(amount > 0, 'Invalid-amount');
		require(isWhiteListPaymentMethod[paymentToken], 'Invalid-payment-method');
		Order memory order = orders[orderId];
		require(amount <= order.amount, 'Invalid-amount');
		uint256 orderAmount = order.pricePerToken.mul(amount);
		uint256 amountToCreator;
		if (order.creatorFee > 0 && order.nftCreator != address(0)) {
			amountToCreator = orderAmount.mul(order.creatorFee).div(10000);
		}
		uint256 amountToTreasury = orderAmount.sub(amountToCreator);
		if (paymentToken == order.paymentToken && paymentToken == address(0)) {
			// paid in ETH
			require(msg.value >= orderAmount);
			if (amountToCreator > 0) {
				payable(order.nftCreator).sendValue(amountToCreator);
			}
			payable(eddaTreasury).sendValue(amountToTreasury);
		} else if (paymentToken == order.paymentToken && paymentToken != address(0)) {
			if (amountToCreator > 0) {
				IERC20(paymentToken).safeTransferFrom(msg.sender, order.nftCreator, amountToCreator);
			}
			IERC20(paymentToken).safeTransferFrom(msg.sender, eddaTreasury, amountToTreasury);
		} else if (paymentToken != order.paymentToken && paymentToken == address(0)) {
			// pay in ETH while order payment in ERC20
			uint256 amountTokenSwap = _swapETHForToken(order.paymentToken);
			require(amountTokenSwap >= orderAmount, 'Invalid-amount-payment');
			if (amountToCreator > 0) {
				IERC20(order.paymentToken).safeTransfer(order.nftCreator, amountToCreator);
			}
			IERC20(order.paymentToken).safeTransfer(eddaTreasury, amountToTreasury);
		} else {
			uint256 paymentAmount;
			uint256 amountTokenSwap;
			if (order.paymentToken == address(0)) {
				paymentAmount = estimateSwapAmount(paymentToken, WETH, orderAmount);
				IERC20(paymentToken).safeTransferFrom(msg.sender, address(this), paymentAmount);
				amountTokenSwap = _swapTokenForETH(paymentToken, paymentAmount);
			} else {
				paymentAmount = estimateSwapAmount(paymentToken, order.paymentToken, orderAmount);
				IERC20(paymentToken).safeTransferFrom(msg.sender, address(this), paymentAmount);
				amountTokenSwap = _swapTokenForToken(paymentToken, order.paymentToken, paymentAmount);
			}
			require(amountTokenSwap >= orderAmount, 'Invalid-amount-payment');
			if (order.paymentToken == address(0)) {
				if (amountToCreator > 0) {
					payable(order.nftCreator).sendValue(amountToCreator);
				}
				payable(eddaTreasury).sendValue(amountToTreasury);
			} else {
				if (amountToCreator > 0) {
					IERC20(order.paymentToken).safeTransfer(order.nftCreator, amountToCreator);
				}
				IERC20(order.paymentToken).safeTransfer(eddaTreasury, amountToTreasury);
			}
		}
		eddaNFT.mint(msg.sender, order.tokenId, amount, '');
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

	receive() external payable {}
}
