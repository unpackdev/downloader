//Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Pausable.sol";
import "./ERC721URIStorage.sol";
//import "./ERC721Pausable.sol";
import "./ERC721Enumerable.sol";
import "./Counters.sol";
import "./Ownable.sol";


contract Wheels is ERC721URIStorage, Ownable, Pausable, ERC721Enumerable {


	using Counters for Counters.Counter;
	Counters.Counter private _tokenIds;

	uint256 public tokensLimit;
	uint256 public tokensMinted;
	uint256 public tokensAvailable;

	address payable destinationAddress;

	mapping (string => bool) private _mintedTokenUris;

	event UpdateTokenCounts(uint256 tokensMintedNew,uint256 tokensAvailableNew);


	constructor(uint256 tokensLimitInit, address payable destinationAddressInit) public ERC721("Wheels","WHLZ") {
		tokensLimit = tokensLimitInit;
		tokensAvailable = tokensLimitInit;
		tokensMinted = 0;
		destinationAddress = destinationAddressInit;
	}

	function mintToken(address to, string memory uri) 
		public 
		whenNotPaused
		virtual 
		payable 
		returns (uint256) 
	{
		require(msg.value >= 80000000000000000,"Not enough ETH sent");
		require(tokensAvailable >= 1,"All tokens have been minted");
		require(_mintedTokenUris[uri] == false);
		passOnEth(msg.value);


		_tokenIds.increment();
		uint256 newItemId = _tokenIds.current();
		_mint(to,newItemId);
		_setTokenURI(newItemId, uri);


		tokensMinted = newItemId;
		tokensAvailable = tokensLimit - newItemId;
		_mintedTokenUris[uri] = true;

		emit UpdateTokenCounts(tokensMinted,tokensAvailable);

		return newItemId;
	}

	function mintTwoTokens(address to, string memory uri,string memory uriTwo) 
		public 
		whenNotPaused
		virtual 
		payable 
		returns (uint256) 
	{
		require(msg.value >= 130000000000000000,"Not enough ETH sent");
		require(tokensAvailable >= 2,"All tokens have been minted");
		require(_mintedTokenUris[uri] == false);
		require(_mintedTokenUris[uriTwo] == false);
		passOnEth(msg.value);

		_tokenIds.increment();
		uint256 newItemId = _tokenIds.current();
		_mint(to,newItemId);
		_setTokenURI(newItemId, uri);
		_mintedTokenUris[uri] = true;

		_tokenIds.increment();
		newItemId = _tokenIds.current();
		_mint(to,newItemId);
		_setTokenURI(newItemId, uriTwo);
		_mintedTokenUris[uriTwo] = true;

		tokensMinted = newItemId;
		tokensAvailable = tokensLimit - newItemId;

		emit UpdateTokenCounts(tokensMinted,tokensAvailable);

		return newItemId;
	}


	function mintFourTokens(address to, string memory uri,string memory uriTwo,string memory uriThree,string memory uriFour) 
		public
		whenNotPaused 
		virtual 
		payable 
		returns (uint256) 
	{
		require(msg.value >= 200000000000000000,"Not enough ETH sent");
		require(tokensAvailable >= 4,"All tokens have been minted");
		require(_mintedTokenUris[uri] == false);
		require(_mintedTokenUris[uriTwo] == false);
		require(_mintedTokenUris[uriThree] == false);
		require(_mintedTokenUris[uriFour] == false);
		passOnEth(msg.value);

		_tokenIds.increment();
		uint256 newItemId = _tokenIds.current();
		_mint(to,newItemId);
		_setTokenURI(newItemId, uri);
		_mintedTokenUris[uri] = true;

		_tokenIds.increment();
		newItemId = _tokenIds.current();
		_mint(to,newItemId);
		_setTokenURI(newItemId, uriTwo);
		_mintedTokenUris[uriTwo] = true;

		_tokenIds.increment();
		newItemId = _tokenIds.current();
		_mint(to,newItemId);
		_setTokenURI(newItemId, uriThree);
		_mintedTokenUris[uriThree] = true;

		_tokenIds.increment();
		newItemId = _tokenIds.current();
		_mint(to,newItemId);
		_setTokenURI(newItemId, uriFour);
		_mintedTokenUris[uriFour] = true;

		
		tokensMinted = newItemId;
		tokensAvailable = tokensLimit - newItemId;

		emit UpdateTokenCounts(tokensMinted,tokensAvailable);

		return newItemId;
	}



	function mintMysteryToken(address to, string memory uri) 
		public 
		whenNotPaused
		virtual 
		onlyOwner
		returns (uint256) 
	{
		require(tokensAvailable == 0,"Can not mint the mystery wheel yet.");
		require(_mintedTokenUris[uri] == false);


		_tokenIds.increment();
		uint256 newItemId = _tokenIds.current();
		_mint(to,newItemId);
		_setTokenURI(newItemId, uri);
		_mintedTokenUris[uri] = true;

		return newItemId;
	}


	function pauseContract() public onlyOwner whenNotPaused {

		_pause();
	}

	function unPauseContract() public onlyOwner whenPaused {
		_unpause();
	}

	 function passOnEth(uint256 amount) public payable {
        // Call returns a boolean value indicating success or failure.
        // This is the current recommended method to use.

        uint singleAmount = amount;

        (bool sentToAddress, bytes memory dataToAddressOne) = destinationAddress.call{value: singleAmount}("");
        require(sentToAddress, "Failed to send Ether");

    }


    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override (ERC721,ERC721Enumerable)  {
        super._beforeTokenTransfer(from, to, tokenId);
        require(!paused(), "ERC721Pausable: token transfer while paused");

    }


    function _burn(uint256 tokenId) 
    	internal 
    	virtual 
    	override (ERC721, ERC721URIStorage) 
    {
        super._burn(tokenId);

    }


    function tokenURI(uint256 tokenId)
    public 
    view 
    virtual 
    override (ERC721, ERC721URIStorage)
   	returns (string memory) 
   	{

        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) 
    public 
    view 
    virtual 
    override(ERC721, ERC721Enumerable) returns (bool) 
    {
        return super.supportsInterface(interfaceId);
    }

}




