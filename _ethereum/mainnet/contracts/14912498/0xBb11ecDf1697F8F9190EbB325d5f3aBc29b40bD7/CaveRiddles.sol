// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC2981.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract CaveRiddles is ERC721, ERC721Enumerable, ERC2981, Ownable {
	
	address private receiver;
	uint96 private royaltyFeesInBips;
	using Counters for Counters.Counter;
    uint public MAX_SUPPLY = 28;
	Counters.Counter private _tokenIdCounter;
    string public contractURI = "ipfs://QmaeL1VsfKoLSVJfVycsJ1JFPRxyHNRAxt7ieLob4qtbAJ";
	string public baseURI = "ipfs://QmeGMW7kfBXFL4ySt5L4Dhh25gMKR936u3373MdY3VNPjR/";

	constructor() ERC721("YetiLabz Cave Riddles", "CAVE") {
	}
 
	function _baseURI() internal view override returns (string memory) {
		return baseURI;
	}

	function changeContractURI(string memory contractURI_) public onlyOwner {
		contractURI = contractURI_;
	}

	function tokenURI(uint256 tokenId) public view override returns (string memory) {
		require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
		string memory baseURI_ = _baseURI();
		return bytes(baseURI_).length > 0 ? string(abi.encodePacked(baseURI_, Strings.toString(tokenId), ".json")) : "";
	}

	function safeMint(address to, uint256 tokenId) public onlyOwner {
		require(totalSupply() < MAX_SUPPLY, "Not enough tokens left");
		_safeMint(to, tokenId);
	}
 
 	function mintAll() public onlyOwner {
		for (uint256 i = _tokenIdCounter.current(); i < MAX_SUPPLY; i++) {
			_safeMint(msg.sender, _tokenIdCounter.current());
			_tokenIdCounter.increment();

		}
	}
	function bulkAirdrop(address [] calldata _to, uint256 [] calldata _id) public {
		require(_to. length == _id.length, "Receivers and IDs are different length"); 
		for (uint256 i = 0; i<_to.length; i++) {
			safeTransferFrom(msg.sender, _to[i], _id[i]);
		}
	}

	function withdraw() public onlyOwner {
		require(address(this).balance > 0, "Balance is 0"); 
		payable(owner()).transfer(address(this).balance);
	}

	function setRoyaltyInfo(address _receiver, uint96 _royaltyFeesInBips) public onlyOwner {
		_setDefaultRoyalty(_receiver, _royaltyFeesInBips);
	}

	function _beforeTokenTransfer(address from, address to, uint256 tokenId)
		internal
		override(ERC721, ERC721Enumerable)
	{
		super._beforeTokenTransfer(from, to, tokenId);
	}

	function supportsInterface(bytes4 interfaceId)
		public
		view
		override(ERC721, ERC721Enumerable, ERC2981)
		returns (bool)
	{
		return super.supportsInterface(interfaceId);
	}
}