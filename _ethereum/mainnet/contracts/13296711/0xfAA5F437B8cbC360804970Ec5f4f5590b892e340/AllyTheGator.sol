// Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract AllyTheGator is ERC721, ERC721Enumerable, Ownable {
	using SafeMath for uint256;

	string public GATOR_PROVENANCE = '';

	uint256 public constant MAX_TOKENS = 1000;

	uint256 public constant MAX_TOKENS_PER_PURCHASE = 10;

	bool public isSaleActive = true;

	uint256 private _price = 25000000000000000;

	string private _baseURIextended;

	constructor() ERC721('AllyTheGator', 'GATOR') {}

	function setProvenanceHash(string memory _provenanceHash) public onlyOwner {
		GATOR_PROVENANCE = _provenanceHash;
	}

	function setBaseURI(string memory baseURI_) external onlyOwner {
		_baseURIextended = baseURI_;
	}

	function reserveTokens(address _to, uint256 _reserveAmount) public onlyOwner {
		uint256 supply = totalSupply();
		for (uint256 i = 0; i < _reserveAmount; i++) {
			_safeMint(_to, supply + i);
		}
	}

	function _beforeTokenTransfer(
		address from,
		address to,
		uint256 tokenId
	) internal override(ERC721, ERC721Enumerable) {
		super._beforeTokenTransfer(from, to, tokenId);
	}

	function supportsInterface(bytes4 interfaceId)
		public
		view
		override(ERC721, ERC721Enumerable)
		returns (bool)
	{
		return super.supportsInterface(interfaceId);
	}

	function mint(uint256 _count) public payable {
		uint256 totalSupply = totalSupply();

		require(isSaleActive, 'Sale is not active');
		require(
			_count > 0 && _count < MAX_TOKENS_PER_PURCHASE + 1,
			'Exceeds maximum tokens you can purchase in a single transaction'
		);
		require(
			totalSupply + _count < MAX_TOKENS + 1,
			'Exceeds maximum tokens available for purchase'
		);

		require(msg.value >= _price.mul(_count), 'Ether value sent is not correct');

		for (uint256 i = 0; i < _count; i++) {
			_safeMint(msg.sender, totalSupply + i);
		}
	}

	function _baseURI() internal view virtual override returns (string memory) {
		return _baseURIextended;
	}

	function flipSaleStatus() public onlyOwner {
		isSaleActive = !isSaleActive;
	}

	function setPrice(uint256 _newPrice) public onlyOwner {
		_price = _newPrice;
	}

	function getPrice() public view returns (uint256) {
		return _price;
	}

	function withdraw() public onlyOwner {
		payable(owner()).transfer(address(this).balance);
	}

	function tokensByOwner(address _owner) external view returns (uint256[] memory) {
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
}
