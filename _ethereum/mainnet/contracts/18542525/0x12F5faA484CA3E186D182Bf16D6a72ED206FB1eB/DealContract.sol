// SPDX-License-Identifier: MIT
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";

pragma solidity ^0.8.7;

interface IUniswapV2Router02 {
	function getAmountsOut(
		uint amountIn,
		address[] memory path
	) external view returns (uint[] memory amounts);

	function WETH() external view returns (address);
}

contract DealContract is Ownable, ReentrancyGuard {
	using SafeERC20 for IERC20;
	using SafeMath for uint256;

	struct DealInfo {
		address creator;
		address partner;
		address sellToken;
		address buyToken;
		uint256 sellAmount;
		uint256 buyAmount;
		uint256 createTime;
		uint256 feeAmount;
		uint256 status; //0: Not created, 1: Opened, 2: Pending, 3: Approved, 4: Cancelled
	}

	mapping(bytes32 => DealInfo) public g_deals;
	mapping(address => uint256) public g_dealCounts;
	mapping(address => mapping(uint256 => bytes32)) public g_dealsForWallet;
	IERC20 public g_feeToken;
	uint256 public g_defaultFeeAmount;
	uint256 public g_dealDuration;
	uint256 public g_feePercentage;

	IERC20 public USDT = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
	IUniswapV2Router02 public SwapRouter =
		IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

	event CreateDeal(address _creator, bytes32 _id);
	event DepositForDeal(address _partner, bytes32 _id);

	constructor(address _feeToken) {
		g_feeToken = IERC20(_feeToken);
		g_dealDuration = 7200; //2 hrs
		g_defaultFeeAmount = 5 * (10 ** 6);
		g_feePercentage = 100;
	}

	function setSwapRouter(address _swapRouter) external onlyOwner {
		SwapRouter = IUniswapV2Router02(_swapRouter);
	}

	function setFeePercentage(uint256 _feePercentage) external onlyOwner {
		g_feePercentage = _feePercentage;
	}

	function setUSDT(IERC20 _usdtAddress) external onlyOwner {
		USDT = _usdtAddress;
	}

	function setFeeToken(address _tokenAddress) external onlyOwner {
		g_feeToken = IERC20(_tokenAddress);
	}

	function setFeeAmount(uint256 _tokenAmount) external onlyOwner {
		g_defaultFeeAmount = _tokenAmount;
	}

	function withdrawFee() external onlyOwner {
		uint256 m_balance = g_feeToken.balanceOf(address(this));
		g_feeToken.safeTransfer(msg.sender, m_balance);
	}

	function setDealDuration(uint256 _hours) external onlyOwner {
		g_dealDuration = 60 * 60 * _hours;
	}

	function getDealCounts(address _user) external view returns (uint256 _count) {
		return g_dealCounts[_user];
	}

	function getFeeAmount() public view returns (uint256) {
		if (g_defaultFeeAmount == 0) return 0;

		address[] memory path = new address[](3);
		path[0] = address(USDT);
		path[1] = SwapRouter.WETH();
		path[2] = address(g_feeToken);

		uint256[] memory amounts = SwapRouter.getAmountsOut(g_defaultFeeAmount, path);

		return amounts[2];
	}

	function createDeal(
		address _partner,
		address _sellToken,
		address _buyToken,
		uint256 _sellAmount,
		uint256 _buyAmount
	) external payable {
		bytes32 m_dealId = keccak256(abi.encodePacked(msg.sender, _partner, block.timestamp));

		uint256 fee = getFeeAmount();

		require(g_feeToken.balanceOf(msg.sender) >= fee, "Not enough Fee");

		if (_sellToken != SwapRouter.WETH()) {
			require(
				IERC20(_sellToken).balanceOf(msg.sender) >= _sellAmount,
				"Not enough tokens for selling!"
			);
			IERC20(_sellToken).safeTransferFrom(msg.sender, address(this), _sellAmount);
		} else {
			require(address(msg.sender).balance >= _sellAmount, "Not enough tokens for selling!");
			require(msg.value == _sellAmount, "Not enought tokens for selling!");
		}
		if (fee > 0) {
			g_feeToken.safeTransferFrom(msg.sender, address(this), fee);
		}

		DealInfo storage m_deal = g_deals[m_dealId];
		m_deal.creator = msg.sender;
		m_deal.partner = _partner;
		m_deal.sellToken = _sellToken;
		m_deal.buyToken = _buyToken;
		m_deal.sellAmount = _sellAmount;
		m_deal.buyAmount = _buyAmount;
		m_deal.createTime = block.timestamp;
		m_deal.feeAmount = fee;
		m_deal.status = 1; //Deal is Opened

		uint256 counts = g_dealCounts[msg.sender];
		g_dealsForWallet[msg.sender][counts] = m_dealId;
		g_dealCounts[msg.sender] = counts + 1;

		emit CreateDeal(msg.sender, m_dealId);
	}

	function depositForDeal(bytes32 _dealId) external payable {
		DealInfo storage m_deal = g_deals[_dealId];

		require(msg.sender == m_deal.partner, "You are not a part of this deal");
		require(m_deal.status == 1, "This deal is not created!");

		m_deal.status = 2; //Deal is Pending

		if (m_deal.buyToken != SwapRouter.WETH()) {
			require(
				IERC20(m_deal.buyToken).balanceOf(msg.sender) > m_deal.buyAmount,
				"Not enough tokens for exchange!"
			);
			IERC20(m_deal.buyToken).safeTransferFrom(msg.sender, address(this), m_deal.buyAmount);
		} else {
			require(address(msg.sender).balance > m_deal.buyAmount, "Not enough tokens for exchange!");
			require(msg.value == m_deal.buyAmount, "Not enough tokens for exchange!");
		}

		uint256 counts = g_dealCounts[msg.sender];
		g_dealsForWallet[msg.sender][counts] = _dealId;
		g_dealCounts[msg.sender] = counts + 1;

		emit DepositForDeal(msg.sender, _dealId);
	}

	function approveDeal(bytes32 _dealId) external nonReentrant {
		DealInfo storage m_deal = g_deals[_dealId];

		require(msg.sender == m_deal.creator, "You are not a part of this deal");
		require(m_deal.status == 2, "This deal is started yet!");

		m_deal.status = 3; //Deal is approved

		if (m_deal.sellToken != SwapRouter.WETH()) {
			IERC20(m_deal.sellToken).safeTransfer(m_deal.partner, m_deal.sellAmount);
		} else {
			payable(m_deal.partner).transfer(m_deal.sellAmount);
		}

		if (m_deal.buyToken != SwapRouter.WETH()) {
			IERC20(m_deal.buyToken).safeTransfer(m_deal.creator, m_deal.buyAmount);
		} else {
			payable(m_deal.creator).transfer(m_deal.buyAmount);
		}
	}

	function emergencyWithdraw(bytes32 _dealId) external nonReentrant {
		DealInfo storage m_deal = g_deals[_dealId];
		require(
			msg.sender == m_deal.creator || msg.sender == m_deal.partner,
			"You are not a part of this deal!"
		);
		require(block.timestamp > m_deal.createTime + g_dealDuration, "Time is not limited yet!");

		m_deal.status = 4; //Deal is Cancelled!

		if (m_deal.sellToken != SwapRouter.WETH()) {
			IERC20(m_deal.sellToken).safeTransfer(m_deal.creator, m_deal.sellAmount);
		} else {
			payable(m_deal.creator).transfer(m_deal.sellAmount);
		}

		if (m_deal.buyToken != SwapRouter.WETH()) {
			IERC20(m_deal.buyToken).safeTransfer(m_deal.partner, m_deal.buyAmount);
		} else {
			payable(m_deal.partner).transfer(m_deal.buyAmount);
		}

		if (m_deal.feeAmount > 0) g_feeToken.safeTransfer(m_deal.creator, m_deal.feeAmount);
	}

	function withdrawStuckedToken(address _tokenAddress, uint256 _amount) external onlyOwner {
		IERC20(_tokenAddress).transfer(msg.sender, _amount);
	}

	function withdrawStuckedEth(uint256 _amount) external onlyOwner {
		payable(msg.sender).transfer(_amount);
	}

	receive() external payable {}
}
