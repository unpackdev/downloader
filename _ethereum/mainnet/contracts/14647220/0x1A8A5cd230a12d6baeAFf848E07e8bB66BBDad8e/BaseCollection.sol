// SPDX-License-Identifier: AGPL-3.0-or-later


pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";

contract BaseCollection is Ownable, ERC721A, ReentrancyGuard {
	
    using Strings for uint256;

	uint256 devReserve;
	bool initialized;
	
	uint256 public price = 0.033 ether;
	uint256 public maxSupply;
	
	address feeCollector;
	
	constructor(
		string memory name_, 
		string memory symbol_, 
		uint256 collectionSize_
	) ERC721A(
		name_, 
		symbol_, 
		100, 
		collectionSize_) {
			maxSupply = collectionSize_;
		}
	
	function initialize(uint256 reserveAmount, string calldata unrevealedURI) external onlyOwner{
		require(!initialized, "only initialized once");
		initialized = true;
		devReserve = reserveAmount;
		_unrevealedURI = unrevealedURI;
	}

	function mint(uint amount) external nonReentrant payable{
		require(msg.value == price * amount, "Price not correct");
		_mintTo(msg.sender, amount);
	}

	function mintFor(address account, uint amount)external nonReentrant payable{
		require(msg.value == price * amount, "Price not correct");
		_mintTo(account, amount);
	}
	
	//unlimited mint amount
	function _mintTo(address account, uint amount) internal{
		require(totalSupply() + devReserve + amount <= maxSupply, "Reached max supply");
		_safeMint(account, amount);
	}
	
	// batch airdrop optimization
	function devMint(address[] calldata _addr, uint256[] calldata amount) external onlyOwner{
		uint256 i;
		uint256 addrLen = _addr.length;
		uint256 batchTotal = 0;
        for (i = 0; i < addrLen;){
            batchTotal += amount[i];
			unchecked{ ++i;}
		}
		require(batchTotal <= devReserve, "All reserve minted.");
		require(totalSupply() + batchTotal <= collectionSize, "Reached max supply");
		devReserve -= batchTotal;
		for (i = 0; i < addrLen;){
			if(amount[i] >0) _safeMint(_addr[i], amount[i]);
			unchecked{ ++i;}
		}
	}
	
	function withdraw() external {
		uint256 balance = address(this).balance;
        (bool sent,) = feeCollector.call{value: balance}("");
        require(sent, "Failed to send Ether");
    }
	
	function setFeeCollector(address _newAddr) external onlyOwner{
		feeCollector = _newAddr;
	}

	function setPrice(uint newPrice) external onlyOwner{
		require(newPrice > price,"only accept bigger new price.");
		price = newPrice;
	}

	function reduceMaxSupply(uint newSupply) external onlyOwner{
		require(newSupply < maxSupply,"only accept reduce supply");
		maxSupply = newSupply;
	}

	// // metadata URI
	string private _baseTokenURI;
	string private _unrevealedURI;
	bool public isRevealed;
	
	function tokenURI(uint256 tokenId) public view override returns (string memory){
		require( _exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

		if(!isRevealed) return _unrevealedURI;
		
		string memory baseURI = _baseTokenURI;
		
		return bytes(baseURI).length > 0 ? 
			string(abi.encodePacked(baseURI, tokenId.toString())) : "";
	}
	
	function reveal() external onlyOwner {
		isRevealed = true;
	}
	
	function setUnrevealURI(string calldata unrevealedURI) external onlyOwner {
		_unrevealedURI = unrevealedURI;
	}

	function setBaseURI(string calldata baseURI) external onlyOwner {
		_baseTokenURI = baseURI;
	}

	function setOwnersExplicit(uint256 quantity) external onlyOwner nonReentrant {
		_setOwnersExplicit(quantity);
	}	

	function numberMinted(address owner) public view returns (uint256) {
		return _numberMinted(owner);
	}

	function getOwnershipData(uint256 tokenId) external view returns (TokenOwnership memory){
		return ownershipOf(tokenId);
	}
	
	fallback() external payable {}

    receive() external payable {}
}