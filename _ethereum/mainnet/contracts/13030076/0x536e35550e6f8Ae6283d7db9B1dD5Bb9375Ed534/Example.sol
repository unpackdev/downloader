//Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";


contract Example is ERC721 {


	using Counters for Counters.Counter;
	Counters.Counter private _tokenIds;

	uint256 public tokensLimit;
	uint256 public tokensMinted;
	uint256 public tokensAvailable;

	address payable destinationAddressOne;
	address payable destinationAddressTwo;

	event UpdateTokenCounts(uint256 tokensMintedNew,uint256 tokensAvailableNew);

	constructor(uint256 tokensLimitInit, address payable desAddressOneInit, address payable desAddressTwoInit) public ERC721("Example","EXMPL") {
		tokensLimit = tokensLimitInit;
		tokensAvailable = tokensLimitInit;
		tokensMinted = 0;
		destinationAddressOne = desAddressOneInit;
		destinationAddressTwo = desAddressTwoInit;
	}

	function mintToken(address to, string memory uri) 
		public 
		virtual 
		payable 
		returns (uint256) 
	{
		require(msg.value >= 10000000000000,"Not enough ETH sent");
		require(tokensAvailable >= 1,"All tokens have been minted");
		passOnEth(msg.value);

		_tokenIds.increment();
		uint256 newItemId = _tokenIds.current();
		_mint(to,newItemId);
		_setTokenURI(newItemId, uri);


		tokensMinted = newItemId;
		tokensAvailable = tokensLimit - newItemId;

		emit UpdateTokenCounts(tokensMinted,tokensAvailable);

		return newItemId;
	}

	function mintFiveTokens(address to, string memory uri,string memory uriTwo,string memory uriThree,string memory uriFour,string memory uriFive) 
		public 
		virtual 
		payable 
		returns (uint256) 
	{
		require(msg.value >= 50000000000000,"Not enough ETH sent");
		require(tokensAvailable >= 5,"All tokens have been minted");
		passOnEth(msg.value);

		_tokenIds.increment();
		uint256 newItemId = _tokenIds.current();
		_mint(to,newItemId);
		_setTokenURI(newItemId, uri);

		_tokenIds.increment();
		newItemId = _tokenIds.current();
		_mint(to,newItemId);
		_setTokenURI(newItemId, uriTwo);

		_tokenIds.increment();
		newItemId = _tokenIds.current();
		_mint(to,newItemId);
		_setTokenURI(newItemId, uriThree);

		_tokenIds.increment();
		newItemId = _tokenIds.current();
		_mint(to,newItemId);
		_setTokenURI(newItemId, uriFour);

		_tokenIds.increment();
		newItemId = _tokenIds.current();
		_mint(to,newItemId);
		_setTokenURI(newItemId, uriFive);


		tokensMinted = newItemId;
		tokensAvailable = tokensLimit - newItemId;

		emit UpdateTokenCounts(tokensMinted,tokensAvailable);

		

		return newItemId;
	}


	function mintTenTokens(address to, string memory uri,string memory uriTwo,string memory uriThree,string memory uriFour,string memory uriFive, string memory uriSix,string memory uriSeven,string memory uriEight,string memory uriNine,string memory uriTen) 
		public 
		virtual 
		payable 
		returns (uint256) 
	{
		require(msg.value >= 100000000000000,"Not enough ETH sent");
		require(tokensAvailable >= 10,"All tokens have been minted");
		passOnEth(msg.value);

		_tokenIds.increment();
		uint256 newItemId = _tokenIds.current();
		_mint(to,newItemId);
		_setTokenURI(newItemId, uri);

		_tokenIds.increment();
		newItemId = _tokenIds.current();
		_mint(to,newItemId);
		_setTokenURI(newItemId, uriTwo);

		_tokenIds.increment();
		newItemId = _tokenIds.current();
		_mint(to,newItemId);
		_setTokenURI(newItemId, uriThree);

		_tokenIds.increment();
		newItemId = _tokenIds.current();
		_mint(to,newItemId);
		_setTokenURI(newItemId, uriFour);

		_tokenIds.increment();
		newItemId = _tokenIds.current();
		_mint(to,newItemId);
		_setTokenURI(newItemId, uriFive);

		_tokenIds.increment();
		newItemId = _tokenIds.current();
		_mint(to,newItemId);
		_setTokenURI(newItemId, uriSix);

		_tokenIds.increment();
		newItemId = _tokenIds.current();
		_mint(to,newItemId);
		_setTokenURI(newItemId, uriSeven);

		_tokenIds.increment();
		newItemId = _tokenIds.current();
		_mint(to,newItemId);
		_setTokenURI(newItemId, uriEight);

		_tokenIds.increment();
		newItemId = _tokenIds.current();
		_mint(to,newItemId);
		_setTokenURI(newItemId, uriNine);

		_tokenIds.increment();
		newItemId = _tokenIds.current();
		_mint(to,newItemId);
		_setTokenURI(newItemId, uriTen);


		tokensMinted = newItemId;
		tokensAvailable = tokensLimit - newItemId;

		emit UpdateTokenCounts(tokensMinted,tokensAvailable);

		

		return newItemId;
	}



	 function passOnEth(uint256 amount) public payable {
        // Call returns a boolean value indicating success or failure.
        // This is the current recommended method to use.

        uint singleAmount = amount / 2;

        (bool sentToAddressOne, bytes memory dataToAddressOne) = destinationAddressOne.call{value: singleAmount}("");
        require(sentToAddressOne, "Failed to send Ether");

        (bool sentToAddressTwo, bytes memory dataToAddressTwo) = destinationAddressTwo.call{value: singleAmount}("");
        require(sentToAddressTwo, "Failed to send Ether");
    }


}




