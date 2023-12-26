// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./PaymentSplitter.sol";
import "./Address.sol";
import "./IERC20.sol";
import "./IUniswapV2Router02.sol";
import "./IReceiver.sol";

contract FeesReceiver is Ownable, PaymentSplitter, IReceiver {
	IERC20 public immutable TOKEN;
	address public immutable WETH;
	IUniswapV2Router02 public immutable ROUTER;

	uint public minAmount;
	uint public maxAmount;

	address[] public receivers;
	mapping(address => uint) public receiverToShare;
	uint internal constant PRECISION = 10000;

	constructor(
		address _token,
		address _weth,
		address _router,
		address[] memory _payees, 
		uint256[] memory _shares
	) 
		PaymentSplitter(_payees, _shares)
	{
		TOKEN = IERC20(_token);
		WETH = _weth;
		ROUTER = IUniswapV2Router02(_router);

		TOKEN.approve(_router, type(uint).max);
	}

	function distribute(uint) external {
		uint balance = TOKEN.balanceOf(address(this));
		uint maxAmountCached = maxAmount;
		uint amount = balance > maxAmountCached ? maxAmountCached : balance;
		if (amount < minAmount) return;
		amount -= 1; // non zero

		address[] memory path = new address[](2);
		path[0] = address(TOKEN);
		path[1] = WETH;

		ROUTER.swapExactTokensForETHSupportingFeeOnTransferTokens(
			amount,
			0,
			path,
			address(this),
			block.timestamp
		);
	}

	function setMinAmount(uint _minAmount) external onlyOwner {
		assert(_minAmount > 1);
		minAmount = _minAmount;
	}

	function setMaxAmount(uint _maxAmount) external onlyOwner {
		maxAmount = _maxAmount;
	}

	function release(IERC20 token, address account) public override {
		assert(token != TOKEN);
		super.release(token, account);
	}
}
