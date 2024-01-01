// SPDX-License-Identifier: MIT

pragma solidity 0.8.1;

import "./Address.sol";
import "./Ownable.sol";
import "./IERC20.sol";

interface IToken is IERC20 {
	function openTrading() external;
	function transferOwnership(address) external;
}

interface IStaking {
	function withdraw() external;
}

contract Launcher is Ownable {
	IToken public token;
	IStaking public staking;

	constructor(IToken token_, IStaking staking_) {
		token = token_;
		staking = staking_;
	}

	function launch() external onlyOwner {
		token.openTrading();
		uint balance = token.balanceOf(address(this));
		token.transfer(address(staking), balance);
		token.transferOwnership(owner());
	}

	function recoverTokenOwnership() external onlyOwner {
		token.transferOwnership(owner());
	}

	function withdraw() external onlyOwner {
		staking.withdraw();
	}

	function claimERC20(IERC20 erc20) external onlyOwner {
		uint balanceToken = erc20.balanceOf(address(this));
		erc20.transfer(owner(), balanceToken);
	}

	function claimETH() external onlyOwner {
		uint balanceETH = address(this).balance;
		Address.sendValue(payable(owner()), balanceETH);
	}

	function twitter() external view returns (string memory) {
		return "https://twitter.com/StakingAI";
	}

	receive() external payable {}
}
