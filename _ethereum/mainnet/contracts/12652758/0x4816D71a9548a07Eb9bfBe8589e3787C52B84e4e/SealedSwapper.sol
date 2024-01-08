// Be Name KHODA
// Bime Abolfazl

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";


interface IBPool {
	function exitPool(uint poolAmountIn, uint[] calldata minAmountsOut) external;
	function exitswapPoolAmountIn(address tokenOut, uint256 poolAmountIn, uint256 minAmountOut) external returns (uint256 tokenAmountOut);
	function transferFrom(address src, address dst, uint256 amt) external returns (bool);
}

interface IERC20 {
	function approve(address dst, uint256 amt) external returns (bool);
	function transfer(address recipient, uint256 amount) external returns (bool);
	function totalSupply() external view returns (uint);
	function balanceOf(address owner) external returns (uint);
}

interface Vault {
	function lockFor(uint256 amount, address _user) external returns (uint256);
}

interface SealedToken {
	function burn(address from, uint256 amount) external;
	function transfer(address recipient, uint256 amount) external returns (bool);
	function transferFrom(address src, address dst, uint256 amt) external returns (bool);
	function balanceOf(address owner) external returns (uint);
}

interface IUniswapV2Pair {
	function getReserves() external returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

interface IUniswapV2Router02 {
	function removeLiquidityETH(
		address token,
		uint256 liquidity,
		uint256 amountTokenMin,
		uint256 amountETHMin,
		address to,
		uint256 deadline
	) external returns (uint256 amountToken, uint256 amountETH);

	function removeLiquidity(
		address tokenA,
		address tokenB,
		uint256 liquidity,
		uint256 amountAMin,
		uint256 amountBMin,
		address to,
		uint256 deadline
	) external returns (uint256 amountA, uint256 amountB);

	function swapExactTokensForTokens(
		uint256 amountIn,
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external returns (uint256[] memory amounts);

	function swapExactTokensForETH(
		uint amountIn,
		uint amountOutMin,
		address[] calldata path,
		address to,
		uint deadline
	) external returns (uint[] memory amounts);

	function getAmountsOut(uint256 amountIn, address[] memory path) external  returns (uint256[] memory amounts);
}

interface AutomaticMarketMaker {
	function calculatePurchaseReturn(uint256 etherAmount) external returns (uint256);
	function buy(uint256 _tokenAmount) external payable;
	function sell(uint256 tokenAmount, uint256 _etherAmount) external;
	function withdrawPayments(address payable payee) external;
}

contract SealedSwapper is Ownable {

	IBPool public bpt;
	IUniswapV2Router02 public uniswapRouter;
	AutomaticMarketMaker public AMM;
	Vault public sdeaVault;
	SealedToken public sdeus;
	SealedToken public sdea;
	SealedToken public sUniDD;
	SealedToken public sUniDE;
	SealedToken public sUniDU;
	address dea;
	address deus;
	address usdc;
	address uniDD;
	address uniDU;
	address uniDE;
	
	uint256 MAX_INT = type(uint256).max;

	constructor (
			address _uniswapRouter,
			address _bpt,
			address _amm,
			address _sdeaVault,
			address _dea,
			address _deus,
			address _usdc,
			address _uniDD,
			address _uniDE,
			address _uniDU
		) {

		uniswapRouter = IUniswapV2Router02(_uniswapRouter);
		bpt = IBPool(_bpt);
		AMM = AutomaticMarketMaker(_amm);

		sdeaVault = Vault(_sdeaVault);

		dea = _dea;
		deus = _deus;
		usdc = _usdc;
		uniDD = _uniDD;
		uniDU = _uniDU;
		uniDE = _uniDE;

	}
	
	function init(
		address _sdea,
		address _sdeus,
		address _sUniDD,
		address _sUniDE,
		address _sUniDU
	) external {
		sdea = SealedToken(_sdea);
		sdeus = SealedToken(_sdeus);
		sUniDD = SealedToken(_sUniDD);
		sUniDE = SealedToken(_sUniDE);
		sUniDU = SealedToken(_sUniDU);
		IERC20(dea).approve(address(uniswapRouter), MAX_INT);
		IERC20(deus).approve(address(uniswapRouter), MAX_INT);
		IERC20(usdc).approve(address(uniswapRouter), MAX_INT);
		IERC20(uniDD).approve(address(uniswapRouter), MAX_INT);
		IERC20(uniDE).approve(address(uniswapRouter), MAX_INT);
		IERC20(uniDU).approve(address(uniswapRouter), MAX_INT);
	}

	function approve(address token, address recipient, uint256 amount) external onlyOwner {
		IERC20(token).approve(recipient, amount);
	}

	function changeBPT(address _bpt) external onlyOwner {
		bpt = IBPool(_bpt);
	}

	function changeAMM(address _amm) external onlyOwner {
		AMM = AutomaticMarketMaker(_amm);
	}

	function bpt2eth(address tokenOut, uint256 poolAmountIn, uint256[] memory minAmountsOut, address[] memory path) public {
		bpt.transferFrom(msg.sender, address(this), poolAmountIn);
		uint256 deaAmount = bpt.exitswapPoolAmountIn(tokenOut, poolAmountIn, minAmountsOut[0]);
		uint256 deusAmount = uniswapRouter.swapExactTokensForTokens(deaAmount, minAmountsOut[1], path, address(this), block.timestamp + 1 days)[1];
		AMM.sell(deusAmount, minAmountsOut[2]);
		AMM.withdrawPayments(payable(msg.sender));
	}

	function bpt2Uni(address tokenOut, uint256 poolAmountIn, uint256[] memory minAmountsOut, address[] memory path) public {
		bpt.transferFrom(msg.sender, address(this), poolAmountIn);
		uint256 deaAmount = bpt.exitswapPoolAmountIn(tokenOut, poolAmountIn, minAmountsOut[0]);
		uniswapRouter.swapExactTokensForTokens(deaAmount, minAmountsOut[1], path, msg.sender, block.timestamp + 1 days);
	}

	function sdeus2sdea(uint256 amountIn, uint256 minAmountOut, address[] memory path) internal {
		sdeus.burn(msg.sender, amountIn);

		uint256 deaAmount = uniswapRouter.swapExactTokensForTokens(amountIn, minAmountOut, path, address(this), block.timestamp + 1 days)[1];
		uint256 sdeaAmount = sdeaVault.lockFor(deaAmount, msg.sender);

		sdea.transfer(msg.sender, sdeaAmount);
	}

	function bpt2sdea(address tokenOut, uint256 poolAmountIn, uint256 minAmountOut) public {
		bpt.transferFrom(msg.sender, address(this), poolAmountIn);

		uint256 deaAmount = bpt.exitswapPoolAmountIn(tokenOut, poolAmountIn, minAmountOut);
		uint256 sdeaAmount = sdeaVault.lockFor(deaAmount, msg.sender);

		sdea.transfer(msg.sender, sdeaAmount);
	}

	function bpt2sdea(
		uint256 poolAmountIn,
		uint256[] memory balancerMinAmountsOut,
		uint256 DDMinAmountsOut,
		uint256 sUniDDMinAmountsOut,
		uint256 sUniDEMinAmountsOut,
		uint256[] memory sUniDUMinAmountsOut,
		address[] memory DDPath,
		address[] memory sUniDDPath,
		address[] memory sUniDEPath,
		address[] memory sUniDUPath1,
		address[] memory sUniDUPath2
	) public {
		bpt.transferFrom(msg.sender, address(this), poolAmountIn);
		bpt.exitPool(poolAmountIn, balancerMinAmountsOut);

		sdeus2sdea(sdeus.balanceOf(address(this)), DDMinAmountsOut, DDPath);
		sUniDD2sdea(sUniDD.balanceOf(address(this)), sUniDDMinAmountsOut, sUniDDPath);
		sUniDE2sdea(sUniDE.balanceOf(address(this)), sUniDEMinAmountsOut, sUniDEPath);
		sUniDU2sdea(sUniDU.balanceOf(address(this)), sUniDUMinAmountsOut, sUniDUPath1, sUniDUPath2);

		uint256 sdeaAmount = sdeaVault.lockFor(IERC20(dea).balanceOf(address(this)), msg.sender);

		sdea.transfer(msg.sender, sdeaAmount);
	}

	function minAmountsCalculator(uint256 univ2Amount, uint256 totalSupply, uint256 reserve1, uint256 reserve2) pure internal returns(uint256, uint256) {
		return (((univ2Amount/1e5) /  totalSupply * reserve1) * 95 / 100, ((univ2Amount/1e5) / totalSupply * reserve2) * 95 / 100);
	}
	
	function sUniDD2sdea(uint256 sUniDDAmount, uint256 minAmountOut, address[] memory path) public {
		sUniDD.burn(msg.sender, sUniDDAmount);

		uint256 totalSupply = IERC20(uniDD).totalSupply();
		(uint256 deusReserve, uint256 deaReserve, ) = IUniswapV2Pair(uniDD).getReserves();

		(uint256 deusMinAmountOut, uint256 deaMinAmountOut) = minAmountsCalculator(sUniDDAmount, totalSupply, deusReserve, deaReserve);
		(uint256 deusAmount, uint256 deaAmount) = uniswapRouter.removeLiquidity(deus, dea, sUniDDAmount, deusMinAmountOut, deaMinAmountOut, address(this), block.timestamp + 1 days);

		uint256 deaAmount2 = uniswapRouter.swapExactTokensForTokens(deusAmount, minAmountOut, path, address(this), block.timestamp + 1 days)[1];

		uint256 sdeaAmount = sdeaVault.lockFor(deaAmount + deaAmount2, msg.sender);

		sdea.transfer(msg.sender, sdeaAmount);
	}

	// function sUniDU2sdea() public {
		
	// }
	

	function sUniDU2sdea(uint256 sUniDUAmount, uint256[] memory minAmountsOut, address[] memory path1, address[] memory path2) public {
		sUniDU.burn(msg.sender, sUniDUAmount);

		uint256 totalSupply = IERC20(uniDU).totalSupply();
		(uint256 deaReserve, uint256 usdcReserve, ) = IUniswapV2Pair(uniDU).getReserves();
		
		(uint256 deaMinAmountOut, uint256 usdcMinAmountOut) = minAmountsCalculator(sUniDUAmount/1e5, totalSupply, deaReserve, usdcReserve);
		(uint256 deaAmount, uint256 usdcAmount) = uniswapRouter.removeLiquidity(dea, usdc, (sUniDUAmount/1e5), deaMinAmountOut, usdcMinAmountOut, address(this), block.timestamp + 1 days);


		uint256 ethAmount = uniswapRouter.swapExactTokensForETH(usdcAmount, minAmountsOut[0], path1, address(this), block.timestamp + 1 days)[1];

		uint256 deusAmount = AMM.calculatePurchaseReturn(ethAmount);
		AMM.buy{value: ethAmount}(deusAmount);
		
		uint256 deaAmount2 = uniswapRouter.swapExactTokensForTokens(deusAmount, minAmountsOut[1], path2, address(this), block.timestamp + 1 days)[1];

		uint256 sdeaAmount = sdeaVault.lockFor(deaAmount + deaAmount2, msg.sender);

		sdea.transfer(msg.sender, sdeaAmount);
	}

	// function sUniDE2sdea() public {
		
	// }

	function sUniDE2sdea(uint256 sUniDEAmount, uint256 minAmountOut, address[] memory path) public {
		sUniDE.burn(msg.sender, sUniDEAmount);

		uint256 totalSupply = IERC20(uniDE).totalSupply();
		(uint256 deusReserve, uint256 wethReserve, ) = IUniswapV2Pair(uniDE).getReserves();
		(uint256 deusMinAmountOut, uint256 ethMinAmountOut) = minAmountsCalculator(sUniDEAmount, totalSupply, deusReserve, wethReserve);
		(uint256 deusAmount, uint256 ethAmount) = uniswapRouter.removeLiquidityETH(deus, sUniDEAmount, deusMinAmountOut, ethMinAmountOut, address(this), block.timestamp + 1 days);
		uint256 deusAmount2 = AMM.calculatePurchaseReturn(ethAmount);
		AMM.buy{value: ethAmount}(deusAmount2);
		uint256 deaAmount = uniswapRouter.swapExactTokensForTokens(deusAmount + deusAmount2, minAmountOut, path, address(this), block.timestamp + 1 days)[1];

		uint256 sdeaAmount = sdeaVault.lockFor(deaAmount, msg.sender);

		sdea.transfer(msg.sender, sdeaAmount);
	}

	function withdraw(address token, uint256 amount, address to) public onlyOwner {
		IERC20(token).transfer(to, amount);
	}

	receive() external payable {}
}

// Dar panahe Khoda