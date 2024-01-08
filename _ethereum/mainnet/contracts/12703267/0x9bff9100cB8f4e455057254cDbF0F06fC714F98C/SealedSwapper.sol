// Be Name KHODA
// Bime Abolfazl

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./AccessControl.sol";
import "./ReentrancyGuard.sol";


interface IBPool {
	function totalSupply() external view returns (uint);
	function exitPool(uint poolAmountIn, uint[] calldata minAmountsOut) external;
	function exitswapPoolAmountIn(address tokenOut, uint256 poolAmountIn, uint256 minAmountOut) external returns (uint256 tokenAmountOut);
	function transferFrom(address src, address dst, uint256 amt) external returns (bool);
}

interface IERC20 {
	function approve(address dst, uint256 amt) external returns (bool);
	function totalSupply() external view returns (uint);
	function burn(address from, uint256 amount) external;
	function transfer(address recipient, uint256 amount) external returns (bool);
	function transferFrom(address src, address dst, uint256 amt) external returns (bool);
	function balanceOf(address owner) external view returns (uint);
}

interface Vault {
	function lockFor(uint256 amount, address _user) external returns (uint256);
}

interface IUniswapV2Pair {
	function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
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

	function getAmountsOut(uint256 amountIn, address[] memory path) external view returns (uint256[] memory amounts);
}

interface AutomaticMarketMaker {
	function calculateSaleReturn(uint256 tokenAmount) external view returns (uint256);
	function calculatePurchaseReturn(uint256 etherAmount) external view returns (uint256);
	function buy(uint256 _tokenAmount) external payable;
	function sell(uint256 tokenAmount, uint256 _etherAmount) external;
	function withdrawPayments(address payable payee) external;
}

contract SealedSwapper is AccessControl, ReentrancyGuard {

	bytes32 public constant ADMIN_SWAPPER_ROLE = keccak256("ADMIN_SWAPPER_ROLE");
	bytes32 public constant TRUSTY_ROLE = keccak256("TRUSTY_ROLE");
	
	IBPool public bpt;
	IUniswapV2Router02 public uniswapRouter;
	AutomaticMarketMaker public AMM;
	Vault public sdeaVault;
	address public sdeus;
	address public sdea;
	address public sUniDD;
	address public sUniDE;
	address public sUniDU;
	address public dea;
	address public deus;
	address public usdc;
	address public uniDD;
	address public uniDU;
	address public uniDE;

	address[] public usdc2wethPath =  [0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2];
	address[] public deus2deaPath =  [0x3b62F3820e0B035cc4aD602dECe6d796BC325325, 0x80aB141F324C3d6F2b18b030f1C4E95d4d658778];
	

	uint256 public MAX_INT = type(uint256).max;
	uint256 public scale = 1e18;
	uint256 public DDRatio;
	uint256 public DERatio;
	uint256 public DURatio;
	uint256 public deusRatio;
	uint256 public DUVaultRatio;

	event Swap(address user, address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOut);

	constructor (
		address _uniswapRouter,
		address _bpt,
		address _amm,
		address _sdeaVault,
		uint256 _DERatio,
		uint256 _DURatio,
		uint256 _DDRatio,
		uint256 _deusRatio,
		uint256 _DUVaultRatio
	) ReentrancyGuard() {
		_setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
		_setupRole(TRUSTY_ROLE, msg.sender);
		uniswapRouter = IUniswapV2Router02(_uniswapRouter);
		bpt = IBPool(_bpt);
		AMM = AutomaticMarketMaker(_amm);
		sdeaVault = Vault(_sdeaVault);
		DDRatio = _DDRatio;
		DURatio = _DURatio;
		DERatio = _DERatio;
		deusRatio = _deusRatio;
		DUVaultRatio = _DUVaultRatio;
	}
	
	function init(
		address _sdea,
		address _sdeus,
		address _sUniDD,
		address _sUniDE,
		address _sUniDU,
		address _dea,
		address _deus,
		address _usdc,
		address _uniDD,
		address _uniDU,
		address _uniDE
	) external {
		require(hasRole(TRUSTY_ROLE, msg.sender), "SEALED_SWAPPER: Caller is not a TRUSTY");
		sdea = _sdea;
		sdeus = _sdeus;
		sUniDD = _sUniDD;
		sUniDE = _sUniDE;
		sUniDU = _sUniDU;
		dea = _dea;
		deus = _deus;
		usdc = _usdc;
		uniDD = _uniDD;
		uniDU = _uniDU;
		uniDE = _uniDE;
		IERC20(dea).approve(address(uniswapRouter), MAX_INT);
		IERC20(deus).approve(address(uniswapRouter), MAX_INT);
		IERC20(usdc).approve(address(uniswapRouter), MAX_INT);
		IERC20(uniDD).approve(address(uniswapRouter), MAX_INT);
		IERC20(uniDE).approve(address(uniswapRouter), MAX_INT);
		IERC20(uniDU).approve(address(uniswapRouter), MAX_INT);
		IERC20(dea).approve(address(sdeaVault), MAX_INT);
	}

	function setRatios(uint256 _DERatio, uint256 _DURatio, uint256 _DDRatio, uint256 _deusRatio, uint256 _DUVaultRatio) external {
		require(hasRole(TRUSTY_ROLE, msg.sender), "SEALED_SWAPPER: Caller is not a TRUSTY");
		DDRatio = _DDRatio;
		DURatio = _DURatio;
		DERatio = _DERatio;
		deusRatio = _deusRatio;
		DUVaultRatio = _DUVaultRatio;
	}

	function approve(address token, address recipient, uint256 amount) external {
		require(hasRole(TRUSTY_ROLE, msg.sender), "SEALED_SWAPPER: Caller is not a TRUSTY");
		IERC20(token).approve(recipient, amount);
	}

	function bpt2eth(uint256 poolAmountIn, uint256[] memory minAmountsOut) public nonReentrant() {
		bpt.transferFrom(msg.sender, address(this), poolAmountIn);
		uint256 deaAmount = bpt.exitswapPoolAmountIn(dea, poolAmountIn, minAmountsOut[0]);
		uint256 deusAmount = uniswapRouter.swapExactTokensForTokens(deaAmount, minAmountsOut[1], deus2deaPath, address(this), block.timestamp + 1 days)[1];
		uint256 ethAmount = AMM.calculateSaleReturn(deusAmount);
		AMM.sell(deusAmount, minAmountsOut[2]);
		AMM.withdrawPayments(payable(address(this)));
		payable(msg.sender).transfer(ethAmount);

		emit Swap(msg.sender, address(bpt), address(0), poolAmountIn, ethAmount);
	}

	function deus2dea(uint256 amountIn) internal returns(uint256) {
		return uniswapRouter.swapExactTokensForTokens(amountIn, 1, deus2deaPath, address(this), block.timestamp + 1 days)[1];
	}

	function bpt2sdea(uint256 poolAmountIn, uint256 minAmountOut) public nonReentrant() {
		bpt.transferFrom(msg.sender, address(this), poolAmountIn);

		uint256 deaAmount = bpt.exitswapPoolAmountIn(dea, poolAmountIn, minAmountOut);
		uint256 sdeaAmount = sdeaVault.lockFor(deaAmount, address(this));

		IERC20(sdea).transfer(msg.sender, sdeaAmount);
		emit Swap(msg.sender, address(bpt), sdea, poolAmountIn, sdeaAmount);
	}

	function sdea2dea(uint256 amount, address recipient) external nonReentrant() {
		require(hasRole(ADMIN_SWAPPER_ROLE, msg.sender), "SEALED_SWAPPER: Caller is not an ADMIN_SWAPPER");
		IERC20(sdea).burn(msg.sender, amount);
		IERC20(dea).transfer(recipient, amount);
		
		emit Swap(recipient, sdea, dea, amount, amount);
	}

	function sdeus2deus(uint256 amount, address recipient) external nonReentrant() {
		require(hasRole(ADMIN_SWAPPER_ROLE, msg.sender), "SEALED_SWAPPER: Caller is not an ADMIN_SWAPPER");
		IERC20(sdeus).burn(msg.sender, amount);
		IERC20(deus).transfer(recipient, amount);

		emit Swap(recipient, sdeus, deus, amount, amount);
	}

	function sUniDE2UniDE(uint256 amount, address recipient) external nonReentrant() {
		require(hasRole(ADMIN_SWAPPER_ROLE, msg.sender), "SEALED_SWAPPER: Caller is not an ADMIN_SWAPPER");
		IERC20(sUniDE).burn(msg.sender, amount);
		IERC20(uniDE).transfer(recipient, amount);

		emit Swap(recipient, sUniDE, uniDE, amount, amount);
	}

	function sUniDD2UniDD(uint256 amount, address recipient) external nonReentrant() {
		require(hasRole(ADMIN_SWAPPER_ROLE, msg.sender), "SEALED_SWAPPER: Caller is not an ADMIN_SWAPPER");
		IERC20(sUniDD).burn(msg.sender, amount);
		IERC20(uniDD).transfer(recipient, amount);

		emit Swap(recipient, sUniDD, uniDD, amount, amount);
	}

	function sUniDU2UniDU(uint256 amount, address recipient) external nonReentrant() {
		require(hasRole(ADMIN_SWAPPER_ROLE, msg.sender), "SEALED_SWAPPER: Caller is not an ADMIN_SWAPPER");
		IERC20(sUniDU).burn(msg.sender, amount);
		IERC20(uniDU).transfer(recipient, amount * DUVaultRatio / scale);

		emit Swap(recipient, sUniDU, uniDU, amount, amount * DUVaultRatio / scale);
	}

	function calcExitAmount(address token, uint256 Predeemed) public view returns(uint256) {
		uint256 Psupply = bpt.totalSupply();
		uint256 Bk = IERC20(token).balanceOf(address(bpt));
		return Bk - (((Psupply - Predeemed) * Bk) / Psupply);
	}

	function bpt2sdea(
		uint256 poolAmountIn,
		uint256[] memory balancerMinAmountsOut,
		uint256 minAmountOut
	) external nonReentrant() {
		bpt.transferFrom(msg.sender, address(this), poolAmountIn);
		uint256 deaAmount = calcExitAmount(dea, poolAmountIn);
		uint256 sdeaAmount = calcExitAmount(sdea, poolAmountIn);
		uint256 sdeusAmount = calcExitAmount(sdeus, poolAmountIn);
		uint256 sUniDDAmount = calcExitAmount(sUniDD, poolAmountIn);
		uint256 sUniDEAmount = calcExitAmount(sUniDE, poolAmountIn);
		uint256 sUniDUAmount = calcExitAmount(sUniDU, poolAmountIn);

		bpt.exitPool(poolAmountIn, balancerMinAmountsOut);

		IERC20(sdeus).burn(address(this), sdeusAmount);
		deaAmount += deus2dea(sdeusAmount * deusRatio / scale);

		IERC20(sUniDD).burn(address(this), sUniDDAmount);
		deaAmount += uniDD2dea(sUniDDAmount * DDRatio / scale);

		IERC20(sUniDE).burn(address(this), sUniDEAmount);
		deaAmount += uniDE2dea(sUniDEAmount * DERatio / scale);

		IERC20(sUniDU).burn(address(this), sUniDUAmount);
		deaAmount += uniDU2dea(sUniDUAmount * DURatio / scale);

		require(deaAmount >= minAmountOut, "SEALED_SWAPPER: INSUFFICIENT_OUTPUT_AMOUNT");

		sdeaVault.lockFor(deaAmount, address(this));
		IERC20(sdea).transfer(msg.sender, deaAmount + sdeaAmount);

		emit Swap(msg.sender, address(bpt), sdea, poolAmountIn, deaAmount + sdeaAmount);
	}



	function uniDD2dea(uint256 sUniDDAmount) internal returns(uint256) {
		(uint256 deusAmount, uint256 deaAmount) = uniswapRouter.removeLiquidity(deus, dea, sUniDDAmount, 1, 1, address(this), block.timestamp + 1 days);

		uint256 deaAmount2 = uniswapRouter.swapExactTokensForTokens(deusAmount, 1, deus2deaPath, address(this), block.timestamp + 1 days)[1];

		return deaAmount + deaAmount2;
	}

	function sUniDD2sdea(uint256 sUniDDAmount, uint256 minAmountOut) public nonReentrant() {
		IERC20(sUniDD).burn(msg.sender, sUniDDAmount);

		uint256 deaAmount = uniDD2dea(sUniDDAmount * DDRatio / scale);

		require(deaAmount >= minAmountOut, "SEALED_SWAPPER: INSUFFICIENT_OUTPUT_AMOUNT");
		sdeaVault.lockFor(deaAmount, address(this));
		IERC20(sdea).transfer(msg.sender, deaAmount);

		emit Swap(msg.sender, uniDD, sdea, sUniDDAmount, deaAmount);
	}


	function uniDU2dea(uint256 sUniDUAmount) internal returns(uint256) {
		(uint256 deaAmount, uint256 usdcAmount) = uniswapRouter.removeLiquidity(dea, usdc, (sUniDUAmount * DUVaultRatio / scale), 1, 1, address(this), block.timestamp + 1 days);

		uint256 ethAmount = uniswapRouter.swapExactTokensForETH(usdcAmount, 1, usdc2wethPath, address(this), block.timestamp + 1 days)[1];

		uint256 deusAmount = AMM.calculatePurchaseReturn(ethAmount);
		AMM.buy{value: ethAmount}(deusAmount);
		
		uint256 deaAmount2 = uniswapRouter.swapExactTokensForTokens(deusAmount, 1, deus2deaPath, address(this), block.timestamp + 1 days)[1];

		return deaAmount + deaAmount2;
	}
	

	function sUniDU2sdea(uint256 sUniDUAmount, uint256 minAmountOut) public nonReentrant() {
		IERC20(sUniDU).burn(msg.sender, sUniDUAmount);

		uint256 deaAmount = uniDU2dea(sUniDUAmount * DURatio / scale);

		require(deaAmount >= minAmountOut, "SEALED_SWAPPER: INSUFFICIENT_OUTPUT_AMOUNT");
		sdeaVault.lockFor(deaAmount, address(this));
		IERC20(sdea).transfer(msg.sender, deaAmount);
		
		emit Swap(msg.sender, uniDU, sdea, sUniDUAmount, deaAmount);
	}


	function uniDE2dea(uint256 sUniDEAmount) internal returns(uint256) {
		(uint256 deusAmount, uint256 ethAmount) = uniswapRouter.removeLiquidityETH(deus, sUniDEAmount, 1, 1, address(this), block.timestamp + 1 days);
		uint256 deusAmount2 = AMM.calculatePurchaseReturn(ethAmount);
		AMM.buy{value: ethAmount}(deusAmount2);
		uint256 deaAmount = uniswapRouter.swapExactTokensForTokens(deusAmount + deusAmount2, 1, deus2deaPath, address(this), block.timestamp + 1 days)[1];
		return deaAmount;
	}

	function sUniDE2sdea(uint256 sUniDEAmount, uint256 minAmountOut) public nonReentrant() {
		IERC20(sUniDE).burn(msg.sender, sUniDEAmount);

		uint256 deaAmount = uniDE2dea(sUniDEAmount * DERatio / scale);

		require(deaAmount >= minAmountOut, "SEALED_SWAPPER: INSUFFICIENT_OUTPUT_AMOUNT");
		sdeaVault.lockFor(deaAmount, address(this));
		IERC20(sdea).transfer(msg.sender, deaAmount);

		emit Swap(msg.sender, uniDE, sdea, sUniDEAmount, deaAmount);
	}

	function withdraw(address token, uint256 amount, address to) public {
		require(hasRole(TRUSTY_ROLE, msg.sender), "SEALED_SWAPPER: Caller is not a TRUSTY");
		IERC20(token).transfer(to, amount);
	}

	function withdrawEther(uint256 amount, address payable to) public {
		require(hasRole(TRUSTY_ROLE, msg.sender), "SEALED_SWAPPER: Caller is not a TRUSTY");
		to.transfer(amount);
	}
	
	receive() external payable {}
	
	//--------- View functions --------- //

	function minAmountCaculator(address pair, uint amount) public view returns(uint, uint) {
		(uint reserve1, uint reserve2, ) = IUniswapV2Pair(uniDD).getReserves();
		uint totalSupply = IERC20(pair).totalSupply();
		return (amount * reserve1 / totalSupply, amount * reserve2 / totalSupply);
	}

	function getBpt2SDeaAmount(uint poolAmountIn) public view returns(uint[6] memory, uint) {
		uint256 deaAmount = calcExitAmount(dea, poolAmountIn);
		uint256 sUniDDAmount = calcExitAmount(sUniDD, poolAmountIn);
		uint256 sUniDUAmount = calcExitAmount(sUniDU, poolAmountIn);
		uint256 sUniDEAmount = calcExitAmount(sUniDE, poolAmountIn);
		uint256 sdeaAmount = calcExitAmount(sdea, poolAmountIn);
		uint256 sdeusAmount = calcExitAmount(sdeus, poolAmountIn);

		sdeaAmount += deaAmount;
		sdeaAmount += getSUniDD2SDeaAmount(sUniDDAmount);
		sdeaAmount += getSUniDU2SDeaAmount(sUniDUAmount);
		sdeaAmount += getSUniDE2SDeaAmount(sUniDEAmount);
		sdeaAmount += uniswapRouter.getAmountsOut(sdeusAmount * deusRatio / scale, deus2deaPath)[1];

		return ([deaAmount, sUniDDAmount, sUniDUAmount, sUniDEAmount, sdeaAmount, sdeusAmount], sdeaAmount);
	}
	function getSUniDU2SDeaAmount(uint amountIn) public view returns(uint) {
		(uint deaAmount, uint usdcAmount) = minAmountCaculator(uniDU, (amountIn * DUVaultRatio / scale));
		uint ethAmount = uniswapRouter.getAmountsOut(usdcAmount, usdc2wethPath)[1];
		uint deusAmount = AMM.calculatePurchaseReturn(ethAmount);
		uint deaAmount2 = uniswapRouter.getAmountsOut(deusAmount, deus2deaPath)[1];
		return (deaAmount + deaAmount2) * DURatio / scale;
	}

	function getSUniDD2SDeaAmount(uint amountIn) public view returns(uint) {
		(uint deusAmount, uint deaAmount) = minAmountCaculator(uniDD, amountIn);
		uint deaAmount2 = uniswapRouter.getAmountsOut(deusAmount, deus2deaPath)[1];
		return (deaAmount + deaAmount2) * DDRatio / scale;
	}
	function getSUniDE2SDeaAmount(uint amountIn) public view returns(uint) {
		(uint deusAmount, uint ethAmount) = minAmountCaculator(uniDE, amountIn);
		uint deusAmount2 = AMM.calculatePurchaseReturn(ethAmount);
		uint deaAmount = uniswapRouter.getAmountsOut(deusAmount + deusAmount2, deus2deaPath)[1];
		return deaAmount * DERatio / scale;
	}
}

// Dar panahe Khoda