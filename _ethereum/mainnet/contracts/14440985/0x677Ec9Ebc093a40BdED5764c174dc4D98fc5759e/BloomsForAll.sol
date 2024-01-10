// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

/*********************************************************************************************
 _______     ___    _     _______       _______  .-./`)  
\  ____  \ .'   |  | |   /   __  \     /   __  \ \ .-.') 
| |    \ | |   .'  | |  | ,_/  \__)   | ,_/  \__)/ `-' \ 
| |____/ / .'  '_  | |,-./  )       ,-./  )       `-'`"` 
|   _ _ '. '   ( \.-.|\  '_ '`)     \  '_ '`)     .---.  
|  ( ' )  \' (`. _` /| > (_)  )  __  > (_)  )  __ |   |  
| (_{;}_) || (_ (_) _)(  .  .-'_/  )(  .  .-'_/  )|   |  
|  (_,_)  / \ /  . \ / `-'`-'     /  `-'`-'     / |   |  
/_______.'   ``-'`-''    `._____.'     `._____.'  '---'  
                                                                                                                                                                                  
**********************************************************************************************
 ENGINEER James Iacabucci
 ARTIST Kelley Art Botanica
*********************************************************************************************/

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract BloomsForAll is ERC721, Ownable, ReentrancyGuard {
	using Counters for Counters.Counter;

	// The number of NTFs that have been minted
	Counters.Counter private currentTokenId;

	// The number of NTFs that have been burned
	Counters.Counter private tokensBurned;

	// The maximum number of NFTs that can be minted
	uint256 public constant COLLECTION_SIZE = 44;

	// Unique URI for each NFT (1/1 collection)
	mapping(uint256 => string) private _tokenURIs;

	// Event to signify that metadata has been frozen
	event PermanentURI(string _value, uint256 indexed _id);

	constructor() ERC721("Blooms for All", "BLOOM") {}

	function totalSupply() public pure returns (uint256) {
		return COLLECTION_SIZE;
	}

	function totalMinted() public view returns (uint256) {
		return currentTokenId.current();
	}

	function totalBurned() public view returns (uint256) {
		return tokensBurned.current();
	}

	function mintNft(address recipient, string memory _tokenURI) public onlyOwner returns (uint256) {
		require((currentTokenId.current() - tokensBurned.current()) < COLLECTION_SIZE, "The maximum number of NFTs have already been minted.");
		currentTokenId.increment();
		uint256 newItemId = currentTokenId.current();
		_safeMint(recipient, newItemId);
		_tokenURIs[newItemId] = _tokenURI;
		emit PermanentURI(_tokenURI, newItemId);
		return newItemId;
	}

	function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
		require(_exists(tokenId), "The token Id specified does not exist.");
		return (_tokenURIs[tokenId]);
	}

	function withdraw() public onlyOwner nonReentrant {
		// transfer the contract balance to the owner.
		(bool os, ) = payable(owner()).call{ value: address(this).balance }("");
		require(os);
	}

	function burn(uint256 tokenId) public {
		require(ownerOf(tokenId) == msg.sender, "You must be the owner of the token");
		tokensBurned.increment();
		_burn(tokenId);
	}

	function _burn(uint256 tokenId) internal virtual override {
		super._burn(tokenId);

		if (bytes(_tokenURIs[tokenId]).length != 0) {
			delete _tokenURIs[tokenId];
		}
	}
}
