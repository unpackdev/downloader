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
// ========================= DEUSZapper =========================
// ==============================================================
// DEUS Finance: https://github.com/DeusFinance

// Primary Author(s)
// Vahid Gh: https://github.com/vahid-dev

import "./Ownable.sol";
import "./SafeERC20.sol";


library Babylonian {
	function sqrt(uint256 y) internal pure returns (uint256 z) {
		if (y > 3) {
			z = y;
			uint256 x = y / 2 + 1;
			while (x < z) {
				z = x;
				x = (y / x + x) / 2;
			}
		} else if (y != 0) {
			z = 1;
		}
		// else z = 0
	}
}

interface IUniswapV2Router02 {
	function factory() external pure returns (address);
	function addLiquidity(
		address tokenA,
		address tokenB,
		uint256 amountADesired,
		uint256 amountBDesired,
		uint256 amountAMin,
		uint256 amountBMin,
		address to,
		uint256 deadline
	) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

	function swapExactTokensForTokens(
		uint256 amountIn,
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external returns (uint256[] memory amounts);

	function swapExactETHForTokens(
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external payable returns (uint256[] memory amounts);

	function getAmountsOut(
		uint256 amountIn, 
		address[] calldata path
	) external view returns (uint256[] memory amounts);
}

interface IUniwapV2Pair {
	function token0() external pure returns (address);
	function token1() external pure returns (address);
	function totalSupply() external view returns (uint);
	function getReserves() external view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);
}

interface IStaking {
	function depositFor(address _user, uint256 amount) external;
}

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

interface IDEIProxy {
	function getUSDC2DEIInputs(
		uint amountIn, 
		uint deusPriceUSD, 
		uint colPriceUSD
	) external view returns (uint amountOut, uint usdcForMintAmount, uint deusNeededAmount);
	function USDC2DEI(ProxyInput memory proxyInput) external returns (uint deiAmount);
}

contract DEI_DEUS_ZAPPER is Ownable {
	using SafeERC20 for IERC20;

	/* ========== STATE VARIABLES ========== */

	bool public stopped;
	address public uniswapRouter;
	address public pairAddress;
	address public usdcAddress;
	address public deiAddress;
	address public deusAddress;
	address public stakingAddress;
	address public deiProxyAddress;
	uint private constant deadline = 0xf000000000000000000000000000000000000000000000000000000000000000;

	/* ========== CONSTRUCTOR ========== */

	constructor (
		address _pairAddress,
		address _usdcAddress,
		address _deiAddress,
		address _deusAddress,
		address _uniswapRouter,
		address _stakingAddress,
		address _deiProxyAddress
	) {
		uniswapRouter = _uniswapRouter;
		pairAddress = _pairAddress;
		usdcAddress = _usdcAddress;
		deiAddress = _deiAddress;
		deusAddress = _deusAddress;
		stakingAddress = _stakingAddress;
		deiProxyAddress = _deiProxyAddress;
		init();
	}

	/* ========== RESTRICTED FUNCTIONS ========== */

	function approve(address token, address to) public onlyOwner {
		IERC20(token).safeApprove(to, type(uint256).max);
	}

	function emergencyWithdrawERC20(address token, address to, uint amount) external onlyOwner {
		IERC20(token).safeTransfer(to, amount);
	}

	function emergencyWithdrawETH(address recv, uint amount) external onlyOwner {
		payable(recv).transfer(amount);
	}

	function setStaking(address _stakingAddress) external onlyOwner {
		stakingAddress = _stakingAddress;
		emit StakingSet(stakingAddress);
	}

	function setVariables(
		address _pairAddress,
		address _usdcAddress,
		address _deiAddress,
		address _deusAddress,
		address _uniswapRouter,
		address _stakingAddress,
		address _deiProxyAddress
	) external onlyOwner {
		uniswapRouter = _uniswapRouter;
		pairAddress = _pairAddress;
		usdcAddress = _usdcAddress;
		deiAddress = _deiAddress;
		deusAddress = _deusAddress;
		stakingAddress = _stakingAddress;
		deiProxyAddress = _deiProxyAddress;
	}

	// circuit breaker modifiers
	modifier stopInEmergency() {
		require(!stopped, "ZAPPER: temporarily paused");
		_;
	}

	/* ========== PUBLIC FUNCTIONS ========== */

	function zapInNativecoin(
		ProxyInput memory proxyInput,
		uint256 minLPAmount,
		address[] calldata path,
		bool transferResidual  // Set false to save gas by donating the residual remaining after a Zap
	) external payable {
		proxyInput.amountIn = IUniswapV2Router02(uniswapRouter).swapExactETHForTokens{value: msg.value}(1, path, address(this), deadline)[path.length-1];

		uint deiAmount = IDEIProxy(deiProxyAddress).USDC2DEI(proxyInput);

		(uint256 token0Bought, uint256 token1Bought) = _buyTokens(deiAddress, deiAmount);

		uint256 LPBought = _uniDeposit(IUniwapV2Pair(pairAddress).token0(),
										IUniwapV2Pair(pairAddress).token1(),
										token0Bought,
										token1Bought,
										transferResidual);

		require(LPBought >= minLPAmount, "ZAPPER: Insufficient output amount");

		IStaking(stakingAddress).depositFor(msg.sender, LPBought);

		emit ZappedIn(address(0), pairAddress, msg.value, LPBought, transferResidual);
	}


	function zapInERC20(
		ProxyInput memory proxyInput,
		uint256 amountIn,
		uint256 minLPAmount,
		address[] calldata path,
		bool transferResidual  // Set false to save gas by donating the residual remaining after a Zap
	) external {
		IERC20(path[0]).safeTransferFrom(msg.sender, address(this), amountIn);
		
		if (path[0] != usdcAddress) {
			// approve token if doesn't have allowance
			if (IERC20(path[0]).allowance(address(this), uniswapRouter) == 0) IERC20(path[0]).safeApprove(uniswapRouter, type(uint).max);
			proxyInput.amountIn = IUniswapV2Router02(uniswapRouter).swapExactTokensForTokens(amountIn, 1, path, address(this), deadline)[path.length-1];
		}

		uint deiAmount = IDEIProxy(deiProxyAddress).USDC2DEI(proxyInput);

		(uint256 token0Bought, uint256 token1Bought) = _buyTokens(deiAddress, deiAmount);

		uint256 LPBought = _uniDeposit(IUniwapV2Pair(pairAddress).token0(),
										IUniwapV2Pair(pairAddress).token1(),
										token0Bought,
										token1Bought,
										transferResidual);

		require(LPBought >= minLPAmount, "ZAPPER: Insufficient output amount");

		IStaking(stakingAddress).depositFor(msg.sender, LPBought);

		emit ZappedIn(path[0], pairAddress, amountIn, LPBought, transferResidual);
	}


	function zapInDEI(
		uint256 amountIn,
		uint256 minLPAmount,
		bool transferResidual  // Set false to save gas by donating the residual remaining after a Zap
	) public stopInEmergency {
		IERC20(deiAddress).safeTransferFrom(msg.sender, address(this), amountIn);

		(uint256 token0Bought, uint256 token1Bought) = _buyTokens(deiAddress, amountIn);

		uint256 LPBought = _uniDeposit(IUniwapV2Pair(pairAddress).token0(),
										IUniwapV2Pair(pairAddress).token1(),
										token0Bought,
										token1Bought,
										transferResidual);

		require(LPBought >= minLPAmount, "ZAPPER: Insufficient output amount");

		IStaking(stakingAddress).depositFor(msg.sender, LPBought);

		emit ZappedIn(deiAddress, pairAddress, amountIn, LPBought, transferResidual);
	}

	function zapInDEUS(
		uint amountIn,
		uint minLPAmount,
		bool transferResidual
	) external stopInEmergency {
		IERC20(deusAddress).safeTransferFrom(msg.sender, address(this), amountIn);

		(uint256 token0Bought, uint256 token1Bought) = _buyTokens(deusAddress, amountIn);

		uint256 LPBought = _uniDeposit(IUniwapV2Pair(pairAddress).token0(),
									IUniwapV2Pair(pairAddress).token1(),
									token0Bought,
									token1Bought,
									transferResidual);

		require(LPBought >= minLPAmount, "ZAPPER: Insufficient output amount");

		IStaking(stakingAddress).depositFor(msg.sender, LPBought);

		emit ZappedIn(deiAddress, pairAddress, amountIn, LPBought, transferResidual);
	}

	function _buyTokens(address inputToken, uint256 _amount) internal returns(uint256 token0Bought, uint256 token1Bought) {
		IUniwapV2Pair pair = IUniwapV2Pair(pairAddress);
		(uint res0, uint256 res1, ) = pair.getReserves();
		if (inputToken == pair.token0()) {
			uint256 amountToSwap = calculateSwapInAmount(res0, _amount);	
			if (amountToSwap <= 0) amountToSwap = _amount / 2;
			token1Bought = _token2Token(
							inputToken,
							pair.token1(), // it depend on pair tokens (token0 or token1)
							amountToSwap
						);
			token0Bought = _amount - amountToSwap;
		} else {
			uint256 amountToSwap = calculateSwapInAmount(res1, _amount);
			if (amountToSwap <= 0) amountToSwap = _amount / 2;
			token0Bought = _token2Token(
								inputToken,
								pair.token0(), // it depend on pair tokens (token0 or token1)
								amountToSwap
							);
			token1Bought = _amount - amountToSwap;
		}
	}

	function _token2Token(
		address _fromToken,
		address _toToken,
		uint256 tokens2Trade
	) internal returns (uint256 tokenBought) {
		address[] memory path = new address[](2);
		path[0] = _fromToken;
		path[1] = _toToken;

		tokenBought = IUniswapV2Router02(uniswapRouter).swapExactTokensForTokens(tokens2Trade,
																				1,
																				path,
																				address(this),
																				deadline)[path.length-1];

		require(tokenBought > 0, "ZAPPER: Error swapExactTokensForTokens");
	}

	function calculateSwapInAmount(uint256 reserveIn, uint256 userIn)
		internal
		pure
		returns (uint256)
	{
		return (Babylonian.sqrt(reserveIn * ((userIn * 3988000) + (reserveIn * 3988009))) - (reserveIn * 1997)) / 1994;
	}

	function _uniDeposit(
		address _toUnipoolToken0,
		address _toUnipoolToken1,
		uint256 token0Bought,
		uint256 token1Bought,
		bool transferResidual
	) internal returns(uint256) {
		(uint256 amountA, uint256 amountB, uint256 LP) = IUniswapV2Router02(uniswapRouter).addLiquidity(_toUnipoolToken0,
																										_toUnipoolToken1,
																										token0Bought,
																										token1Bought,
																										1,
																										1,
																										address(this),
																										deadline);

		if (transferResidual) {
			//Returning Residue in token0, if any.
			if (token0Bought - amountA > 0) {
				IERC20(_toUnipoolToken0).safeTransfer(
					msg.sender,
					token0Bought - amountA
				);
			}

			//Returning Residue in token1, if any
			if (token1Bought - amountB > 0) {
				IERC20(_toUnipoolToken1).safeTransfer(
					msg.sender,
					token1Bought - amountB
				);
			}
		}

		return LP;
	}

	/* ========== VIEWS ========== */

	function getAmountOutLPERC20ORNativecoin(uint amountIn, uint deusPriceUSD, uint colPriceUSD, address[] memory path) public view returns (uint percentage, uint lp, uint usdcForMintAmount, uint deusNeededAmount) {
		uint deiAmount;
		uint usdcAmount = IUniswapV2Router02(uniswapRouter).getAmountsOut(amountIn, path)[path.length - 1];
		(deiAmount, usdcForMintAmount, deusNeededAmount) = IDEIProxy(deiProxyAddress).getUSDC2DEIInputs(usdcAmount, deusPriceUSD, colPriceUSD);
		
		IUniwapV2Pair pair = IUniwapV2Pair(pairAddress);
		uint totalSupply = pair.totalSupply();
		(uint res0, uint256 res1, ) = pair.getReserves(); 
		uint dei_to_deus_amount;
		if (deiAddress == pair.token0()) {
			dei_to_deus_amount = calculateSwapInAmount(res0, deiAmount);
			uint dei_pure_amount = deiAmount - dei_to_deus_amount; 
			percentage = dei_pure_amount * 1e6 / (res0 + dei_pure_amount);
			lp = dei_pure_amount * totalSupply / res0;
		} else {
			dei_to_deus_amount = calculateSwapInAmount(res1, deiAmount);
			uint dei_pure_amount = deiAmount - dei_to_deus_amount; 
			percentage = dei_pure_amount * 1e6 / (res1 + dei_pure_amount);
			lp = dei_pure_amount * totalSupply / res1;
		}
	}

	function getAmountOutLPDEUS(uint amount) public view returns (uint percentage, uint lp) {
		IUniwapV2Pair pair = IUniwapV2Pair(pairAddress);
		uint totalSupply = pair.totalSupply();
		(uint res0, uint256 res1, ) = pair.getReserves(); 
		uint deus_to_dei_amount;
		if (deusAddress == pair.token0()) {
			deus_to_dei_amount = calculateSwapInAmount(res0, amount);
			uint deus_pure_amount = amount - deus_to_dei_amount; 
			percentage = deus_pure_amount * 1e6 / (res0 + amount);
			lp = deus_pure_amount * totalSupply / res0;
		} else {
			deus_to_dei_amount = calculateSwapInAmount(res1, amount);
			uint deus_pure_amount = amount - deus_to_dei_amount; 
			percentage = deus_pure_amount * 1e6 / (res1 + amount);
			lp = deus_pure_amount * totalSupply / res1;
		}
	}

	function getAmountOutLPDEI(uint dei_amount) public view returns (uint percentage, uint lp){
		IUniwapV2Pair pair = IUniwapV2Pair(pairAddress);
		uint totalSupply = pair.totalSupply();
		(uint res0, uint256 res1, ) = pair.getReserves(); 
		uint dei_to_deus_amount;
		if (deiAddress == pair.token0()) {
			dei_to_deus_amount = calculateSwapInAmount(res0, dei_amount);
			uint dei_pure_amount = dei_amount - dei_to_deus_amount; 
			percentage = dei_pure_amount * 1e6 / (res0 + dei_pure_amount);
			lp = dei_pure_amount * totalSupply / res0;
		} else {
			dei_to_deus_amount = calculateSwapInAmount(res1, dei_amount);
			uint dei_pure_amount = dei_amount - dei_to_deus_amount; 
			percentage = dei_pure_amount * 1e6 / (res1 + dei_pure_amount);
			lp = dei_pure_amount * totalSupply / res1;
		}
	}

	function init() public onlyOwner {
		approve(IUniwapV2Pair(pairAddress).token0(), uniswapRouter);
		approve(IUniwapV2Pair(pairAddress).token1(), uniswapRouter);
		approve(pairAddress, stakingAddress);
		approve(usdcAddress, deiProxyAddress);
	}

	// to Pause the contract
	function toggleContractActive() external onlyOwner {
		stopped = !stopped;
	}

	event StakingSet(address staking);
	event ZappedIn(address input_token, address output_token, uint input_amount, uint output_amount, bool transfer_residual);
}

// Dar panahe Khoda