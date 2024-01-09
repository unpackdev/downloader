// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./Strings.sol";
import "./ECDSA.sol";

contract Bobaverse is ERC721, ERC721Enumerable, Ownable {
	using Strings for uint256;
	using ECDSA for bytes32;
	string public baseUri;
	string public baseExtension = ".json";
	string public notRevealedUri;
	bool public paused = true;
	bool public pausedWhitelist = true;
	bool public revealed = false;
	uint256 public constant MAX_SUPPLY = 8084;
	uint256 public constant MAX_PER_WALLET_PUBLIC = 3;
	uint256 public constant MAX_PER_WALLET_WL = 4;
	uint256 public PRICE = 0.095 ether;
	uint256 public PRICE_WHITELIST = 0.085 ether;
	address internal signer;
	
	function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
		super._beforeTokenTransfer(from, to, tokenId);
	}
	
	function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
		return super.supportsInterface(interfaceId);
	}
	
	function setBaseURI(string memory newBaseURI) public onlyOwner() {
		baseUri = newBaseURI;
	}
	
	function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
		baseExtension = _newBaseExtension;
	}
	
	function _baseURI() internal view virtual override returns (string memory) {
		return baseUri;
	}
	
	function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory){
		require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
		if (revealed == false) {
			return notRevealedUri;
		}
		string memory currentBaseURI = _baseURI();
		return bytes(currentBaseURI).length > 0
		? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
		: "";
	}
	
	function setPaused(bool newState) external onlyOwner {
		paused = newState;
	}
	
	function setPausedWhitelist(bool newState) external onlyOwner {
		pausedWhitelist = newState;
	}
	
	function setRevealed(bool newState) external onlyOwner {
		revealed = newState;
	}
	
	function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
		notRevealedUri = _notRevealedURI;
	}
	
	function setSigner(address newSigner) public onlyOwner {
		require(newSigner != address(0), "incorrect address");
		signer = newSigner;
	}
	
	constructor(string memory _name,
		string memory _symbol,
		address _signer,
		string memory _initBaseURI,
		string memory _initNotRevealedUri) ERC721(_name, _symbol) {
		setBaseURI(_initBaseURI);
		setNotRevealedURI(_initNotRevealedUri);
		setSigner(_signer);
	}
	
	function mint(uint numberOfTokens) external payable {
		uint256 totalSupply = totalSupply();
		uint256 tokenCount = balanceOf(msg.sender);
		require(!paused, "Contract Paused");
		require(totalSupply + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max tokens");
		require((tokenCount + numberOfTokens <= MAX_PER_WALLET_PUBLIC), "Purchase exceed max tokens allowed per wallet");
		require(PRICE * numberOfTokens <= msg.value, "Ether value sent is not correct");
		for (uint256 i = 0; i < numberOfTokens; i++) {
			_safeMint(msg.sender, totalSupply + i);
		}
	}
	
	function mintWhitelist(uint256 numberOfTokens, bytes calldata _signature) external payable {
		uint256 totalSupply = totalSupply();
		uint256 tokenCount = balanceOf(msg.sender);
		require(!pausedWhitelist, "Whitelist Paused");
		require(totalSupply + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max tokens");
		require((tokenCount + numberOfTokens <= MAX_PER_WALLET_WL), "Purchase exceed max tokens allowed per wallet");
		require((recoverData(msg.sender, _signature) == signer), "Invalid Signature");
		require(PRICE_WHITELIST * numberOfTokens <= msg.value, "Ether value sent is not correct");
		for (uint256 i = 0; i < numberOfTokens; i++) {
			_safeMint(msg.sender, totalSupply + i);
		}
	}
	
	function recoverData(address _sender, bytes calldata _signature) internal pure returns (address _data) {
		bytes32 msgHash = keccak256(abi.encode(_sender));
		return msgHash.toEthSignedMessageHash().recover(_signature);
	}
	
	function reserve(uint256 numberOfTokens) external onlyOwner {
		uint totalSupply = totalSupply();
		require(totalSupply + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max tokens");
		for (uint256 i = 0; i < numberOfTokens; i++) {
			_safeMint(msg.sender, totalSupply + i);
		}
	}
	
	function mintTo(uint numberOfTokens, address to) external onlyOwner {
		uint totalSupply = totalSupply();
		require(totalSupply + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max tokens");
		for (uint256 i = 0; i < numberOfTokens; i++) {
			_safeMint(to, totalSupply + i);
		}
	}
	
	function tokensOfOwner(address _owner) external view returns (uint256[] memory) {
		uint256 tokenCount = balanceOf(_owner);
		if (tokenCount == 0) {
			return new uint256[](0);
		} else {
			uint256[] memory result = new uint256[](tokenCount);
			uint256 index;
			for (index = 0; index < tokenCount; index++) {
				result[index] = tokenOfOwnerByIndex(_owner, index);
			}
			return result;
		}
	}
	
	function withdraw() external onlyOwner {
		uint balance = address(this).balance;
		payable(msg.sender).transfer(balance);
	}
}
