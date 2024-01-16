// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./IERC20Metadata.sol";
import "./IExofiswapFactory.sol";

interface IExofiswapRouter {
	receive() external payable;

	function addLiquidityETH(
		IERC20Metadata token,
		uint256 amountTokenDesired,
		uint256 amountTokenMin,
		uint256 amountETHMin,
		address to,
		uint256 deadline
	) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

	function addLiquidity(
		IERC20Metadata tokenA,
		IERC20Metadata tokenB,
		uint256 amountADesired,
		uint256 amountBDesired,
		uint256 amountAMin,
		uint256 amountBMin,
		address to,
		uint256 deadline
	) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

	function removeLiquidity(
		IERC20Metadata tokenA,
		IERC20Metadata tokenB,
		uint256 liquidity,
		uint256 amountAMin,
		uint256 amountBMin,
		address to,
		uint256 deadline
	) external returns (uint256 amountA, uint256 amountB);

	function removeLiquidityETH(
		IERC20Metadata token,
		uint256 liquidity,
		uint256 amountTokenMin,
		uint256 amountETHMin,
		address to,
		uint256 deadline
	) external returns (uint256 amountToken, uint256 amountETH);

	function removeLiquidityETHSupportingFeeOnTransferTokens(
		IERC20Metadata token,
		uint256 liquidity,
		uint256 amountTokenMin,
		uint256 amountETHMin,
		address to,
		uint256 deadline
	) external returns (uint256 amountETH);

	function removeLiquidityETHWithPermit(
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
	) external returns (uint256 amountToken, uint256 amountETH);

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
	) external returns (uint256 amountETH);

	function removeLiquidityWithPermit(
		IERC20Metadata tokenA,
		IERC20Metadata tokenB,
		uint256 liquidity,
		uint256 amountAMin,
		uint256 amountBMin,
		address to,
		uint256 deadline,
		bool approveMax,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external returns (uint256 amountA, uint256 amountB);

	function swapETHForExactTokens(
		uint256 amountOut,
		IERC20Metadata[] calldata path,
		address to,
		uint256 deadline
	) external payable returns (uint256[] memory amounts);

	function swapExactETHForTokens(
		uint256 amountOutMin,
		IERC20Metadata[] calldata path,
		address to,
		uint256 deadline
	) external payable returns (uint256[] memory amounts);

	function swapExactTokensForETH(
		uint256 amountIn,
		uint256 amountOutMin,
		IERC20Metadata[] calldata path,
		address to,
		uint256 deadline
	) external returns (uint256[] memory amounts);

	function swapExactTokensForETHSupportingFeeOnTransferTokens(
		uint256 amountIn,
		uint256 amountOutMin,
		IERC20Metadata[] calldata path,
		address to,
		uint256 deadline
	) external;

	function swapExactTokensForTokens(
		uint256 amountIn,
		uint256 amountOutMin,
		IERC20Metadata[] calldata path,
		address to,
		uint256 deadline
	) external returns (uint256[] memory amounts);

	function swapExactTokensForTokensSupportingFeeOnTransferTokens(
		uint256 amountIn,
		uint256 amountOutMin,
		IERC20Metadata[] calldata path,
		address to,
		uint256 deadline
	) external;

	function swapTokensForExactETH(
		uint256 amountOut,
		uint256 amountInMax,
		IERC20Metadata[] calldata path,
		address to,
		uint256 deadline
	) external returns (uint256[] memory amounts);

	function swapTokensForExactTokens(
		uint256 amountOut,
		uint256 amountInMax,
		IERC20Metadata[] calldata path,
		address to,
		uint256 deadline
	) external returns (uint256[] memory amounts);

	function swapExactETHForTokensSupportingFeeOnTransferTokens(
		uint256 amountOutMin,
		IERC20Metadata[] calldata path,
		address to,
		uint256 deadline
	) external payable;

		function factory() external view returns (IExofiswapFactory);

	function getAmountsIn(uint256 amountOut, IERC20Metadata[] calldata path)
		external
		view
		returns (uint256[] memory amounts);

	function WETH() external view returns (IERC20Metadata); // solhint-disable-line func-name-mixedcase

	function getAmountsOut(uint256 amountIn, IERC20Metadata[] calldata path)
		external
		view
		returns (uint256[] memory amounts);

	function getAmountOut(
		uint256 amountIn,
		uint256 reserveIn,
		uint256 reserveOut
	) external pure returns (uint256 amountOut);

	function getAmountIn(
		uint256 amountOut,
		uint256 reserveIn,
		uint256 reserveOut
	) external pure returns (uint256);

	function quote(
		uint256 amount,
		uint256 reserve0,
		uint256 reserve1
	) external pure returns (uint256);
}
