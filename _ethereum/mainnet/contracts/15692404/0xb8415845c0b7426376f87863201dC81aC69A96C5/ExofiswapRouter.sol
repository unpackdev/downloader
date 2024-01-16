// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20Metadata.sol";
import "./SafeERC20.sol";
import "./Context.sol";
import "./ExofiswapLibrary.sol";
import "./MathUInt256.sol";
import "./IExofiswapFactory.sol";
import "./IExofiswapPair.sol";
import "./IExofiswapRouter.sol";
import "./IWETH9.sol";

contract ExofiswapRouter is IExofiswapRouter, Context
{
	IExofiswapFactory private immutable _swapFactory;
	IWETH9 private immutable _wrappedEth;

	modifier ensure(uint256 deadline) {
		require(deadline >= block.timestamp, "ER: EXPIRED"); // solhint-disable-line not-rely-on-time
		_;
	}

	constructor(IExofiswapFactory swapFactory, IWETH9 wrappedEth)
	{
		_swapFactory = swapFactory;
		_wrappedEth = wrappedEth;
	}

	receive() override external payable
	{
		assert(_msgSender() == address(_wrappedEth)); // only accept ETH via fallback from the WETH contract
	}

	function addLiquidityETH(
		IERC20Metadata token,
		uint256 amountTokenDesired,
		uint256 amountTokenMin,
		uint256 amountETHMin,
		address to,
		uint256 deadline
	) override external virtual payable ensure(deadline) returns (uint256 amountToken, uint256 amountETH, uint256 liquidity)
	{
		IExofiswapPair pair;
		(amountToken, amountETH, pair) = _addLiquidity(
			token,
			_wrappedEth,
			amountTokenDesired,
			msg.value,
			amountTokenMin,
			amountETHMin
		);
		SafeERC20.safeTransferFrom(token, _msgSender(), address(pair), amountToken);
		_wrappedEth.deposit{value: amountETH}();
		assert(_wrappedEth.transfer(address(pair), amountETH));
		liquidity = pair.mint(to);
		// refund dust eth, if any
		if (msg.value > amountETH) ExofiswapLibrary.safeTransferETH(_msgSender(), MathUInt256.unsafeSub(msg.value, amountETH));
	}

	function addLiquidity(
		IERC20Metadata tokenA,
		IERC20Metadata tokenB,
		uint256 amountADesired,
		uint256 amountBDesired,
		uint256 amountAMin,
		uint256 amountBMin,
		address to,
		uint256 deadline
	) override external virtual ensure(deadline) returns (uint256 amountA, uint256 amountB, uint256 liquidity)
	{
		IExofiswapPair pair;
		(amountA, amountB, pair) = _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
		_safeTransferFrom(tokenA, tokenB, address(pair), amountA, amountB);
		liquidity = pair.mint(to);
	}

	function removeLiquidity(
		IERC20Metadata tokenA,
		IERC20Metadata tokenB,
		uint256 liquidity,
		uint256 amountAMin,
		uint256 amountBMin,
		address to,
		uint256 deadline
	) external virtual override ensure(deadline) returns (uint256, uint256)
	{
		IExofiswapPair pair = ExofiswapLibrary.pairFor(_swapFactory, tokenA, tokenB);
		return _removeLiquidity(pair, tokenB < tokenA, liquidity, amountAMin, amountBMin, to);
	}

	function removeLiquidityETH(
		IERC20Metadata token,
		uint256 liquidity,
		uint256 amountTokenMin,
		uint256 amountETHMin,
		address to,
		uint256 deadline
	) external override virtual ensure(deadline) returns (uint256 amountToken, uint256 amountETH)
	{
		IExofiswapPair pair = ExofiswapLibrary.pairFor(_swapFactory, token, _wrappedEth);
		(amountToken, amountETH) = _removeLiquidity(pair, _wrappedEth < token, liquidity, amountTokenMin, amountETHMin, address(this));
		SafeERC20.safeTransfer(token, to, amountToken);
		_wrappedEth.withdraw(amountETH);
		ExofiswapLibrary.safeTransferETH(to, amountETH);
	}

	function removeLiquidityETHSupportingFeeOnTransferTokens(
		IERC20Metadata token,
		uint256 liquidity,
		uint256 amountTokenMin,
		uint256 amountETHMin,
		address to,
		uint256 deadline
	) override external virtual ensure(deadline) returns (uint256 amountETH)
	{
		IExofiswapPair pair = ExofiswapLibrary.pairFor(_swapFactory, token, _wrappedEth);
		(, amountETH) = _removeLiquidity(pair, _wrappedEth < token, liquidity, amountTokenMin, amountETHMin, address(this));
		SafeERC20.safeTransfer(token, to, token.balanceOf(address(this)));
		_wrappedEth.withdraw(amountETH);
		ExofiswapLibrary.safeTransferETH(to, amountETH);
	}

	function removeLiquidityETHWithPermit(
		IERC20Metadata token,
		uint256 liquidity,
		uint256 amountTokenMin,
		uint256 amountETHMin,
		address to,
		uint256 deadline,
		bool approveMax, uint8 v, bytes32 r, bytes32 s
	) external override virtual returns (uint256 amountToken, uint256 amountETH)
	{
		IExofiswapPair pair = ExofiswapLibrary.pairFor(_swapFactory, token, _wrappedEth);
		{
			uint256 value = approveMax ? type(uint256).max : liquidity;
			pair.permit(_msgSender(), address(this), value, deadline, v, r, s); // ensure(deadline) happens here
		}
		(amountToken, amountETH) = _removeLiquidity(pair, _wrappedEth < token, liquidity, amountTokenMin, amountETHMin, address(this));
		SafeERC20.safeTransfer(token, to, amountToken);
		_wrappedEth.withdraw(amountETH);
		ExofiswapLibrary.safeTransferETH(to, amountETH);
	}

	function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
		IERC20Metadata token,
		uint256 liquidity,
		uint256 amountTokenMin,
		uint256 amountETHMin,
		address to,
		uint256 deadline,
		bool approveMax,
		uint8 v,
		bytes32 r,
		bytes32 s
	) override external virtual returns (uint256 amountETH)
	{
		{
			IExofiswapPair pair = ExofiswapLibrary.pairFor(_swapFactory, token, _wrappedEth);
			uint256 value = approveMax ? type(uint256).max : liquidity;
			pair.permit(_msgSender(), address(this), value, deadline, v, r, s); // ensure(deadline) happens here
			(, amountETH) = _removeLiquidity(pair, _wrappedEth < token, liquidity, amountTokenMin, amountETHMin, address(this));
		}
		SafeERC20.safeTransfer(token, to, token.balanceOf(address(this)));
		_wrappedEth.withdraw(amountETH);
		ExofiswapLibrary.safeTransferETH(to, amountETH);
	}

	function removeLiquidityWithPermit(
		IERC20Metadata tokenA,
		IERC20Metadata tokenB,
		uint256 liquidity,
		uint256 amountAMin,
		uint256 amountBMin,
		address to,
		uint256 deadline,
		bool approveMax, uint8 v, bytes32 r, bytes32 s
	) external override virtual returns (uint256 amountA, uint256 amountB)
	{
		IExofiswapPair pair = ExofiswapLibrary.pairFor(_swapFactory, tokenA, tokenB);
		{
			uint256 value = approveMax ? type(uint256).max : liquidity;
			pair.permit(_msgSender(), address(this), value, deadline, v, r, s); // ensure(deadline) happens here
		}
		(amountA, amountB) = _removeLiquidity(pair, tokenB < tokenA, liquidity, amountAMin, amountBMin, to);
	}

	function swapExactTokensForETH(uint256 amountIn, uint256 amountOutMin, IERC20Metadata[] calldata path, address to, uint256 deadline)
		override external virtual ensure(deadline) returns (uint256[] memory amounts)
	{
		uint256 lastItem = MathUInt256.unsafeDec(path.length);
		require(path[lastItem] == _wrappedEth, "ER: INVALID_PATH"); // Overflow on lastItem will flail here to
		amounts = ExofiswapLibrary.getAmountsOut(_swapFactory, amountIn, path);
		require(amounts[amounts.length - 1] >= amountOutMin, "ER: INSUFFICIENT_OUTPUT_AMOUNT");
		SafeERC20.safeTransferFrom(path[0], _msgSender(), address(ExofiswapLibrary.pairFor(_swapFactory, path[0], path[1])), amounts[0]);
		_swap(amounts, path, address(this));
		// Lenght of amounts array must be equal to length of path array.
		_wrappedEth.withdraw(amounts[lastItem]);
		ExofiswapLibrary.safeTransferETH(to, amounts[lastItem]);
	}

	function swapExactTokensForETHSupportingFeeOnTransferTokens(
		uint256 amountIn,
		uint256 amountOutMin,
		IERC20Metadata[] calldata path,
		address to,
		uint256 deadline
	) override external virtual ensure(deadline)
	{
		require(path[MathUInt256.unsafeDec(path.length)] == _wrappedEth, "ER: INVALID_PATH");
		SafeERC20.safeTransferFrom(path[0], _msgSender(), address(ExofiswapLibrary.pairFor(_swapFactory, path[0], path[1])), amountIn);
		_swapSupportingFeeOnTransferTokens(path, address(this));
		uint256 amountOut = _wrappedEth.balanceOf(address(this));
		require(amountOut >= amountOutMin, "ER: INSUFFICIENT_OUTPUT_AMOUNT");
		_wrappedEth.withdraw(amountOut);
		ExofiswapLibrary.safeTransferETH(to, amountOut);
	}

	function swapExactTokensForTokens(
		uint256 amountIn,
		uint256 amountOutMin,
		IERC20Metadata[] calldata path,
		address to,
		uint256 deadline
	) external override virtual ensure(deadline) returns (uint256[] memory amounts)
	{
		amounts = ExofiswapLibrary.getAmountsOut(_swapFactory, amountIn, path);
		require(amounts[MathUInt256.unsafeDec(amounts.length)] >= amountOutMin, "ER: INSUFFICIENT_OUTPUT_AMOUNT");
		SafeERC20.safeTransferFrom(path[0], _msgSender(), address(ExofiswapLibrary.pairFor(_swapFactory, path[0], path[1])), amounts[0]);
		_swap(amounts, path, to);
	}

	function swapExactTokensForTokensSupportingFeeOnTransferTokens(
		uint256 amountIn,
		uint256 amountOutMin,
		IERC20Metadata[] calldata path,
		address to,
		uint256 deadline
	) override external virtual ensure(deadline)
	{
		SafeERC20.safeTransferFrom(path[0], _msgSender(), address(ExofiswapLibrary.pairFor(_swapFactory, path[0], path[1])), amountIn);
		uint256 lastItem = MathUInt256.unsafeDec(path.length);
		uint256 balanceBefore = path[lastItem].balanceOf(to);
		_swapSupportingFeeOnTransferTokens(path, to);
		require((path[lastItem].balanceOf(to) - balanceBefore) >= amountOutMin, "ER: INSUFFICIENT_OUTPUT_AMOUNT");
	}

	function swapTokensForExactETH(uint256 amountOut, uint256 amountInMax, IERC20Metadata[] calldata path, address to, uint256 deadline) override
		external virtual ensure(deadline) returns (uint256[] memory amounts)
	{
		uint256 lastItem = MathUInt256.unsafeDec(path.length);
		require(path[lastItem] == _wrappedEth, "ER: INVALID_PATH"); // Overflow on lastItem will fail here too
		amounts = ExofiswapLibrary.getAmountsIn(_swapFactory, amountOut, path);
		require(amounts[0] <= amountInMax, "ER: EXCESSIVE_INPUT_AMOUNT");
		SafeERC20.safeTransferFrom(
			path[0], _msgSender(), address(ExofiswapLibrary.pairFor(_swapFactory, path[0], path[1])), amounts[0]
		);
		_swap(amounts, path, address(this));
		// amounts and path must have the same item count...
		_wrappedEth.withdraw(amounts[lastItem]);
		ExofiswapLibrary.safeTransferETH(to, amounts[lastItem]);
	}

	function swapTokensForExactTokens(
		uint256 amountOut,
		uint256 amountInMax,
		IERC20Metadata[] calldata path,
		address to,
		uint256 deadline
	) external override virtual ensure(deadline) returns (uint256[] memory amounts)
	{
		amounts = ExofiswapLibrary.getAmountsIn(_swapFactory, amountOut, path);
		require(amounts[0] <= amountInMax, "ER: EXCESSIVE_INPUT_AMOUNT");
		SafeERC20.safeTransferFrom(
			path[0], _msgSender(), address(ExofiswapLibrary.pairFor(_swapFactory, path[0], path[1])), amounts[0]
		);
		_swap(amounts, path, to);
	}

	function swapETHForExactTokens(uint256 amountOut, IERC20Metadata[] calldata path, address to, uint256 deadline)
		override external virtual payable ensure(deadline) returns (uint256[] memory amounts)
	{
		require(path[0] == _wrappedEth, "ER: INVALID_PATH");
		amounts = ExofiswapLibrary.getAmountsIn(_swapFactory, amountOut, path);
		require(amounts[0] <= msg.value, "ER: EXCESSIVE_INPUT_AMOUNT");
		_wrappedEth.deposit{value: amounts[0]}();
		assert(_wrappedEth.transfer(address(ExofiswapLibrary.pairFor(_swapFactory, path[0], path[1])), amounts[0]));
		_swap(amounts, path, to);
		// refund dust eth, if any
		if (msg.value > amounts[0]) ExofiswapLibrary.safeTransferETH(_msgSender(), msg.value - amounts[0]);
	}

	function swapExactETHForTokens(uint256 amountOutMin, IERC20Metadata[] calldata path, address to, uint256 deadline)
		override external virtual payable ensure(deadline) returns (uint[] memory amounts)
	{
		require(path[0] == _wrappedEth, "ER: INVALID_PATH");
		amounts = ExofiswapLibrary.getAmountsOut(_swapFactory, msg.value, path);
		require(amounts[MathUInt256.unsafeDec(amounts.length)] >= amountOutMin, "ER: INSUFFICIENT_OUTPUT_AMOUNT");
		_wrappedEth.deposit{value: amounts[0]}();
		assert(_wrappedEth.transfer(address(ExofiswapLibrary.pairFor(_swapFactory, path[0], path[1])), amounts[0]));
		_swap(amounts, path, to);
	}

	function swapExactETHForTokensSupportingFeeOnTransferTokens(
		uint256 amountOutMin,
		IERC20Metadata[] calldata path,
		address to,
		uint256 deadline
	) override external virtual payable ensure(deadline)
	{
		require(path[0] == _wrappedEth, "ER: INVALID_PATH");
		uint256 amountIn = msg.value;
		_wrappedEth.deposit{value: amountIn}();
		assert(_wrappedEth.transfer(address(ExofiswapLibrary.pairFor(_swapFactory, path[0], path[1])), amountIn));
		uint256 lastItem = MathUInt256.unsafeDec(path.length);
		uint256 balanceBefore = path[lastItem].balanceOf(to);
		_swapSupportingFeeOnTransferTokens(path, to);
		require(path[lastItem].balanceOf(to) - balanceBefore >= amountOutMin, "ER: INSUFFICIENT_OUTPUT_AMOUNT");
	}

	function factory() override external view returns (IExofiswapFactory)
	{
		return _swapFactory;
	}

	function getAmountsIn(uint256 amountOut, IERC20Metadata[] memory path) override
		public view virtual returns (uint[] memory amounts)
	{
		return ExofiswapLibrary.getAmountsIn(_swapFactory, amountOut, path);
	}

	// solhint-disable-next-line func-name-mixedcase
	function WETH() override public view returns(IERC20Metadata)
	{
		return _wrappedEth;
	}

	function getAmountsOut(uint256 amountIn, IERC20Metadata[] memory path) override
		public view virtual returns (uint256[] memory amounts)
	{
		return ExofiswapLibrary.getAmountsOut(_swapFactory, amountIn, path);
	}

	function getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut) override
		public pure virtual returns (uint256 amountIn)
	{
		return ExofiswapLibrary.getAmountIn(amountOut, reserveIn, reserveOut);
	}

	function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) override
		public pure virtual returns (uint256)
	{
		return ExofiswapLibrary.getAmountOut(amountIn, reserveIn, reserveOut);
	}

	function quote(uint256 amount, uint256 reserve0, uint256 reserve1) override public pure virtual returns (uint256)
	{
		return ExofiswapLibrary.quote(amount, reserve0, reserve1);
	}

	function _addLiquidity(
		IERC20Metadata tokenA,
		IERC20Metadata tokenB,
		uint256 amountADesired,
		uint256 amountBDesired,
		uint256 amountAMin,
		uint256 amountBMin
	) private returns (uint256, uint256, IExofiswapPair)
	{
		// create the pair if it doesn't exist yet
		IExofiswapPair pair = _swapFactory.getPair(tokenA, tokenB);
		if (address(pair) == address(0))
		{
			pair = _swapFactory.createPair(tokenA, tokenB);
		}
		(uint256 reserveA, uint256 reserveB, ) = pair.getReserves();
		if (reserveA == 0 && reserveB == 0)
		{
			return (amountADesired, amountBDesired, pair);
		}
		if(pair.token0() == tokenB)
		{
			(reserveB, reserveA) = (reserveA, reserveB);
		}
		uint256 amountBOptimal = ExofiswapLibrary.quote(amountADesired, reserveA, reserveB);
		if (amountBOptimal <= amountBDesired)
		{
			require(amountBOptimal >= amountBMin, "ER: INSUFFICIENT_B_AMOUNT");
			return (amountADesired, amountBOptimal, pair);
		}
		uint256 amountAOptimal = ExofiswapLibrary.quote(amountBDesired, reserveB, reserveA);
		assert(amountAOptimal <= amountADesired);
		require(amountAOptimal >= amountAMin, "ER: INSUFFICIENT_A_AMOUNT");
		return (amountAOptimal, amountBDesired, pair);
	}

	function _removeLiquidity(
	IExofiswapPair pair,
	bool reverse,
	uint256 liquidity,
	uint256 amountAMin,
	uint256 amountBMin,
	address to
	) private returns (uint256 amountA, uint256 amountB)
	{
		pair.transferFrom(_msgSender(), address(pair), liquidity); // send liquidity to pair
		(amountA, amountB) = pair.burn(to);
		if(reverse)
		{
			(amountA, amountB) = (amountB, amountA);
		}
		require(amountA >= amountAMin, "ER: INSUFFICIENT_A_AMOUNT");
		require(amountB >= amountBMin, "ER: INSUFFICIENT_B_AMOUNT");
	}

	function _safeTransferFrom(IERC20Metadata tokenA, IERC20Metadata tokenB, address pair, uint256 amountA, uint256 amountB) private
	{
		address sender = _msgSender();
		SafeERC20.safeTransferFrom(tokenA, sender, pair, amountA);
		SafeERC20.safeTransferFrom(tokenB, sender, pair, amountB);
	}

	// requires the initial amount to have already been sent to the first pair
	function _swap(uint256[] memory amounts, IERC20Metadata[] memory path, address to) private
	{
		// TODO: Optimize for Gas. Still higher than Uniswap....maybe get all pairs from factory at once helps....
		uint256 pathLengthSubTwo = MathUInt256.unsafeSub(path.length, 2);
		uint256 j;
		uint256 i;
		while (i < pathLengthSubTwo)
		{
			j = MathUInt256.unsafeInc(i);
			IExofiswapPair pair = ExofiswapLibrary.pairFor(_swapFactory, path[i], path[j]);
			(uint256 amount0Out, uint256 amount1Out) = path[i] == pair.token0() ? (uint256(0), amounts[j]) : (amounts[j], uint256(0));
			pair.swap(amount0Out, amount1Out, address(ExofiswapLibrary.pairFor(_swapFactory, path[j], path[MathUInt256.unsafeInc(j)])), new bytes(0));
			i = j;
		}
		j = MathUInt256.unsafeInc(i);
		IExofiswapPair pair2 = ExofiswapLibrary.pairFor(_swapFactory, path[i], path[j]);
		(uint256 amount0Out2, uint256 amount1Out2) = path[i] == pair2.token0() ? (uint256(0), amounts[j]) : (amounts[j], uint256(0));
		pair2.swap(amount0Out2, amount1Out2, to, new bytes(0));
	}

	function _swapSupportingFeeOnTransferTokens(IERC20Metadata[] memory path, address to) private
	{
		uint256 pathLengthSubTwo = MathUInt256.unsafeSub(path.length, 2);
		uint256 j;
		uint256 i;
		while (i < pathLengthSubTwo)
		{
			j = MathUInt256.unsafeInc(i);
			IExofiswapPair pair = ExofiswapLibrary.pairFor(_swapFactory, path[i], path[j]);
			uint256 amountInput;
			uint256 amountOutput;
			IERC20Metadata token0 = pair.token0();
			{ // scope to avoid stack too deep errors
				(uint256 reserveInput, uint256 reserveOutput,) = pair.getReserves();
				if (path[j] == token0)
				{
					(reserveInput, reserveOutput) = (reserveOutput, reserveInput);
				}
				amountInput = (path[i].balanceOf(address(pair)) - reserveInput);
				amountOutput = ExofiswapLibrary.getAmountOut(amountInput, reserveInput, reserveOutput);
			}
			(uint256 amount0Out, uint256 amount1Out) = path[i] == token0 ? (uint256(0), amountOutput) : (amountOutput, uint256(0));
			address receiver = address(ExofiswapLibrary.pairFor(_swapFactory, path[j], path[MathUInt256.unsafeInc(j)]));
			pair.swap(amount0Out, amount1Out, receiver, new bytes(0));
			i = j;
		}
		j = MathUInt256.unsafeInc(i);
		IExofiswapPair pair2 = ExofiswapLibrary.pairFor(_swapFactory, path[i], path[j]);
		uint256 amountInput2;
		uint256 amountOutput2;
		IERC20Metadata token02 = pair2.token0();
		{ // scope to avoid stack too deep errors
			(uint256 reserveInput, uint256 reserveOutput,) = pair2.getReserves();
			if (path[j] == token02)
			{
				(reserveInput, reserveOutput) = (reserveOutput, reserveInput);
			}
			amountInput2 = (path[i].balanceOf(address(pair2)) - reserveInput);
			amountOutput2 = ExofiswapLibrary.getAmountOut(amountInput2, reserveInput, reserveOutput);
		}
		(uint256 amount0Out2, uint256 amount1Out2) = path[i] == token02? (uint256(0), amountOutput2) : (amountOutput2, uint256(0));
		pair2.swap(amount0Out2, amount1Out2, to, new bytes(0));
	}
}
