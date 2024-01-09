// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./ERC20Burnable.sol";
import "./ERC20.sol";
import "./Ownable.sol";
import "./ITuna.sol";

/**
 * $TUNA is an utility token, with 0 economic value, used only in The Shark Mob NFT ecosystem.
 * mint, burn & transfer without approval is given to game contracts
 * transparent & full history at everyone's fingertips
 * maxSupply is capped at 100 million
 * there's no team distribution, no marketing reserves, no ICO, no partnerships or investors
 * no vesting, no giveaways and no presale and no liquidy pools creations done by the team
 */
contract Tuna is ITuna, Context, ERC20, ERC20Burnable, Ownable {
	mapping(address => bool) controllers;

	event CustomPay(uint256 nftID, uint256 value, uint256 actionID, string payload);

	constructor() ERC20("$TUNA", "$TUNA") {
		controllers[0xf9A45AD61b327b656508515dc66f6fa11908afcf] = true; //TUNA REWARDS
	}

	//usage of $TUNA outside the blockchain
	function customPay(
		uint256 nftID,
		uint256 id,
		string memory what
	) external payable {
		emit CustomPay(nftID, msg.value, id, what);
	}

	function setController(address controller, bool isAllowed) external onlyOwner {
		controllers[controller] = isAllowed;
	}

	function mint(address to, uint256 amount) external {
		require(totalSupply() < 100000000 ether, "over 100 mil");
		require(controllers[msg.sender], "only controllers can mint");
		_mint(to, amount);
	}

	function burn(address from, uint256 amount) external {
		require(controllers[msg.sender], "only controllers can burn");
		_burn(from, amount);
	}

	function transferFrom(
		address sender,
		address recipient,
		uint256 amount
	) public virtual override(ERC20, ITuna) returns (bool) {
		if (controllers[_msgSender()]) {
			_transfer(sender, recipient, amount);
			return true;
		}
		// else allowance needed
		return super.transferFrom(sender, recipient, amount);
	}
}
