//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20Metadata.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract MigrationHelper is Ownable {
	using SafeERC20 for IERC20Metadata;
	using SafeMath for uint256;

	address public oldTokenAddress;
	address public newTokenAddress;

	uint256 public divider = 100;
	uint256 public dividerDenominator = 100;

	uint256 newAmountToReceive;
	uint256 oldAmount;

	event Claim(address indexed address_, uint256 amount);

	constructor() Ownable(){
	}

	function setOldTokenAddress(address oldTokenAddress_) external onlyOwner {
		require(oldTokenAddress_ != address(0));
		oldTokenAddress = oldTokenAddress_;
	}

	function setDivider(uint256 divider_) external onlyOwner {
		require(divider_ != 0);
		divider = divider_;
	}

	function setNewTokenAddress(address newTokenAddress_) external onlyOwner {
		require(newTokenAddress_ != address(0));
		newTokenAddress = newTokenAddress_;
	}

	function claim(uint256 balance) public {
		require(IERC20Metadata(oldTokenAddress).balanceOf(msg.sender) >= balance, "Insufficient funds");

		IERC20Metadata(oldTokenAddress).safeTransferFrom(msg.sender, address(this), balance);
		setNewAmountToReceive(balance);
		IERC20Metadata(newTokenAddress).safeTransfer(msg.sender, newAmountToReceive);

		emit Claim(msg.sender, newAmountToReceive);
	}

	function setNewAmountToReceive(uint256 _balance) private {
		uint256 decimalsOldToken = IERC20Metadata(oldTokenAddress).decimals();
		uint256 decimalsNewToken = IERC20Metadata(newTokenAddress).decimals();
		
		newAmountToReceive = _balance.div(10**decimalsOldToken).mul(10**decimalsNewToken).mul(dividerDenominator).div(divider);
	}

	function withdrawToken(address tokenAddress_, address to_, uint256 amount) external onlyOwner{
		IERC20Metadata(tokenAddress_).safeTransfer(to_, amount);
	}
}
