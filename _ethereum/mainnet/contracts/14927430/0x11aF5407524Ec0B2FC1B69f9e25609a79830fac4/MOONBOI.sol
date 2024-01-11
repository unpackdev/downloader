// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./Ownable.sol";
import "./ERC721A.sol";

contract MOONBOI is ERC721A, Ownable {
    
    //private
    string private baseURI = "ipfs://QmWFfAPEiZba73SWECKtJMYXXAb811AaX21F7DvvgekqoJ/";
     
	// Public Variables
	bool public started = false;
	uint256 public constant MAX_SUPPLY = 6969;
	uint256 public constant MAX_MINT = 2;
	
	mapping(address => uint256) public addressClaimed;
    
    constructor() ERC721A("moonbois.wtf", "MOONBOI") {}
    
	// Start tokenid at 1 instead of 0
	function _startTokenId() internal view virtual override returns (uint256) {
		return 1;
	}

	function mint(uint256 quantity) external {
		require(started, "IT IS STILL DAY");
		require(quantity > 0, "CAN'T HAVE 0 MOONS");
		require(addressClaimed[_msgSender()]+quantity <= MAX_MINT, "TOO MANY MOONS IN YOUR POCKET");
		require(totalSupply()+quantity <= MAX_SUPPLY, "NO MOONS LEFT");
		// mint
		addressClaimed[_msgSender()] += quantity;
		_safeMint(msg.sender, quantity);
	}
	
	function setBaseURI(string memory baseURI_) external onlyOwner {
		baseURI = baseURI_;
	}

	function _baseURI() internal view virtual override returns (string memory) {
		return baseURI;
	}

	function enableMint(bool mintStarted) external onlyOwner {
		started = mintStarted;
	}

 	function checkIfClaimed(address _owner) public view returns (uint256){
		return addressClaimed[_owner];
	}
}