// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "./Ownable.sol";
import "./Strings.sol";
import "./ERC721A.sol";

//String_Ownable_IERCmetadata_ERC165_IERC165_context_ERC721_IERC721

contract JustASquareERC721A is ERC721A, Ownable {
	using Strings for uint256;

	string public uriPrefix = "";
	string public uriSuffix = ".json";

	uint256 private cost = 0.01 ether;
	uint256 private costFree = 0;
	uint256 public maxSupply = 2000;
	uint256 public maxSupplyFree = 1000;
	uint256 public maxMintAmountPerTx = 10;
	uint256 public maxMintPerWallet = 20;

	bool public paused = true;

	constructor(string memory _tokenName, string memory _symbol) ERC721A(_tokenName, _symbol) {}

	modifier mintCompliance(uint256 _mintAmount) {
		require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "Invalid mint amount!");
		require(totalSupply() + _mintAmount <= maxSupply, "Max supply exceeded!");
		require(balanceOf(msg.sender) + _mintAmount <= maxMintPerWallet, "Max supply for your wallet exceeded!");
		_;
	}

	function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) {
		require(!paused, "The contract is paused!");
		if (totalSupply() + _mintAmount <= maxSupplyFree) {
			_safeMint(msg.sender, _mintAmount);
		} else {
			require(msg.value >= cost * _mintAmount, "Insufficient funds!");
			_safeMint(msg.sender, _mintAmount);
		}
	}

	function gift(uint256 _mintAmount, address _receiver) public onlyOwner {
		require(totalSupply() + _mintAmount <= maxSupply, "Max supply exceeded!");
		_safeMint(_receiver, _mintAmount);
	}

	function walletOfOwner(address _owner) public view returns (uint256[] memory) {
		uint256 ownerTokenCount = balanceOf(_owner);
		uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
		uint256 currentTokenId = 1;
		uint256 ownedTokenIndex = 0;

		while (ownedTokenIndex < ownerTokenCount && currentTokenId <= totalSupply()) {
			address currentTokenOwner = ownerOf(currentTokenId);

			if (currentTokenOwner == _owner) {
				ownedTokenIds[ownedTokenIndex] = currentTokenId;

				ownedTokenIndex++;
			}

			currentTokenId++;
		}

		return ownedTokenIds;
	}

	function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
		require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

		string memory currentBaseURI = _baseURI();
		return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix)) : "";
	}

	function setCost(uint256 _cost) public onlyOwner {
		cost = _cost;
	}

	function getCost() public view returns (uint256) {
		if (totalSupply() < maxSupplyFree) {
			return costFree;
		}
		return cost;
	}

	function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
		maxMintAmountPerTx = _maxMintAmountPerTx;
	}

	function setUriPrefix(string memory _uriPrefix) public onlyOwner {
		uriPrefix = _uriPrefix;
	}

	function setUriSuffix(string memory _uriSuffix) public onlyOwner {
		uriSuffix = _uriSuffix;
	}

	function setPaused(bool _state) public onlyOwner {
		paused = _state;
	}

	function withdraw() public onlyOwner {
		// This will transfer the remaining contract balance to the owner.
		(bool os, ) = payable(owner()).call{ value: address(this).balance }("");
		require(os);
	}

	function withdrawAmount(uint256 _amount) public onlyOwner {
		require(_amount <= address(this).balance, "not enought in contract");
		(bool os, ) = payable(owner()).call{ value: _amount }("");
		require(os);
	}

	function _baseURI() internal view virtual override returns (string memory) {
		return uriPrefix;
	}

	function _startTokenId() internal view virtual override returns (uint256) {
		return 1;
	}
}
