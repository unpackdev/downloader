// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract GJMintPass is ERC20, Ownable, ReentrancyGuard {
	
	bool public saleClosed;
	uint256 public maxSupply;
	uint256 public price;
	uint256 public maxPerTransaction;
	address public authenticatedBurner;
	    
	constructor( 
		string memory name_, 
		string memory symbol_, 
		uint256 price_,
		uint256 maxSupply_,
		uint256 maxPerTransaction_) ERC20(name_, symbol_) {
		price = price_;
		maxSupply = maxSupply_;
		maxPerTransaction = maxPerTransaction_;
	}

	function isSoldOut() external view returns(bool) {
		return!(totalSupply() < maxSupply);
	}

	function setBurner(address newBurnerAddress_) external onlyOwner {
		authenticatedBurner = newBurnerAddress_;
	}

	function burnFrom(address from, uint256 amount) external nonReentrant {
		require(authenticatedBurner != address(0), "Burner not configured");
		require(msg.sender == authenticatedBurner, "Not authorised");
		require(balanceOf(from) >= amount, "Not enough to burn");
		require(amount > 0, "Amount must be over 0");
		super._burn(from, amount);
	}


	function mint(uint256 amount) external payable {
		require(!saleClosed, "Mint pass closed");
		require((totalSupply()+amount) <= maxSupply, "Minting will exceed maximum supply");
		require(amount > 0, "Mint more than zero");
		require(amount <= maxPerTransaction, "Mint amount too high");
		require(amount % 1 ether == 0, "Mint only whole tokens");
		require(msg.value >= ((price * amount) / 1 ether), "Sent eth incorrect"); // amount should always be whole ether values
		_mint(msg.sender, amount);
	}

	function withdraw(address treasury) external payable onlyOwner nonReentrant {
		payable(treasury).transfer(address(this).balance);
	}

	function closeSale() external onlyOwner {
		saleClosed = true;
	}

	/**
	* @dev to receive remaining eth from the link exchange
	*/
    receive() external payable {}
}