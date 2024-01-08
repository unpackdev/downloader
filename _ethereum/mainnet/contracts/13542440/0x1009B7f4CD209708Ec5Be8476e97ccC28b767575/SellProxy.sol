// Be name Khoda
// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
pragma abicoder v2;
// =================================================================================================================
//  _|_|_|    _|_|_|_|  _|    _|    _|_|_|      _|_|_|_|  _|                                                       |
//  _|    _|  _|        _|    _|  _|            _|            _|_|_|      _|_|_|  _|_|_|      _|_|_|    _|_|       |
//  _|    _|  _|_|_|    _|    _|    _|_|        _|_|_|    _|  _|    _|  _|    _|  _|    _|  _|        _|_|_|_|     |
//  _|    _|  _|        _|    _|        _|      _|        _|  _|    _|  _|    _|  _|    _|  _|        _|           |
//  _|_|_|    _|_|_|_|    _|_|    _|_|_|        _|        _|  _|    _|    _|_|_|  _|    _|    _|_|_|    _|_|_|     |
// =================================================================================================================
// ========================= SellProxy ===========================
// ===============================================================
// DEUS Finance: https://github.com/DeusFinance

// Primary Author(s)
// Vahid Gh: https://github.com/vahid-dev

import "./Ownable.sol";
import "./SafeERC20.sol";


interface IUniswapV2Router02 {
	function swapExactTokensForTokens(
		uint amountIn,
		uint amountOutMin,
		address[] calldata path,
		address to,
		uint deadline
	) external returns (uint[] memory amounts);

	function swapExactTokensForETH(
		uint amountIn,
		uint amountOutMin,
		address[] calldata path,
		address to,
		uint deadline
	) external returns (uint[] memory amounts);

	function getAmountsOut(
		uint amountIn, 
		address[] memory path
	) external view returns (uint[] memory amounts);
}

interface ICurveMetapool {
	function exchange_underlying(int128 i, int128 j, uint256 dx, uint256 min_dy) external returns (uint256);
	function get_dy_underlying(int128 i, int128 j, uint256 dx) external view returns (uint256);
}

contract SellProxy is Ownable {
	using SafeERC20 for IERC20;

	/* ========== STATE VARIABLES ========== */

	address public uniswapRouter;
	address public deiMetapool;
	address public deiAddress;
	address public deusAddress;
	address[] public deus2deiPath;
	address[] public coins;
	uint public deadline = 0xf000000000000000000000000000000000000000000000000000000000000000;


	/* ========== CONSTRUCTOR ========== */

	constructor(
		address _uniswapRouter,
		address _deiMetapool,
		address _deiAddress,
        address _deusAddress,
		address[] memory _deus2deiPath,
		address[] memory _coins
	) {
		uniswapRouter = _uniswapRouter;
		deiMetapool= _deiMetapool;
		deiAddress = _deiAddress;
		deusAddress = _deusAddress;

		deus2deiPath = _deus2deiPath;
		coins = _coins;

		IERC20(_deusAddress).safeApprove(_uniswapRouter, type(uint256).max);
		IERC20(_deiAddress).safeApprove(_deiMetapool, type(uint256).max);
	}


	/* ========== PUBLIC FUNCTIONS ========== */

	function DEUS2Stablecoin(uint amountIn, uint minAmountOut, int128 j) external returns (uint amountOut) {
        IERC20(deusAddress).safeTransferFrom(msg.sender, address(this), amountIn);
        
        uint deiAmount = IUniswapV2Router02(uniswapRouter).swapExactTokensForTokens(amountIn, 1, deus2deiPath, address(this), deadline)[1];
		amountOut = ICurveMetapool(deiMetapool).exchange_underlying(0, j, deiAmount, minAmountOut);
        emit Buy(amountIn, amountOut, coins[uint128(j)]);
	}

	function DEUS2ERC20OrEther(uint amountIn, uint minAmountOut, int128 j, address[] memory path, bool eth) external returns (uint amountOut) {
        IERC20(deusAddress).safeTransferFrom(msg.sender, address(this), amountIn);
        
        uint deiAmount = IUniswapV2Router02(uniswapRouter).swapExactTokensForTokens(amountIn, 1, deus2deiPath, address(this), deadline)[1];
		uint stablecoinAmount = ICurveMetapool(deiMetapool).exchange_underlying(0, j, deiAmount, minAmountOut);

		// check safeApprove part
		address token = path[0];
		if (IERC20(token).allowance(address(this), uniswapRouter) < stablecoinAmount) {
			IERC20(token).safeApprove(uniswapRouter, type(uint256).max);
		}

		if (eth) {
			amountOut = IUniswapV2Router02(uniswapRouter).swapExactTokensForETH(stablecoinAmount, minAmountOut, path, msg.sender, deadline)[path.length - 1];
		} else {
			amountOut = IUniswapV2Router02(uniswapRouter).swapExactTokensForTokens(stablecoinAmount, minAmountOut, path, msg.sender, deadline)[path.length - 1];
		}

		emit Buy(amountIn, amountOut, path[path.length - 1]);
	}


	/* ========== VIEWS ========== */

	function getAmountOut(uint amountIn, int128 j, address[] memory path) public view returns (uint amountOut) {
		uint deiAmount = IUniswapV2Router02(uniswapRouter).getAmountsOut(amountIn, deus2deiPath)[1];
		amountOut = ICurveMetapool(deiMetapool).get_dy_underlying(0, j, deiAmount);
		if (path.length > 0) {
			amountOut = IUniswapV2Router02(uniswapRouter).getAmountsOut(amountOut, path)[path.length - 1];
		}
	}


	/* ========== RESTRICTED FUNCTIONS ========== */

	function safeApprove(address token, address to) external onlyOwner {
		IERC20(token).safeApprove(to, type(uint256).max);
	}

	function emergencyWithdrawERC20(address token, address to, uint amount) external onlyOwner {
		IERC20(token).safeTransfer(to, amount);
	}

	function emergencyWithdrawETH(address to, uint amount) external onlyOwner {
		payable(to).transfer(amount);
	}


	/* ========== EVENTS ========== */
	
	event Buy(uint amountIn, uint amountOut, address outputToken);
}

// Dar panahe Khoda
