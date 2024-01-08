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
// ========================= MultiSwap ============================
// ===============================================================
// DEUS Finance: https://github.com/DeusFinance

// Primary Author(s)
// Kazem

import "./Ownable.sol";
import "./IERC20.sol";


interface IDEIProxy {
    struct ProxyInput {
		uint amountIn;
		uint minAmountOut;
		uint deusPriceUSD;
		uint colPriceUSD;
		uint usdcForMintAmount;
		uint deusNeededAmount;
		uint expireBlock;
		bytes[] sigs;
	}
	function USDC2DEI(ProxyInput memory proxyInput) external returns (uint deiAmount);
    function ERC202DEI(ProxyInput memory proxyInput, address[] memory path) external returns (uint deiAmount);
    function Nativecoin2DEI(ProxyInput memory proxyInput, address[] memory path) payable external returns (uint deiAmount);
    function getUSDC2DEIInputs(uint amountIn, uint deusPriceUSD, uint colPriceUSD) external view returns (uint amountOut, uint usdcForMintAmount, uint deusNeededAmount);
    function getERC202DEIInputs(uint amountIn, uint deusPriceUSD, uint colPriceUSD, address[] memory path) external view returns (uint amountOut, uint usdcForMintAmount, uint deusNeededAmount);
}


interface IUniswapV2Router02 {
	function swapExactTokensForTokens(
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

contract MultiSwap is Ownable {
	/* ========== STATE VARIABLES ========== */

	address public uniswapRouter;
	address public deiAddress;
	address public usdcAddress;
    address public deiProxy;

	address[] public dei2deusPath;

	uint public deadline = 0xf000000000000000000000000000000000000000000000000000000000000000;

	/* ========== CONSTRUCTOR ========== */

	constructor(
		address _uniswapRouter,
		address _deiAddress,
		address _usdcAddress,
        address _deiProxy,
		address[] memory _dei2deusPath
	) {
		uniswapRouter = _uniswapRouter;
		deiAddress = _deiAddress;
		usdcAddress = _usdcAddress;
        deiProxy = _deiProxy;

		dei2deusPath = _dei2deusPath;

		IERC20(usdcAddress).approve(_deiProxy, type(uint256).max);
		IERC20(deiAddress).approve(_uniswapRouter, type(uint256).max);
	}

	/* ========== RESTRICTED FUNCTIONS ========== */

	function approve(address token, address to) external onlyOwner {
		IERC20(token).approve(to, type(uint256).max);
	}

	function emergencyWithdrawERC20(address token, address to, uint amount) external onlyOwner {
		IERC20(token).transfer(to, amount);
	}

	function emergencyWithdrawETH(address to, uint amount) external onlyOwner {
		payable(to).transfer(amount);
	}

	/* ========== PUBLIC FUNCTIONS ========== */

	function USDC2DEUS(IDEIProxy.ProxyInput memory proxyInput) external returns (uint deusAmount) {
        IERC20(usdcAddress).transferFrom(msg.sender, address(this), proxyInput.amountIn);

		uint deiAmount = IDEIProxy(deiProxy).USDC2DEI(proxyInput);
        
        deusAmount = IUniswapV2Router02(uniswapRouter).swapExactTokensForTokens(deiAmount, 1, dei2deusPath, msg.sender, deadline)[1];

        require(proxyInput.minAmountOut <= deusAmount, "Multi Swap: Insufficient output amount");

        emit Buy(usdcAddress, proxyInput.amountIn, deusAmount);
	}


	function ERC202DEUS(IDEIProxy.ProxyInput memory proxyInput, address[] memory path) external returns (uint deusAmount) {
		IERC20(path[0]).transferFrom(msg.sender, address(this), proxyInput.amountIn);

		// approve if it doesn't have allowance
		if (IERC20(path[0]).allowance(address(this), deiProxy) == 0) {IERC20(path[0]).approve(deiProxy, type(uint).max);}
        
        uint deiAmount = IDEIProxy(deiProxy).ERC202DEI(proxyInput, path);
        
        deusAmount = IUniswapV2Router02(uniswapRouter).swapExactTokensForTokens(deiAmount, 1, dei2deusPath, msg.sender, deadline)[1];

        require(proxyInput.minAmountOut <= deusAmount, "Multi Swap: Insufficient output amount");

        emit Buy(path[0], proxyInput.amountIn, deusAmount);
	}

	function Nativecoin2DEUS(IDEIProxy.ProxyInput memory proxyInput, address[] memory path) payable external returns (uint deusAmount) {
		uint deiAmount = IDEIProxy(deiProxy).Nativecoin2DEI{value: msg.value}(proxyInput, path);
        
        deusAmount = IUniswapV2Router02(uniswapRouter).swapExactTokensForTokens(deiAmount, 1, dei2deusPath, msg.sender, deadline)[1];

        require(proxyInput.minAmountOut <= deusAmount, "Multi Swap: Insufficient output amount");

        emit Buy(path[0], proxyInput.amountIn, deusAmount);
	}

	/* ========== VIEWS ========== */

	function getUSDC2DEUSInputs(uint amountIn, uint deusPriceUSD, uint colPriceUSD) public view returns (uint amountOut, uint usdcForMintAmount, uint deusNeededAmount) {
		(amountOut, usdcForMintAmount, deusNeededAmount) = IDEIProxy(deiProxy).getUSDC2DEIInputs(amountIn, deusPriceUSD, colPriceUSD);
        amountOut = IUniswapV2Router02(uniswapRouter).getAmountsOut(amountOut, dei2deusPath)[1];
	}

	function getERC202DEUSInputs(uint amountIn, uint deusPriceUSD, uint colPriceUSD, address[] memory path) public view returns (uint amountOut, uint usdcForMintAmount, uint deusNeededAmount) {
		(amountOut, usdcForMintAmount, deusNeededAmount) = IDEIProxy(deiProxy).getERC202DEIInputs(amountIn, deusPriceUSD, colPriceUSD, path);
        amountOut = IUniswapV2Router02(uniswapRouter).getAmountsOut(amountOut, dei2deusPath)[1];
	}

	/* ========== EVENTS ========== */

	event Buy(address tokenIn, uint amountIn, uint amountOut);
}

// Dar panahe Khoda
