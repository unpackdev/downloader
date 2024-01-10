pragma solidity ^0.6.12;

import "IERC20.sol";
import "Ownable.sol";

contract TokenSwapper is Ownable {

	IERC20 public constant WGK = IERC20(0xB14b87790643D2dAB44b06692D37Dd95B4b30E56);
	IERC20 public constant WGKV2 = IERC20(0xE8F7C65A6e6f9bF2a4df751dfa54B2563F44b409);

	function fetchV2() external onlyOwner {
		WGKV2.transfer(msg.sender, WGKV2.balanceOf(address(this)));
	}

	function fetch() external onlyOwner {
		WGK.transfer(msg.sender, WGK.balanceOf(address(this)));
	}

	function swap() external {
		uint256 balanceOf = WGK.balanceOf(msg.sender);
		WGK.transferFrom(msg.sender, address(this), balanceOf);
		WGKV2.transfer(msg.sender, balanceOf);
	}
}