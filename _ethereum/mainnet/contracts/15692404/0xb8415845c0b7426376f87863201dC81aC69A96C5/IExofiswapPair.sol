// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IExofiswapCallee.sol";
import "./IExofiswapERC20.sol";
import "./IExofiswapFactory.sol";

interface IExofiswapPair is IExofiswapERC20
{
	event Mint(address indexed sender, uint256 amount0, uint256 amount1);
	event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
	event Swap(address indexed sender, uint256 amount0In, uint256 amount1In, uint256 amount0Out, uint256 amount1Out, address indexed to);
	event Sync(uint112 reserve0, uint112 reserve1);

	function burn(address to) external returns (uint256 amount0, uint256 amount1);
	function initialize(IERC20Metadata token0Init, IERC20Metadata token1Init) external;
	function mint(address to) external returns (uint256 liquidity);
	function skim(address to) external;
	function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;
	function sync() external;

	function factory() external view returns (IExofiswapFactory);
	function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
	function kLast() external view returns (uint256);
	function price0CumulativeLast() external view returns (uint256);
	function price1CumulativeLast() external view returns (uint256);
	function token0() external view returns (IERC20Metadata);
	function token1() external view returns (IERC20Metadata);

	function MINIMUM_LIQUIDITY() external pure returns (uint256); //solhint-disable-line func-name-mixedcase
}