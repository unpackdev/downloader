// SPDX-License-Identifier: GPL-3.0

// Created by hLoot

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract grid is ERC721Enumerable, Ownable {
	using Strings for uint256;

	string public baseURI = 'https://gridproject.mypinata.cloud/ipfs/QmTB88vzp3k6jTh7BwZmgzBQQ55f1D1Kt3RbS2NU7FFTyc/';
	string public baseExtension = ".json";
	uint256 public cost = 0.05 ether;
	uint256 public promoCost = 0.04 ether;
	uint256 public promoMin = 5;
	uint256 public maxSupply = 2048;
	uint256 public maxMintAmount = 10;
	bool public paused = false;
	mapping(address => bool) public whitelisted;


	constructor() ERC721("Grid Project", "GRID") {
	}

	// internal
	function _baseURI() internal view virtual override returns (string memory) {
		return baseURI;
	}

	// public
	function mint(uint256 _mintAmount) public payable {
 		uint256 supply = totalSupply();
		require(!paused);
		require(_mintAmount > 0);
		require(_mintAmount <= maxMintAmount);
		require(supply + _mintAmount <= maxSupply);

		if (msg.sender != owner()) {
				if(whitelisted[msg.sender] != true) {
					if(_mintAmount >= promoMin) {
						require(msg.value >= promoCost * _mintAmount);
					} else {
						require(msg.value >= cost * _mintAmount);
					}
				}
		}

		for (uint256 i = 1; i <= _mintAmount; i++) {
			_safeMint(msg.sender, supply + i);
		}
	}

	function walletOfOwner(address _owner)
		public
		view
		returns (uint256[] memory)
	{
		uint256 ownerTokenCount = balanceOf(_owner);
		uint256[] memory tokenIds = new uint256[](ownerTokenCount);
		for (uint256 i; i < ownerTokenCount; i++) {
			tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
		}
		return tokenIds;
	}

	 function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

	//only owner
	function setCost(uint256 _newCost) public onlyOwner() {
		cost = _newCost;
	}

	function setPromoCost(uint256 _newPromoCost) public onlyOwner() {
		promoCost = _newPromoCost;
	}

	function setPromoMin(uint256 _newPromoMin) public onlyOwner() {
		promoMin = _newPromoMin;
	}

	function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner() {
		maxMintAmount = _newmaxMintAmount;
	}

	function setBaseURI(string memory _newBaseURI) public onlyOwner {
		baseURI = _newBaseURI;
	}

	function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
		baseExtension = _newBaseExtension;
	}

	function pause(bool _state) public onlyOwner {
		paused = _state;
	}

function whitelistUser(address _user) public onlyOwner {
		whitelisted[_user] = true;
	}

	function removeWhitelistUser(address _user) public onlyOwner {
		whitelisted[_user] = false;
	}

	function withdraw() public payable onlyOwner {
		require(payable(msg.sender).send(address(this).balance));
	}

}