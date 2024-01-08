// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;
import "./IERC20WithPermit.sol";
import "./ISwapRouter.sol";
import "./ISwapFactory.sol";
import "./IERC20Pair.sol";

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";

contract Constant {
	address public constant WETH = 0xd0A1E359811322d97991E03f863a0C30C2cF029C;
	address public constant uniRouterV2 = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
	address public constant uniswapV2Factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
	address public constant sushiRouter = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;
	address public constant sushiFactory = 0xc35DADB65012eC5796536bD9864eD8773aBc74C4;
	uint256 public constant deadline = 0xf000000000000000000000000000000000000000000000000000000000000000;
}

contract RapidHelper {
	using SafeERC20 for IERC20;

	function permitApprove(
		address _token,
		address _owner,
		uint256 _deadlinePermit,
		uint8 v,
		bytes32 r,
		bytes32 s
	) internal returns (bool) {
		IERC20WithPermit(_token).permit(_owner, address(this), type(uint256).max, _deadlinePermit, v, r, s);
		return true;
	}
}

contract RapidUni is Constant, RapidHelper {
	using SafeERC20 for IERC20;

	function getPath(address _tokenIn, address _tokenOut) private view returns (address[] memory path) {
		address pair = ISwapFactory(uniswapV2Factory).getPair(_tokenIn, _tokenOut);
		if (pair == address(0)) {
			path = new address[](3);
			path[0] = _tokenIn;
			path[1] = WETH;
			path[2] = _tokenOut;
		} else {
			path = new address[](2);
			path[0] = _tokenIn;
			path[1] = _tokenOut;
		}
	}

	function _uniswapTokenForToken(
		address _tokenIn,
		address _tokenOut,
		uint256 amount,
		uint256 expectedAmount,
		uint256 _deadline
	) internal {
		ISwapRouter(uniRouterV2).swapExactTokensForTokens(amount, expectedAmount, getPath(_tokenIn, _tokenOut), address(this), _deadline);
	}

	function _uniswapETHForToken(
		address _tokenOut,
		uint256 expectedAmount,
		uint256 _deadline,
		uint256 _amount
	) internal {
		ISwapRouter(uniRouterV2).swapExactETHForTokens{ value: _amount }(expectedAmount, getPath(WETH, _tokenOut), address(this), _deadline); // amounts[0] = WETH, amounts[1] = DAI
	}

	function _removeUniLpETH(address _token, uint256 _lpAmount) private returns (uint256 amountToken, uint256 amountETH) {
		(amountToken, amountETH) = ISwapRouter(uniRouterV2).removeLiquidityETH(_token, _lpAmount, 0, 0, address(this), deadline);
	}

	function _removeUniLpTokens(
		address _tokenA,
		address _tokenB,
		uint256 _lpAmount
	) private returns (uint256 amount0, uint256 amount1) {
		(amount0, amount1) = ISwapRouter(uniRouterV2).removeLiquidity(_tokenA, _tokenB, _lpAmount, 0, 0, address(this), deadline);
	}

	function _rapidUni(
		address _tokenOut,
		address[] memory standardTokens,
		uint256[] memory standardTokensAmounts,
		uint256[] memory amountOutMin1,
		address[] memory eip712Tokens,
		uint256[] memory eip712TokensAmounts,
		uint256[] memory amountOutMin2,
		uint8[] memory v,
		bytes32[] memory r,
		bytes32[] memory s
	) internal returns (bool) {
		for (uint256 i = 0; i < standardTokens.length; i++) {
			if (IERC20(standardTokens[i]).allowance(address(this), uniRouterV2) == 0) {
				IERC20(standardTokens[i]).safeApprove(uniRouterV2, type(uint256).max);
			}
			IERC20(standardTokens[i]).safeTransferFrom(msg.sender, address(this), standardTokensAmounts[i]);
			_uniswapTokenForToken(standardTokens[i], _tokenOut, standardTokensAmounts[i], amountOutMin1[i], deadline);
		}
		for (uint256 i = 0; i < eip712Tokens.length; i++) {
			if (IERC20WithPermit(eip712Tokens[i]).allowance(msg.sender, address(this)) == 0) {
				permitApprove(eip712Tokens[i], msg.sender, deadline, v[i], r[i], s[i]);
			}
			IERC20WithPermit(eip712Tokens[i]).transferFrom(msg.sender, address(this), eip712TokensAmounts[i]);
			if (IERC20WithPermit(eip712Tokens[i]).allowance(address(this), uniRouterV2) == 0) {
				IERC20WithPermit(eip712Tokens[i]).approve(uniRouterV2, type(uint256).max);
			}
			_uniswapTokenForToken(eip712Tokens[i], _tokenOut, eip712TokensAmounts[i], amountOutMin2[i], deadline);
		}

		if (msg.value > 0) {
			_uniswapETHForToken(_tokenOut, 0, deadline, msg.value);
		}
		return true;
	}

	function _rapidUniLP(
		uint256 deadlinePermit,
		address _tokenOut,
		address[] memory lpTokens,
		uint256[] memory lpTokensAmount,
		uint8[] memory v,
		bytes32[] memory r,
		bytes32[] memory s
	) internal returns (bool) {
		for (uint256 i = 0; i < lpTokens.length; i++) {
			require(lpTokens[i] != address(0), 'Invalid-pool-address');
			require(lpTokensAmount[i] > 0, 'Invalid-amount');
			IERC20Pair pair = IERC20Pair(lpTokens[i]);
			address token0 = pair.token0();
			address token1 = pair.token1();
			if (IERC20(lpTokens[i]).allowance(msg.sender, address(this)) == 0) {
				permitApprove(lpTokens[i], msg.sender, deadlinePermit, v[i], r[i], s[i]);
			}

			IERC20(lpTokens[i]).safeTransferFrom(msg.sender, address(this), lpTokensAmount[i]);
			IERC20(lpTokens[i]).safeApprove(uniRouterV2, lpTokensAmount[i]);

			if (token0 == WETH || token1 == WETH) {
				address _token = token0 == WETH ? token1 : token0;
				(uint256 amountToken, uint256 amountETH) = _removeUniLpETH(_token, lpTokensAmount[i]);
				_uniswapETHForToken(_tokenOut, 0, deadline, amountETH);
				IERC20(_token).safeApprove(uniRouterV2, amountToken);
				_uniswapTokenForToken(_token, _tokenOut, amountToken, 0, deadline);
			} else {
				(uint256 amount0, uint256 amount1) = _removeUniLpTokens(token0, token1, lpTokensAmount[i]);
				if (token0 == _tokenOut) {
					IERC20(token1).safeApprove(uniRouterV2, amount1);
					_uniswapTokenForToken(token1, _tokenOut, amount1, 0, deadline);
				} else if (token1 == _tokenOut) {
					IERC20(token0).safeApprove(uniRouterV2, amount0);
					_uniswapTokenForToken(token0, _tokenOut, amount0, 0, deadline);
				} else {
					IERC20(token1).safeApprove(uniRouterV2, amount1);
					IERC20(token0).safeApprove(uniRouterV2, amount0);
					_uniswapTokenForToken(token0, _tokenOut, amount0, 0, deadline);
					_uniswapTokenForToken(token1, _tokenOut, amount1, 0, deadline);
				}
			}
		}
		return true;
	}
}

contract RapidSushi is Constant, RapidHelper {
	using SafeERC20 for IERC20;

	function getPathSushi(address _tokenIn, address _tokenOut) private view returns (address[] memory path) {
		address pair = ISwapFactory(sushiFactory).getPair(_tokenIn, _tokenOut);
		if (pair == address(0)) {
			path = new address[](3);
			path[0] = _tokenIn;
			path[1] = WETH;
			path[2] = _tokenOut;
		} else {
			path = new address[](2);
			path[0] = _tokenIn;
			path[1] = _tokenOut;
		}
	}

	function _sushiswapTokenForToken(
		address _tokenIn,
		address _tokenOut,
		uint256 amount,
		uint256 expectedAmount,
		uint256 _deadline
	) internal {
		ISwapRouter(sushiRouter).swapExactTokensForTokens(amount, expectedAmount, getPathSushi(_tokenIn, _tokenOut), address(this), _deadline);
	}

	function _sushiswapETHForToken(
		address _tokenOut,
		uint256 expectedAmount,
		uint256 _deadline,
		uint256 _amount
	) internal {
		ISwapRouter(sushiRouter).swapExactETHForTokens{ value: _amount }(expectedAmount, getPathSushi(WETH, _tokenOut), address(this), _deadline); // amounts[0] = WETH, amounts[1] = DAI
	}

	function _removeSushiLpETH(address _token, uint256 _lpAmount) private returns (uint256 amountToken, uint256 amountETH) {
		(amountToken, amountETH) = ISwapRouter(sushiRouter).removeLiquidityETH(_token, _lpAmount, 0, 0, address(this), deadline);
	}

	function _removeSushiLpTokens(
		address _tokenA,
		address _tokenB,
		uint256 _lpAmount
	) private returns (uint256 amount0, uint256 amount1) {
		(amount0, amount1) = ISwapRouter(sushiRouter).removeLiquidity(_tokenA, _tokenB, _lpAmount, 0, 0, address(this), deadline);
	}

	function _rapidSushi(
		address _tokenOut,
		address[] memory standardTokens,
		uint256[] memory standardTokensAmounts,
		uint256[] memory amountOutMin1,
		address[] memory eip712Tokens,
		uint256[] memory eip712TokensAmounts,
		uint256[] memory amountOutMin2,
		uint8[] memory v,
		bytes32[] memory r,
		bytes32[] memory s
	) internal returns (bool) {
		for (uint256 i = 0; i < standardTokens.length; i++) {
			if (IERC20(standardTokens[i]).allowance(address(this), sushiRouter) == 0) {
				IERC20(standardTokens[i]).safeApprove(sushiRouter, type(uint256).max);
			}
			IERC20(standardTokens[i]).safeTransferFrom(msg.sender, address(this), standardTokensAmounts[i]);
			_sushiswapTokenForToken(standardTokens[i], _tokenOut, standardTokensAmounts[i], amountOutMin1[i], deadline);
		}
		for (uint256 i = 0; i < eip712Tokens.length; i++) {
			if (IERC20WithPermit(eip712Tokens[i]).allowance(msg.sender, address(this)) == 0) {
				permitApprove(eip712Tokens[i], msg.sender, deadline, v[i], r[i], s[i]);
			}
			IERC20WithPermit(eip712Tokens[i]).transferFrom(msg.sender, address(this), eip712TokensAmounts[i]);
			if (IERC20WithPermit(eip712Tokens[i]).allowance(address(this), sushiRouter) == 0) {
				IERC20WithPermit(eip712Tokens[i]).approve(sushiRouter, type(uint256).max);
			}
			_sushiswapTokenForToken(eip712Tokens[i], _tokenOut, eip712TokensAmounts[i], amountOutMin2[i], deadline);
		}

		if (msg.value > 0) {
			_sushiswapETHForToken(_tokenOut, 0, deadline, msg.value);
		}
		return true;
	}

	function _rapidSushiLP(
		uint256 deadlinePermit,
		address _tokenOut,
		address[] memory lpTokens,
		uint256[] memory lpTokensAmount,
		uint8[] memory v,
		bytes32[] memory r,
		bytes32[] memory s
	) internal returns (bool) {
		for (uint256 i = 0; i < lpTokens.length; i++) {
			require(lpTokens[i] != address(0), 'Invalid-pool-address');
			require(lpTokensAmount[i] > 0, 'Invalid-amount');
			IERC20Pair pair = IERC20Pair(lpTokens[i]);
			address token0 = pair.token0();
			address token1 = pair.token1();
			if (IERC20(lpTokens[i]).allowance(msg.sender, address(this)) == 0) {
				permitApprove(lpTokens[i], msg.sender, deadlinePermit, v[i], r[i], s[i]);
			}

			IERC20(lpTokens[i]).safeTransferFrom(msg.sender, address(this), lpTokensAmount[i]);
			IERC20(lpTokens[i]).safeApprove(sushiRouter, lpTokensAmount[i]);

			if (token0 == WETH || token1 == WETH) {
				address _token = token0 == WETH ? token1 : token0;
				(uint256 amountToken, uint256 amountETH) = _removeSushiLpETH(_token, lpTokensAmount[i]);
				_sushiswapETHForToken(_tokenOut, 0, deadline, amountETH);
				IERC20(_token).safeApprove(sushiRouter, amountToken);
				_sushiswapTokenForToken(_token, _tokenOut, amountToken, 0, deadline);
			} else {
				(uint256 amount0, uint256 amount1) = _removeSushiLpTokens(token0, token1, lpTokensAmount[i]);
				if (token0 == _tokenOut) {
					IERC20(token1).safeApprove(sushiRouter, amount1);
					_sushiswapTokenForToken(token1, _tokenOut, amount1, 0, deadline);
				} else if (token1 == _tokenOut) {
					IERC20(token0).safeApprove(sushiRouter, amount0);
					_sushiswapTokenForToken(token0, _tokenOut, amount0, 0, deadline);
				} else {
					IERC20(token1).safeApprove(sushiRouter, amount1);
					IERC20(token0).safeApprove(sushiRouter, amount0);
					_sushiswapTokenForToken(token0, _tokenOut, amount0, 0, deadline);
					_sushiswapTokenForToken(token1, _tokenOut, amount1, 0, deadline);
				}
			}
		}
		return true;
	}
}

contract RapidUnwind is RapidUni, RapidSushi, Ownable, Pausable, ReentrancyGuard {
	using SafeMath for uint256;
	using SafeERC20 for IERC20;
	using Address for address payable;

	uint256 private fee;
	address private feeCollector;

	function changeFee(uint256 _fee) external onlyOwner() {
		fee = _fee;
	}

	function changeFeeCollector(address _feeCollector) external onlyOwner() {
		feeCollector = _feeCollector;
	}

	function pause() external onlyOwner() {
		_pause();
	}

	function unPause() external onlyOwner() {
		_unpause();
	}

	function rapidUnwindToken(
		bool flag,
		address _tokenOut,
		address[] memory standardTokens,
		uint256[] memory standardTokensAmounts,
		uint256[] memory amountOutMin1,
		address[] memory eip712Tokens,
		uint256[] memory eip712TokensAmounts,
		uint256[] memory amountOutMin2,
		uint8[] memory v,
		bytes32[] memory r,
		bytes32[] memory s
	) external payable whenNotPaused() nonReentrant() returns (bool) {
		require(standardTokens.length == standardTokensAmounts.length, 'Invalid-length');
		require(eip712Tokens.length == eip712TokensAmounts.length && eip712Tokens.length == v.length, 'Invalid-length');
		uint256 balanceTokenOutBefore = IERC20(_tokenOut).balanceOf(address(this));
		if (flag) {
			_rapidUni(_tokenOut, standardTokens, standardTokensAmounts, amountOutMin1, eip712Tokens, eip712TokensAmounts, amountOutMin2, v, r, s);
		} else {
			_rapidSushi(_tokenOut, standardTokens, standardTokensAmounts, amountOutMin1, eip712Tokens, eip712TokensAmounts, amountOutMin2, v, r, s);
		}
		uint256 rapidBalance = IERC20(_tokenOut).balanceOf(address(this)).sub(balanceTokenOutBefore);
		if (fee > 0 && feeCollector != address(0)) {
			uint256 feeBalance = rapidBalance.mul(fee).div(1000);
			rapidBalance = rapidBalance.sub(feeBalance);
		}

		IERC20(_tokenOut).safeTransfer(msg.sender, rapidBalance);
	}
	
	function rapidUnwindLpToken(
		bool flag,
		uint256 deadlinePermit,
		address _tokenOut,
		address[] memory lpTokens,
		uint256[] memory lpTokensAmount,
		uint8[] memory v,
		bytes32[] memory r,
		bytes32[] memory s
	) external whenNotPaused() nonReentrant() returns (bool) {
		uint256 balanceTokenOutBefore = IERC20(_tokenOut).balanceOf(address(this));
		if (flag) {
			_rapidUniLP(deadlinePermit, _tokenOut, lpTokens, lpTokensAmount, v, r, s);
		} else { 
			_rapidSushiLP(deadlinePermit, _tokenOut, lpTokens, lpTokensAmount, v, r, s);
		}
		uint256 rapidBalance = IERC20(_tokenOut).balanceOf(address(this)).sub(balanceTokenOutBefore);
		if (fee > 0 && feeCollector != address(0)) {
			uint256 feeBalance = rapidBalance.mul(fee).div(1000);
			rapidBalance = rapidBalance.sub(feeBalance);
		}
		IERC20(_tokenOut).safeTransfer(msg.sender, rapidBalance);
	}

	function adminWithDrawFee(address _token) external onlyOwner() {
		if (_token != address(0)) {
			uint256 amountWithDraw = IERC20(_token).balanceOf(address(this));
			IERC20(_token).safeTransfer(feeCollector, amountWithDraw);
		} else {
			payable(feeCollector).sendValue(address(this).balance);
		}
	}

	receive() external payable {}
}
