//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/*
  .----------------.  .----------------.  .-----------------. .----------------.  .----------------.
| .--------------. || .--------------. || .--------------. || .--------------. || .--------------. |
| |   ______     | || |     ____     | || | ____  _____  | || | _____  _____ | || |    _______   | |
| |  |_   _ \    | || |   .'    `.   | || ||_   \|_   _| | || ||_   _||_   _|| || |   /  ___  |  | |
| |    | |_) |   | || |  /  .--.  \  | || |  |   \ | |   | || |  | |    | |  | || |  |  (__ \_|  | |
| |    |  __'.   | || |  | |    | |  | || |  | |\ \| |   | || |  | '    ' |  | || |   '.___`-.   | |
| |   _| |__) |  | || |  \  `--'  /  | || | _| |_\   |_  | || |   \ `--' /   | || |  |`\____) |  | |
| |  |_______/   | || |   `.____.'   | || ||_____|\____| | || |    `.__.'    | || |  |_______.'  | |
| |              | || |              | || |              | || |              | || |              | |
| '--------------' || '--------------' || '--------------' || '--------------' || '--------------' |
 '----------------'  '----------------'  '----------------'  '----------------'  '----------------'
 */

interface ENSContract {
	function setName(string memory newName) external;
}
interface IERC20 {
	function transfer(address recipient, uint256 amount) external returns (bool);
}
interface IERC721 {
	function transferFrom(address from, address to, uint256 tokenId) external;
}

contract BonusBuidlGuidl {
	ENSContract public immutable ensContract = ENSContract(0xa58E81fe9b61B5c3fE2AFD33CF304c454AbFc7Cb);
	mapping(address => bool) public isOwner;

	// Events
	event EtherSent(address indexed recipient, uint256 amount, string reason);
	event ERC20Sent(address indexed tokenAddress, address indexed recipient, uint256 amount, string reason);
	event ERC721Sent(address indexed tokenAddress, address indexed recipient, uint256 tokenId, string reason);

	// Modifiers
	modifier onlyOwner() {
		require(isOwner[msg.sender], "Only the owner can call this function");
		_;
	}

	// Constructor
	constructor(address[] memory owners) {
		for (uint256 i = 0; i < owners.length; i++) {
			isOwner[owners[i]] = true;
		}
	}

	function updateOwner(address _owner, bool _isOwner) onlyOwner public {
		require(_owner != msg.sender, "You cannot remove yourself as an owner");
		isOwner[_owner] = _isOwner;
	}

	function sendEther(address payable recipient, uint256 amount, string memory reason) onlyOwner public {
		(bool success,) = recipient.call{value: amount}("");
		require(success, "Failed to send Ether");
		emit EtherSent(recipient, amount, reason);
	}

	function transferERC20(address tokenAddress, address recipient, uint256 amount, string memory reason) onlyOwner public {
		require(IERC20(tokenAddress).transfer(recipient, amount), "Failed to send ERC20");
		emit ERC20Sent(tokenAddress, recipient, amount, reason);
	}

	function transferERC721(address tokenAddress, address recipient, uint256 tokenId, string memory reason) onlyOwner public {
		IERC721(tokenAddress).transferFrom(address(this), recipient, tokenId);
		emit ERC721Sent(tokenAddress, recipient, tokenId, reason);
	}

	// Set the reverse ENS name
	function setName(string memory newName) onlyOwner public {
		ensContract.setName(newName);
	}

	receive() external payable {}
}
