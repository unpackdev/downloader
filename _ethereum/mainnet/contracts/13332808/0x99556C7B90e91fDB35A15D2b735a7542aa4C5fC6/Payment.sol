// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

import "./IWETH.sol";

abstract contract Payment is Ownable {
	using SafeMath for uint;
	using SafeERC20 for IERC20;
	using Address for address payable;

	address public immutable WETH_;

	receive() external payable {}

	constructor(address _WETH) {
		WETH_ = _WETH;
	}

	function balanceOf(address token) internal view returns (uint bal) {
		bal = IERC20(token).balanceOf(address(this));
	}

	function pay(address token, uint amount) internal {
		if (amount == 0) revert('I_A'); // invalid amount
		if (token == address(0)) IWETH(WETH_).deposit{value: amount.mul(1999).div(2000)}();
		else IERC20(token).safeTransferFrom(_msgSender(), address(this), amount);
	}

	function refund(address token, uint amount) internal {
		if (amount == 0) return;
		if (token == address(0)) {
			if (balanceOf(WETH_) > 0) IWETH(WETH_).withdraw(balanceOf(WETH_));
			payable(_msgSender()).sendValue(amount);
		} else {
			IERC20(token).safeTransfer(_msgSender(), amount);
		}
	}

	function collectETH() public returns (uint amount) {
		if (balanceOf(WETH_) > 0) IWETH(WETH_).withdraw(balanceOf(WETH_));
		if ((amount = address(this).balance) > 0) payable(owner()).sendValue(amount);
	}

	function collectTokens(address token) public returns (uint amount) {
		if (token == address(0)) amount = collectETH();
		else if ((amount = balanceOf(token)) > 0) IERC20(token).safeTransfer(owner(), amount);
	}
}
