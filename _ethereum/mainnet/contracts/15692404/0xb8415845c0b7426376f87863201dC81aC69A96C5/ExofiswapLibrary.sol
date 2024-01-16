// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20Metadata.sol";
import "./MathUInt256.sol";
import "./IExofiswapPair.sol";

library ExofiswapLibrary
{
	function safeTransferETH(address to, uint256 value) internal
	{
		// solhint-disable-next-line avoid-low-level-calls
		(bool success, ) = to.call{value: value}(new bytes(0));
		require(success, "ER: ETH transfer failed");
	}

	// performs chained getAmountIn calculations on any number of pairs
	function getAmountsIn(IExofiswapFactory factory, uint256 amountOut, IERC20Metadata[] memory path)
	internal view returns (uint256[] memory amounts)
	{
		// can not underflow since path.length >= 2;
		uint256 j = path.length;
		require(j >= 2, "EL: INVALID_PATH");
		amounts = new uint256[](j);
		j = MathUInt256.unsafeDec(j);
		amounts[j] = amountOut;
		for (uint256 i = j; i > 0; i = j)
		{
			j = MathUInt256.unsafeDec(j);
			(uint256 reserveIn, uint256 reserveOut) = getReserves(factory, path[j], path[i]);
			amounts[j] = getAmountIn(amounts[i], reserveIn, reserveOut);
		}
	}

	// performs chained getAmountOut calculations on any number of pairs
	function getAmountsOut(IExofiswapFactory factory, uint256 amountIn, IERC20Metadata[] memory path)
	internal view returns (uint256[] memory amounts)
	{
		require(path.length >= 2, "EL: INVALID_PATH");
		amounts = new uint256[](path.length);
		amounts[0] = amountIn;
		// can not underflow since path.length >= 2;
		uint256 to = MathUInt256.unsafeDec(path.length);
		uint256 j;
		for (uint256 i; i < to; i = j)
		{
			j = MathUInt256.unsafeInc(i);
			(uint256 reserveIn, uint256 reserveOut) = getReserves(factory, path[i], path[j]);
			amounts[j] = getAmountOut(amounts[i], reserveIn, reserveOut);
		}
	}

	function getReserves(IExofiswapFactory factory, IERC20Metadata token0, IERC20Metadata token1) internal view returns (uint256, uint256)
	{
		(IERC20Metadata tokenL,) = sortTokens(token0, token1);
		(uint reserve0, uint reserve1,) = pairFor(factory, token0, token1).getReserves();
		return tokenL == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
	}

	// calculates the CREATE2 address. It uses the factory for this since Factory already has the Pair contract included.
	// Otherwise this library would add the size of the Pair Contract to every contract using this function.
	function pairFor(IExofiswapFactory factory, IERC20Metadata token0, IERC20Metadata token1) internal pure returns (IExofiswapPair) {
		
		(IERC20Metadata tokenL, IERC20Metadata tokenR) = token0 < token1 ? (token0, token1) : (token1, token0);
		return IExofiswapPair(address(uint160(uint256(keccak256(abi.encodePacked(
				hex'ff', // CREATE2
				address(factory), // sender
				keccak256(abi.encodePacked(tokenL, tokenR)), // salt
				hex'2b030e03595718f09be5b952e8e9e44159b3fcf385422d5db25485106f124f44' // init code hash keccak256(type(ExofiswapPair).creationCode);
			))))));
	}

	// given an output amount of an asset and pair reserves, returns a required input amount of the other asset
	function getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut) internal pure returns (uint amountIn)
	{
		require(amountOut > 0, "EL: INSUFFICIENT_OUTPUT_AMOUNT");
		require(reserveIn > 0 && reserveOut > 0, "EL: INSUFFICIENT_LIQUIDITY");
		uint256 numerator = reserveIn * amountOut * 1000;
		uint256 denominator = (reserveOut - amountOut) * 997;
		// Div of uint can not overflow
		// numerator is calulated in a way that if no overflow happens it is impossible to be type(uint256).max.
		// The most simple explanation is that * 1000 is a multiplikation with an even number so the result hast to be even to.
		// since type(uint256).max is uneven the result has to be smaler than type(uint256).max or an overflow would have occured.
		return MathUInt256.unsafeInc(MathUInt256.unsafeDiv(numerator, denominator));
	}

	function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) internal pure returns (uint256)
	{
		require(amountIn > 0, "EL: INSUFFICIENT_INPUT_AMOUNT");
		require(reserveIn > 0, "EL: INSUFFICIENT_LIQUIDITY");
		require(reserveOut > 0, "EL: INSUFFICIENT_LIQUIDITY");
		uint256 amountInWithFee = amountIn * 997;
		uint256 numerator = amountInWithFee * reserveOut;
		uint256 denominator = (reserveIn * 1000) + amountInWithFee;
		// Div of uint can not overflow
		return MathUInt256.unsafeDiv(numerator, denominator);
	}

	// given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
	function quote(uint256 amount, uint256 reserve0, uint256 reserve1) internal pure returns (uint256) {
		require(amount > 0, "EL: INSUFFICIENT_AMOUNT");
		require(reserve0 > 0, "EL: INSUFFICIENT_LIQUIDITY");
		require(reserve1 > 0, "EL: INSUFFICIENT_LIQUIDITY");
		// Division with uint can not overflow.
		return MathUInt256.unsafeDiv(amount * reserve1, reserve0);
	}

	// returns sorted token addresses, used to handle return values from pairs sorted in this order
	function sortTokens(IERC20Metadata token0, IERC20Metadata token1) internal pure returns (IERC20Metadata tokenL, IERC20Metadata tokenR)
	{
		require(token0 != token1, "EL: IDENTICAL_ADDRESSES");
		(tokenL, tokenR) = token0 < token1 ? (token0, token1) : (token1, token0);
		require(address(tokenL) != address(0), "EL: ZERO_ADDRESS");
	}
}