// SPDX-License-Identifier: AGPL-3.0-or-later


pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ECDSA.sol";
import "./ERC721A.sol";

contract BaseCollection is Ownable, ERC721A, ReentrancyGuard {
	
	using ECDSA for bytes32;
    using Strings for uint256;

	uint256 devReserve;
	address public root;
	bool initialized;
	
	uint256 public price;
	uint256 public allowMint = 1;
	mapping(address=>uint256) public claimed;
	
	address feeCollector;
	
	constructor(
		string memory name_, 
		string memory symbol_, 
		uint256 collectionSize_
	) ERC721A(
		name_, 
		symbol_, 
		100, 
		collectionSize_) {}
	
	function initialize(address root_, uint256 reserveAmount, uint256 price_, string calldata unrevealedURI) external onlyOwner{
		require(!initialized, "only initialized once");
		initialized = true;
		
		root = root_;
		devReserve = reserveAmount;
		price = price_;
		_unrevealedURI = unrevealedURI;
	}
	
	function allowMultipleClaim(uint256 newAmount) external onlyOwner{
		allowMint = newAmount;
	}

	function mint(bytes memory _signature) external nonReentrant payable{
		require(msg.value == price, "Price not correct");
		require(totalSupply() + devReserve < collectionSize, "Reached max supply");
		_verifyAndMint(_signature, msg.sender);
	}

	function mintFor(address account, bytes memory _signature)external nonReentrant payable{
		require(msg.value == price, "Price not correct");
		require(totalSupply() + devReserve < collectionSize, "Reached max supply");
		_verifyAndMint(_signature, account);
	}
	
	function _verifyAndMint(bytes memory _signature, address account) internal{
		bytes32 msgHash = keccak256(abi.encodePacked(account, name()));
        require(isValidSignature(msgHash, _signature), "Not authorized to mint");
		require(claimed[account] < allowMint, "Exceed current WL allowMint.");
		unchecked{ ++claimed[account]; }
		_safeMint(account, 1);
	}
	
	//direct recover to reduce back-end pressure
	function isValidSignature(bytes32 hash, bytes memory signature) public view returns (bool isValid) {
        //bytes32 signedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
		//bytes32 signedHash = ECDSA.toEthSignedMessageHash(hash);
        return hash.recover(signature) == root;
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
		bool sent;
		bytes memory data;
		(sent, data) = owner().call{value: 1 ether}("");
        require(sent, "Failed to refund gas");
		
		uint256 balance = address(this).balance;
        (sent, data) = feeCollector.call{value: balance}("");
        require(sent, "Failed to send Ether");
    }
	
	function setFeeCollector(address _newAddr) external onlyOwner{
		feeCollector = _newAddr;
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