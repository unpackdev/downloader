//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


import "./ERC721A.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";


contract SocialSelfies is ERC721A, Ownable, ReentrancyGuard {
	using Strings for uint256;
	using Counters for Counters.Counter;

	string public uriPrefix = "https://socialselfies.io/nfts/";
	string public uriSuffix = ".json";
	//string public hiddenMetadataUri;
	
	uint256 public cost = 0.0 ether;
	uint256 public maxSupply = 100000000 * 10**6 * 10**5;	
	uint256 public maxMintAmountPerTx = 100;

	bool public paused = true;
	//bool public revealed = true;
	
	event mintedEv(address poster, uint256 _id, uint256 date);

	constructor(
		string memory _tokenName,
		string memory _tokenSymbol
		//string memory _hiddenMetadataUri
	) ERC721A(_tokenName, _tokenSymbol) {
		//setHiddenMetadataUri(_hiddenMetadataUri);
	}

	modifier mintCompliance(uint256 _mintAmount) {
		require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
		//require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
		_;
	}
	modifier mintPriceCompliance(uint256 _mintAmount) {
		require(msg.value >= cost * _mintAmount, 'Insufficient funds!');
		_;
	}

	function ownerMint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) onlyOwner {
		uint256 start_from = totalSupply()+1;
		_safeMint(_msgSender(), _mintAmount);
		for(uint256 i=start_from; i!=totalSupply()+1; i++){
			emit mintedEv(_msgSender(), i, block.timestamp);
		}
	}


	function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
		require(!paused, 'Public mint not allowed!');

		uint256 start_from = totalSupply()+1;
		_safeMint(_msgSender(), _mintAmount);
		for(uint256 i=start_from; i!=totalSupply()+1; i++){
			emit mintedEv(_msgSender(), i, block.timestamp);
		}
	}

	function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
		require(_exists(_tokenId), 'Nonexistent token');
		
		string memory currentBaseURI = _baseURI();
		return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix)) : '';
	}

	function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
		maxMintAmountPerTx = _maxMintAmountPerTx;
	}

//	function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
//		hiddenMetadataUri = _hiddenMetadataUri;
//	}

	function setUriPrefix(string memory _uriPrefix) public onlyOwner {
		uriPrefix = _uriPrefix;
	}

	function setUriSuffix(string memory _uriSuffix) public onlyOwner {
		uriSuffix = _uriSuffix;
	}


	function withdraw() public onlyOwner nonReentrant {
		(bool os, ) = payable(owner()).call{ value: address(this).balance }('');
		require(os);
	}


	function _baseURI() internal view virtual override returns (string memory) {
		return uriPrefix;
	}

	function _startTokenId() internal view virtual override returns (uint256) {
		return 1;
	}


	function setPaused(bool _state) public onlyOwner {
		paused = _state;
	}

//	function setMaxSupply(uint256 count) public onlyOwner {
//		maxSupply = count;
//	}

	function setCost(uint256 _cost) public onlyOwner {
		cost = _cost;
	}


//	function setRevealed(bool _state) public onlyOwner {
//		revealed = _state;
//	}

}
