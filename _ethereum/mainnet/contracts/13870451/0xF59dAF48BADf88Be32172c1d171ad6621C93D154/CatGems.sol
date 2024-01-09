// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./ERC20Burnable.sol";
import "./Ownable.sol";
import "./ERC20.sol";
import "./IERC721.sol";
import "./IERC1155.sol";
import "./ICatGems.sol";

contract CatGems is ICatGems, Context, ERC20, ERC20Burnable, Ownable {
	mapping(address => bool) controllers;

	event CAction(uint256 nftID, uint256 value, uint256 actionID, string payload);

	constructor() ERC20("CATGEMS", "CATGEMS") {}

	//usage of CatGems outside the blockchain
	function cAction(
		uint256 nftID,
		uint256 id,
		string memory what
	) external payable {
		emit CAction(nftID, msg.value, id, what);
	}

	function mint(address to, uint256 amount) external {
		require(controllers[msg.sender], "only controllers can mint");
		_mint(to, amount);
	}

	function burn(address from, uint256 amount) external {
		require(controllers[msg.sender], "only controllers can burn");
		_burn(from, amount);
	}

	function setController(address controller, bool isAllowed) external onlyOwner {
		controllers[controller] = isAllowed;
	}

	function transferFrom(
		address sender,
		address recipient,
		uint256 amount
	) public virtual override(ERC20, ICatGems) returns (bool) {
		// allow the transfer without approval. This saves gas and a transaction.
		// The sender address will still need to actually have the amount being attempted to send.
		if (controllers[_msgSender()]) {
			// NOTE: This will omit any events from being written. This saves additional gas,
			// and the event emission is not a requirement by the EIP
			// (read this function summary / ERC20 summary for more details)
			_transfer(sender, recipient, amount);
			return true;
		}
		// else allowance needed
		return super.transferFrom(sender, recipient, amount);
	}

	function reclaimERC20(IERC20 erc20Token) external onlyOwner {
		erc20Token.transfer(msg.sender, erc20Token.balanceOf(address(this)));
	}

	function reclaimERC721(IERC721 erc721Token, uint256 id) external onlyOwner {
		erc721Token.safeTransferFrom(address(this), msg.sender, id);
	}

	function reclaimERC1155(
		IERC1155 erc1155Token,
		uint256 id,
		uint256 amount
	) external onlyOwner {
		erc1155Token.safeTransferFrom(address(this), msg.sender, id, amount, "");
	}

	// earnings withdrawal
	function withdrawEarnings() public onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}
}
