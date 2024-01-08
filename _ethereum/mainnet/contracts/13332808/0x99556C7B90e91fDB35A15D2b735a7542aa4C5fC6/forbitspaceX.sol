// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;
pragma abicoder v2;

import "./Payment.sol";

struct SwapParam {
	address target;
	bytes swapData;
}

contract forbitspaceX is Payment {
	using SafeMath for uint;
	using Address for address;

	constructor(address _WETH) Payment(_WETH) {}

	function _swap(
		address tokenIn,
		address tokenOut,
		uint amountInTotal,
		SwapParam[] memory params
	)
		private
		returns (
			uint[2][] memory retAmounts,
			uint amountInLeft,
			uint amountOutTotal
		)
	{
		if (tokenIn == address(0)) tokenIn = WETH_;
		if (tokenOut == address(0)) tokenOut = WETH_;
		amountInLeft = amountInTotal;
		retAmounts = new uint[2][](params.length);
		for (uint i = 0; i < params.length; i++) {
			SwapParam memory param = params[i];
			uint amountIn = balanceOf(tokenIn); // amountIn before
			uint amountOut = balanceOf(tokenOut); // amountOut before
			param.target.functionCall(param.swapData, 'C_S_F'); // call swap failed
			amountIn = amountIn.sub(balanceOf(tokenIn)); // amountIn after
			amountOut = balanceOf(tokenOut).sub(amountOut); // amountOut after
			amountInLeft = amountInLeft.sub(amountIn.mul(2000).div(1999), 'N_E_T'); // not enough tokens with 0.05% fee
			amountOutTotal = amountOutTotal.add(amountOut);
			retAmounts[i] = [amountIn, amountOut];
		}
	}

	function aggregate(
		address tokenIn,
		address tokenOut,
		uint amountInTotal,
		SwapParam[] memory params
	)
		public
		payable
		returns (
			uint[2][] memory retAmounts,
			uint amountInLeft,
			uint amountOutTotal
		)
	{
		require(tokenIn != tokenOut, 'I_T_A'); // invalid tokens address
		require(!(tokenIn == address(0) && tokenOut == WETH_));
		require(!(tokenIn == WETH_ && tokenOut == address(0)));

		if (tokenIn == address(0)) require((amountInTotal = msg.value) > 0);
		else require(msg.value == 0);

		pay(tokenIn, amountInTotal);
		uint amountETH = address(this).balance;
		(retAmounts, amountInLeft, amountOutTotal) = _swap(tokenIn, tokenOut, amountInTotal, params);
		amountETH = address(this).balance.sub(amountETH);
		refund(tokenIn, amountInLeft);
		refund(tokenOut, amountOutTotal);
		collectTokens(tokenIn);
	}
}
