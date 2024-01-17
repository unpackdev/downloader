// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./IERC1155.sol";
import "./IERC721.sol";
import "./IERC20.sol";

abstract contract Reclaimable is Ownable {

    function reclaimERC20(IERC20 token) external onlyOwner {
		require(address(token) != address(0));
		uint256 balance = token.balanceOf(address(this));
		token.transfer(msg.sender, balance);
	}

	function reclaimERC1155(IERC1155 erc1155Token, uint256 id) external onlyOwner {
		erc1155Token.safeTransferFrom(address(this), msg.sender, id, 1, "");
	}

	function reclaimERC721(IERC721 erc721Token, uint256 id) external onlyOwner {
		erc721Token.safeTransferFrom(address(this), msg.sender, id);
	}

	function reclaimETH() external onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}
}