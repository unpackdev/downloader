// SPDX-License-Identifier: MIT
// https://github.com/muturgan/nft_dna
// https://linkedin.com/in/andrey-sakharov/
pragma solidity ^0.8.14;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./ERC2981.sol";
import "./Strings.sol";


contract DNA is
	ERC721,
	ERC721Enumerable,
	ERC721URIStorage,
	ERC2981
{
	enum SaleStatus {NotStarted, PreSale, Sale, Finished}

	uint private immutable MAX_NFT_COUNT;
	uint public immutable PRESALE_START_DATE;
	uint public immutable SALE_START_DATE;
	uint public immutable PRESALE_PRICE;
	uint public immutable SALE_PRICE;
	string private FOLDER;

	address private immutable owner;
	uint private tokenIdCounter;

	modifier onlyOwner() {
		require(owner == msg.sender, "not an owner");
		_;
	}


	constructor(
		address _owner,
		string memory _folder,
		uint _maxNftCount,
		uint _presaleStartDate,
		uint _saleStartDate,
		uint _presalePrice,
		uint _salePrice
	) ERC721("Norman's Duel: Apes", "NDA") {
		_setDefaultRoyalty(_owner, 1000); // owner zero addres check inside
		owner = _owner;
		FOLDER = _folder;
		require(_maxNftCount > 0, "zero nft count");
		MAX_NFT_COUNT = _maxNftCount;
		PRESALE_START_DATE = _presaleStartDate;
		require(_saleStartDate > _presaleStartDate, "incorrect saleStartDate");
		SALE_START_DATE = _saleStartDate;
		require(_presalePrice > 0, "zero presale price");
		PRESALE_PRICE = _presalePrice;
		require(_salePrice > _presalePrice, "incorrect salePrice");
		SALE_PRICE = _salePrice;
	}

	function _baseURI() internal pure override returns(string memory) {
		return "https://ipfs.io/ipfs/";
	}

	function contractURI() external view returns(string memory) {
		return string.concat(_baseURI(), FOLDER);
	}

	function mint() public payable {
		uint timestamp = block.timestamp;
		require(timestamp >= PRESALE_START_DATE, "the sale isn't started");

		address sender = msg.sender;
		uint price = timestamp >= SALE_START_DATE ? SALE_PRICE : PRESALE_PRICE;

		uint value = msg.value;
		if (value >= price) {
			mintItem(sender);
		}
		if (value >= price * 2) {
			if (tokenIdCounter < MAX_NFT_COUNT) {
				mintItem(sender);
			}
			else {
				payable(sender).transfer(price);
			}
		}
	}

	function mintItem(address to) private {
		require(tokenIdCounter < MAX_NFT_COUNT, "the sale is over");
		unchecked {
			tokenIdCounter += 1;
		}
		uint256 tokenId = tokenIdCounter;
		_safeMint(to, tokenId);
		string memory uri = string.concat(FOLDER, "/", Strings.toString(tokenId), ".json");
		_setTokenURI(tokenId, uri);
	}

	function setDefaultRoyalty(uint96 feeNumerator) external onlyOwner {
		_setDefaultRoyalty(owner, feeNumerator);
	}

	function setTokenRoyalty(uint tokenId, uint96 feeNumerator) external onlyOwner {
		require(_exists(tokenId), "nonexistent token");
		_setTokenRoyalty(tokenId, owner, feeNumerator);
	}

	function withdaraw() public onlyOwner {
		payable(owner).transfer(address(this).balance);
	}

	function currentPrice() external view returns(uint) {
		return block.timestamp >= SALE_START_DATE ? SALE_PRICE : PRESALE_PRICE;
	}

	function saleStatus() external view returns(SaleStatus) {
		if (block.timestamp < PRESALE_START_DATE) {
			return SaleStatus.NotStarted;
		}
		if (totalSupply() == MAX_NFT_COUNT) {
			return SaleStatus.Finished;
		}
		if (block.timestamp >= SALE_START_DATE) {
			return SaleStatus.Sale;
		}
		return SaleStatus.PreSale;
	}


	receive() external payable {
		if (msg.sender == owner) {
			withdaraw();
		} else {
			mint();
		}
	}

	fallback() external payable {}


	// <<<<< The following functions are overrides required by Solidity.
	function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
		super._beforeTokenTransfer(from, to, tokenId);
	}

	function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
		super._burn(tokenId);
	}

	function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns(string memory) {
		return super.tokenURI(tokenId);
	}

	function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable, ERC2981) returns(bool) {
		return super.supportsInterface(interfaceId);
	}
	// >>>> These functions are overrides required by Solidity.
}
