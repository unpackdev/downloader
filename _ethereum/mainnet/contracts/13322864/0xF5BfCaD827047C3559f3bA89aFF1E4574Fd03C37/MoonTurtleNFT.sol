//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./ERC721URIStorage.sol";


contract MoonTurtleNFT is ERC721URIStorage, Ownable {
	using Counters
	for Counters.Counter;
	Counters.Counter private _tokenIds;
	Counters.Counter private _tokenIdsGiveaway;
	
	uint256 public constant REGULAR_MINT_COST = 0.08 ether;
	uint public constant MAX_TOKENS = 2500;
	uint public constant MAX_TOKENS_INIT = 1000;
	uint public constant MAX_TOKENS_GIVEAWAY = 100;
	
	uint internal CURR_SUPPLY_CAP = MAX_TOKENS_INIT;
	bool public hasSaleStarted = false;
	string public baseURI = "http://api.moonturtlenft.com/collection/";
	constructor() ERC721("MoonTurtleNFT", "MoonTurtle") {}

	function totalSupply() public view returns(uint256) {
		return CURR_SUPPLY_CAP;
	}
	
	function currentSupply() public view returns(uint256) {
		return _tokenIds.current();
	}



	function mintNFT(address recipient) public payable returns(uint256) {
		require(msg.value == REGULAR_MINT_COST, "MoonTurtleNFT: Invalid mint fee provided.");
		require(hasSaleStarted == true, "Sale hasn't started");
		require((_tokenIds.current() + 1) <= CURR_SUPPLY_CAP, "We're at max supply!");
		
		_tokenIds.increment();
		uint256 newItemId = _tokenIds.current();
		_mint(recipient, newItemId);
		_setTokenURI(newItemId, strConcat(baseURI, uint2str(newItemId)));
		return newItemId;
	}

	function strConcat(string memory _a, string memory _b) internal pure returns(string memory) {
		bytes memory _ba = bytes(_a);
		bytes memory _bb = bytes(_b);
		string memory abcde = new string(_ba.length + _bb.length);
		bytes memory babcde = bytes(abcde);
		uint k = 0;
		for(uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
		for(uint i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
		return string(babcde);
	}

	function uint2str(uint _i) internal pure returns(string memory _uintAsString) {
			if(_i == 0) {
				return "0";
			}
			uint j = _i;
			uint len;
			while(j != 0) {
				len++;
				j /= 10;
			}
			bytes memory bstr = new bytes(len);
			uint k = len;
			while(_i != 0) {
				k = k - 1;
				uint8 temp = (48 + uint8(_i - _i / 10 * 10));
				bytes1 b1 = bytes1(temp);
				bstr[k] = b1;
				_i /= 10;
			}
			return string(bstr);
		}
		

	function addCharacter(uint numTokens) public onlyOwner {
		require((CURR_SUPPLY_CAP + numTokens) <= MAX_TOKENS, "Can't add new character NFTs. Would exceed MAX_TOKENS");
		CURR_SUPPLY_CAP = CURR_SUPPLY_CAP + numTokens;
	}

	function setBaseURI(string memory argBaseUri) public onlyOwner {
		baseURI = argBaseUri;
	}

	function getBaseURI() public onlyOwner view returns(string memory) {
		return baseURI;
	}

	function reserveGiveaway(uint256 numTokens, address recipient) public onlyOwner {
		uint currSupply = _tokenIds.current();
		require((_tokenIdsGiveaway.current() + numTokens) <= MAX_TOKENS_GIVEAWAY, "Exceeded giveaway supply");
		require((currSupply + numTokens) < totalSupply(), "Exceeded supply");
		uint256 index;
		// Reserved for the people who helped build this project
		for(index = 1; index <= numTokens; index++) {
			_tokenIds.increment();
			_tokenIdsGiveaway.increment();
			_mint(recipient, currSupply + index);
			_setTokenURI(currSupply + index, strConcat(baseURI, uint2str(currSupply + index)));
		}
	}


	
	function withdrawAll() public payable onlyOwner {
		require(payable(msg.sender).send(address(this).balance));
	}
	
	function startSale() public onlyOwner {
		hasSaleStarted = true;
	}

	function pauseSale() public onlyOwner {
		hasSaleStarted = false;
	}
}