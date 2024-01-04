pragma solidity =0.6.6;
pragma experimental ABIEncoderV2;

import "./ICapitalFreeLiquidate.sol";
import "./IBorrowable.sol";
import "./ICollateral.sol";
import "./IImpermaxCallee.sol";
import "./IERC20.sol";
import "./IWETH.sol";
import "./IUniswapV2Pair.sol";
import "./SafeMath.sol";
import "./TransferHelper.sol";
import "./UniswapV2Library.sol";

// This assumes that the borrower has enough collateral to repay
// The chance that this is not true is low and the check isn't worth the additional gas cost
// The check should be done off chain, and the caller should use the right liquidateAmount parameter
// Another problem is the slippage, so it may be convenient to liquidate large amounts in multiple rounds

// TODO: bot to liquidate both sides at the same time?

contract CapitalFreeLiquidate is ICapitalFreeLiquidate, IImpermaxCallee {
	using SafeMath for uint;

	address public immutable override factory;
	address public immutable override bDeployer;
	address public immutable override cDeployer;
	address public immutable override WETH;
	
	address public override to;

	constructor(address _factory, address _bDeployer, address _cDeployer, address _WETH, address _to) public {
		factory = _factory;
		bDeployer = _bDeployer;
		cDeployer = _cDeployer;
		WETH = _WETH;
		to = _to;
	}

	receive() external payable {
		assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
	}
	
	function _burn(
		address uniswapV2Pair, 
		uint collateralAmount
	) internal virtual returns (uint amount0, uint amount1) {
		TransferHelper.safeTransfer(uniswapV2Pair, uniswapV2Pair, collateralAmount);
		(amount0, amount1) = IUniswapV2Pair(uniswapV2Pair).burn(address(this));
	}
	
	function _swap(
		address uniswapV2Pair, 
		address tokenIn, 
		uint amountIn, 
		uint amountOut, 
		uint8 index
	) internal virtual {
		TransferHelper.safeTransfer(tokenIn, uniswapV2Pair, amountIn);
		(uint amount0Out, uint amount1Out) = index == 1 ? (uint(0), amountOut) : (amountOut, uint(0));
		IUniswapV2Pair(uniswapV2Pair).swap(amount0Out, amount1Out, address(this), new bytes(0));
	}
	
	function _liquidateAmount(
		address borrowable,
		uint amountMax,
		address borrower
	) internal virtual returns (uint amount) {
		IBorrowable(borrowable).accrueInterest();
		uint borrowedAmount = IBorrowable(borrowable).borrowBalance(borrower);
		amount = amountMax < borrowedAmount ? amountMax : borrowedAmount;
	}
	
	function _getBorrowablePrice(
		address uniswapV2Pair,
		address collateral,
		uint8 index,
		uint swapAmount
	) internal virtual returns (uint price) {
		(uint price0, uint price1) = ICollateral(collateral).getPrices();
		price = index == 0 ? price0 : price1;
		(uint reserve0, uint reserve1,) = IUniswapV2Pair(uniswapV2Pair).getReserves();
		uint reserve = index == 0 ? reserve0 : reserve1;
		// Account for LP appreciation after swap
		price = price.mul(reserve).div(reserve.add(swapAmount * 3 / 1000));
	}
	
	function _getExpectedCollateralAmount(
		address uniswapV2Pair,
		address collateral,
		uint8 toLiquidateIndex,
		uint liquidateAmount
	) internal virtual returns (uint collateralAmount) {
		uint price = _getBorrowablePrice(uniswapV2Pair, collateral, toLiquidateIndex, liquidateAmount);
		uint liquidationIncentive = ICollateral(collateral).liquidationIncentive();
		collateralAmount = liquidateAmount.mul(liquidationIncentive).div(1e18).mul(price).div(1e18).sub(1);
	}
	
	function _simulateBurn(
		address uniswapV2Pair,
		uint collateralAmount
	) internal virtual view returns (uint amount0, uint amount1, uint reserve0, uint reserve1) {
		uint totalSupply = IUniswapV2Pair(uniswapV2Pair).totalSupply();
		(uint reserve0Old, uint reserve1Old,) = IUniswapV2Pair(uniswapV2Pair).getReserves();
		amount0 = collateralAmount.mul(reserve0Old).div(totalSupply);
		amount1 = collateralAmount.mul(reserve1Old).div(totalSupply);
		reserve0 = reserve0Old.sub(amount0);
		reserve1 = reserve1Old.sub(amount1);
	}

	function _getLiquidateProfit(
		address uniswapV2Pair,
		uint8 toLiquidateIndex,
		uint8 takeProfitIndex,
		uint liquidateAmount,
		uint collateralAmount
	) internal virtual view returns (uint profit, uint amountIn, uint amountOut) {
		(uint amount0, uint amount1, uint reserve0, uint reserve1) = _simulateBurn(uniswapV2Pair, collateralAmount);
		(uint reserveIn, uint reserveOut) = toLiquidateIndex == 1 ? (reserve0, reserve1) : (reserve1, reserve0);
		uint amountOutBalance = toLiquidateIndex == 1 ? amount1 : amount0;
		if (takeProfitIndex == toLiquidateIndex) {
			// Swap all
			amountIn = toLiquidateIndex == 1 ? amount0 : amount1;
			amountOut = UniswapV2Library.getAmountOut(amountIn, reserveIn, reserveOut);
			profit = amountOutBalance.add(amountOut).sub(liquidateAmount, "CapitalFreeLiquidate: NEGATIVE_PROFIT_1");
		}
		else {
			// Swap only necessary
			amountOut = liquidateAmount.sub(amountOutBalance);
			amountIn = UniswapV2Library.getAmountIn(amountOut, reserveIn, reserveOut);
			uint amountInBalance = toLiquidateIndex == 1 ? amount0 : amount1;
			profit = amountInBalance.sub(amountIn, "CapitalFreeLiquidate: NEGATIVE_PROFIT_2");
		}
	}
	
	function _getTokenInTokenOut(
		address uniswapV2Pair,
		uint8 index
	) internal virtual view returns (address tokenIn, address tokenOut) {
		address token0 = IUniswapV2Pair(uniswapV2Pair).token0();
		address token1 = IUniswapV2Pair(uniswapV2Pair).token1();
		(tokenIn, tokenOut) = index == 1 ? (token0, token1) : (token1, token0);
	}
	
	function liquidate(
		address uniswapV2Pair,
		uint8 toLiquidateIndex,
		uint8 takeProfitIndex,
		address borrower,
		uint liquidateAmountMax,
		uint profitMin
	) external virtual override returns (uint profit) {
		address collateral = getCollateral(uniswapV2Pair);		
		address borrowable = getBorrowable(uniswapV2Pair, toLiquidateIndex);
		uint liquidateAmount = _liquidateAmount(borrowable, liquidateAmountMax, borrower);
		uint collateralAmount = _getExpectedCollateralAmount(uniswapV2Pair, collateral, toLiquidateIndex, liquidateAmount);
		uint amountIn;
		uint amountOut;
		(profit, amountIn, amountOut) = 
			_getLiquidateProfit(uniswapV2Pair, toLiquidateIndex, takeProfitIndex, liquidateAmount, collateralAmount);
		require(profit >= profitMin, "CapitalFreeLiquidator: INSUFFICIENT_PROFIT");
		bytes memory data = abi.encode(CalleeData({
			uniswapV2Pair: uniswapV2Pair,
			collateral: collateral,
			borrowable: borrowable,
			toLiquidateIndex: toLiquidateIndex,
			takeProfitIndex: takeProfitIndex,
			borrower: borrower,
			amountIn: amountIn,
			amountOut: amountOut,
			liquidateAmount: liquidateAmount
		}));
		ICollateral(collateral).flashRedeem(address(this), collateralAmount, data);
	}
	
	function liquidateCallback(
		address uniswapV2Pair,
		address collateral,
		address borrowable,
		uint8 toLiquidateIndex,
		uint8 takeProfitIndex,
		address borrower,
		uint amountIn,
		uint amountOut,
		uint liquidateAmount,
		uint collateralAmount
	) internal virtual {
		_burn(uniswapV2Pair, collateralAmount);
		(address tokenIn, address tokenOut) = _getTokenInTokenOut(uniswapV2Pair, toLiquidateIndex);
		_swap(uniswapV2Pair, tokenIn, amountIn, amountOut, toLiquidateIndex);
		TransferHelper.safeTransfer(tokenOut, borrowable, liquidateAmount);
		uint seizeTokens = IBorrowable(borrowable).liquidate(borrower, address(this));
		TransferHelper.safeTransfer(collateral, collateral, seizeTokens);
		if (toLiquidateIndex == takeProfitIndex) skim(tokenOut);
		else skim(tokenIn);
	}
	
	struct CalleeData {
		address uniswapV2Pair;
		address collateral;
		address borrowable;
		uint8 toLiquidateIndex;
		uint8 takeProfitIndex;
		address borrower;
		uint amountIn;
		uint amountOut;
		uint liquidateAmount;
	}
	
	function impermaxRedeem(address sender, uint redeemAmount, bytes calldata data) external virtual override {
		sender;
		// no security check needed
		CalleeData memory calleeData = abi.decode(data, (CalleeData));
		liquidateCallback(
			calleeData.uniswapV2Pair,
			calleeData.collateral,
			calleeData.borrowable,
			calleeData.toLiquidateIndex,
			calleeData.takeProfitIndex,
			calleeData.borrower,
			calleeData.amountIn,
			calleeData.amountOut,
			calleeData.liquidateAmount,
			redeemAmount
		);
	}

	function impermaxBorrow(address sender, address borrower, uint borrowAmount, bytes calldata data) external virtual override { sender; borrower; borrowAmount; data; }
	
	function skim(address token) public virtual override {
		uint balance = IERC20(token).balanceOf(address(this));
		if (token == WETH) {		
			IWETH(WETH).withdraw(balance);
			TransferHelper.safeTransferETH(to, balance);
		}
		else TransferHelper.safeTransfer(token, to, balance);
	}
	
	/*** UTILITIES ***/
	
	function getBorrowable(address uniswapV2Pair, uint8 index) public virtual override view returns (address borrowable) {
		require(index < 2, "CapitalFreeLiquidator: INDEX_TOO_HIGH");
		borrowable = address(uint(keccak256(abi.encodePacked(
			hex"ff",
			bDeployer,
			keccak256(abi.encodePacked(factory, uniswapV2Pair, index)),
			hex"605ba1db56496978613939baf0ae31dccceea3f5ca53dfaa76512bc880d7bb8f" // Borrowable bytecode keccak256
		))));
	}
	function getCollateral(address uniswapV2Pair) public virtual override view returns (address collateral) {
		collateral = address(uint(keccak256(abi.encodePacked(
			hex"ff",
			cDeployer,
			keccak256(abi.encodePacked(factory, uniswapV2Pair)),
			hex"4b8788d8761647e6330407671d3c6c80afaed3d047800dba0e0e3befde047767" // Collateral bytecode keccak256
		))));
	}
	function getLendingPool(address uniswapV2Pair) public virtual override view returns (address collateral, address borrowableA, address borrowableB) {
		collateral = getCollateral(uniswapV2Pair);
		borrowableA = getBorrowable(uniswapV2Pair, 0);
		borrowableB = getBorrowable(uniswapV2Pair, 1);
	}
}
