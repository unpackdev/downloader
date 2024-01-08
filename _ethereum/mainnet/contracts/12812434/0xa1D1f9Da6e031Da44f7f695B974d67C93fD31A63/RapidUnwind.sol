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
import "./Address.sol";

contract Constant {
	address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
	address public constant uniRouterV2 = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
	address public constant uniswapV2Factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
	address public constant sushiRouter = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;
	address public constant sushiFactory = 0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac;
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

	function getPath(address _tokenIn, address _tokenOut) private returns (address[] memory path) {
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
				IERC20(standardTokens[i]).approve(uniRouterV2, type(uint256).max);
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
}

contract RapidSushi is Constant, RapidHelper {
	using SafeERC20 for IERC20;

	function getPathSushi(address _tokenIn, address _tokenOut) private returns (address[] memory path) {
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
				IERC20(standardTokens[i]).approve(sushiRouter, type(uint256).max);
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
