// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Address.sol";
import "./IERC20.sol";
import "./IUniswapV2Router02.sol";
import "./IReceiver.sol";
import "./console.sol";

contract FeesReceiver is Ownable, IReceiver {
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
		address _router
	) {
		TOKEN = IERC20(_token);
		WETH = _weth;
		ROUTER = IUniswapV2Router02(_router);

		TOKEN.approve(_router, type(uint).max);
	}

	receive() external payable {}

	function distribute(uint) external {
		uint balance = TOKEN.balanceOf(address(this));
		uint amount = balance > maxAmount ? maxAmount : balance;
		if (amount < minAmount) return;

		address[] memory path = new address[](2);
		path[0] = address(TOKEN);
		path[1] = WETH;
		uint[] memory amounts = ROUTER.getAmountsOut(amount, path);
    	uint amountOutMin = amounts[1] * 90 / 100;
		console.log(amountOutMin, amount);
		ROUTER.swapExactTokensForETHSupportingFeeOnTransferTokens(
			amount,
			amountOutMin,
			path,
			address(this),
			block.timestamp
		);

		uint ethBalance = address(this).balance;
		console.log(ethBalance);
		address[] memory receiversCached = receivers;
		for (uint i = 0; i < receiversCached.length; ++i) {
			address receiver = receiversCached[i];
			uint amountReceiver = ethBalance * receiverToShare[receiver] / PRECISION;
			console.log(amountReceiver);
			if (amountReceiver > 0) Address.sendValue(payable(receiver), amountReceiver);
		}
	}

	function setReceiversAndShares(address[] calldata _receivers, uint[] calldata _shares) external onlyOwner {
		require(_receivers.length == _shares.length, "length discrepency");

		address[] memory receiversCached = receivers;
		for (uint i; i < receiversCached.length; ++i) {
			receiverToShare[receiversCached[i]] = 0;
		}

		uint sumShares;
		for (uint i; i < _receivers.length; ++i) {
			receiverToShare[_receivers[i]] = _shares[i];
			sumShares += _shares[i];
		}
		require(sumShares == PRECISION, "sum discrepency");

		receivers = _receivers;
	}
	
	function setMinAmount(uint _minAmount) external onlyOwner {
		minAmount = _minAmount;
	}

	function setMaxAmount(uint _maxAmount) external onlyOwner {
		maxAmount = _maxAmount;
	}
}
