// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
contract PixelPussies is ERC721, ERC721Enumerable, Ownable, ReentrancyGuard {
    using Strings for uint256;

	// Token Info
	uint256 public constant PRICE = .04 ether;
	uint256 public constant MAX_SUPPLY = 10000;
	uint256 public constant MAX_VOLUME_MINTABLE  = 10000;

    // Base URI
    string private _baseURIextended;
	
	// AllowList
	mapping(address => bool) private _allowList;
	mapping(address => uint256) private _stock;
	
	// PreSale - PublicSales
	bool private _isPreSaleActive = false;
	bool private _isPublicSaleActive = false;
	
	// Owners
	address private owner0 = 0x06754B7E4b20A87B58F6DbF4037aDc457FcEB9b9;
	address private owner1 = 0x03112e7C1d078265193C483a6afc8FfA2E0d7Ce0;
	address private owner2 = 0xC9fD593b01697f3C220734f7CDc03B2BC7AB9e72;
	address private owner3 = 0xE6dfC409F5c55ce0C7281F371F47F0eb956cf8d0;
	address private owner4 = 0x74A8acAC1408cdD99fAc009fa71cA6fC1B0EA599;
	address private owner5 = 0x139087327170736972AF33990F34E73499f540b7;
	
	// Modifiers
	modifier isRealUser() {
		require(msg.sender == tx.origin, "Sorry, you do not have the permission todo that.");
		_;
	}
	modifier isOwner() {
        require(msg.sender == owner0, "You are not an owner");
        _;
    }
	
	// Events
	event PreSaleStarted();
	event PreSaleStopped();
	event PublicSaleStarted();
	event PublicSaleStopped();
	
    constructor() ERC721('PixelPussies', 'PP') {}
	
	function addToAllowList(address[] calldata addresses) external onlyOwner() {
		for (uint256 i = 0; i < addresses.length; i++) {
		  require(addresses[i] != address(0), "Null address");
		  _allowList[addresses[i]] = true;
		}
	}

	function removeFromAllowList(address[] calldata addresses) external onlyOwner() {
		for (uint256 i = 0; i < addresses.length; i++) {
		  require(addresses[i] != address(0), "Null address");
		  _allowList[addresses[i]] = false;
		}
	}
	
	function isAddressAllowed(address addr) external view returns (bool) {
		return _allowList[addr];
	}

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

	function getTotalSupply() public view returns (uint256) {
		return totalSupply();
	}
	
	function getTokenByOwner(address _owner) public view returns (uint256[] memory) {
		uint256 tokenCount = balanceOf(_owner);
		uint256[] memory tokenIds = new uint256[](tokenCount);
		for (uint256 i; i < tokenCount; i++) {
			tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
		}
		return tokenIds;
	}
	
	function startPreSale() public onlyOwner() {
		_isPreSaleActive = true;
		emit PreSaleStarted();
	}

	function pausePreSale() public onlyOwner() {
		_isPreSaleActive = false;
		emit PreSaleStopped();
	}
	
	function isPreSaleActive() public view returns (bool) {
		return _isPreSaleActive;
	}
	
	function startPublicSale() public onlyOwner() {
		_isPublicSaleActive = true;
		emit PublicSaleStarted();
	}

	function pausePublicSale() public onlyOwner() {
		_isPublicSaleActive = false;
		emit PublicSaleStopped();
	}
	
	function isPublicSaleActive() public view returns (bool) {
		return _isPublicSaleActive;
	}
	
	function withdraw() public isOwner() nonReentrant {
		uint256 currentBalance = address(this).balance;
		
		require(payable(owner0).send((currentBalance / 1000) * 200), "Wrong.");
		require(payable(owner1).send((currentBalance / 1000) * 200), "Wrong.");
		require(payable(owner2).send((currentBalance / 1000) * 165), "Wrong.");
		require(payable(owner3).send((currentBalance / 1000) * 200), "Wrong.");
		require(payable(owner4).send((currentBalance / 1000) * 200), "Wrong.");
		require(payable(owner5).send((currentBalance / 1000) * 35), "Wrong.");
	}
	
	function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
		require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
		
		if(tokenId < MAX_SUPPLY) {
			return string(abi.encodePacked(_baseURI(), tokenId.toString(), ".json"));
		} else {
			return "ERC721Metadata: URI query for nonexistent token - Invalid token ID";
		}
	}
	
	function mintPresale(uint8 TOKENS_TO_MINT) public payable isRealUser nonReentrant {
		require(_isPreSaleActive, "Sorry, pre-sales is not active yet.");
		require((totalSupply() + TOKENS_TO_MINT) <= MAX_VOLUME_MINTABLE , "Exceeding max supply");
		require(_allowList[msg.sender] == true, "Sorry, you are not whitelisted.");
		require(TOKENS_TO_MINT <= 5 && TOKENS_TO_MINT > 0, "Sorry, you are trying to mint too many tokens at one time");
		require(PRICE*TOKENS_TO_MINT <= msg.value, "Sorry, you did not sent the required amount of ETH");
		require((_stock[msg.sender] + TOKENS_TO_MINT) <= 5, "You are trying to mint too many tokens.");
		
		_allowList[msg.sender] = false;
		_mint(TOKENS_TO_MINT, msg.sender);
	}
	
	function mintPublic(uint8 TOKENS_TO_MINT) public payable isRealUser nonReentrant {
		require(_isPublicSaleActive, "Sorry, public-sales are not active yet.");
		require((totalSupply() + TOKENS_TO_MINT) <= MAX_VOLUME_MINTABLE , "Exceeding max supply");
		require(TOKENS_TO_MINT <= 10 && TOKENS_TO_MINT > 0, "Sorry, you are trying to mint too many tokens at one time");
		require(PRICE*TOKENS_TO_MINT <= msg.value, "Sorry, you did not sent the required amount of ETH");
		require((_stock[msg.sender] + TOKENS_TO_MINT) <= 10, "You are trying to mint too many tokens.");
		
		_mint(TOKENS_TO_MINT, msg.sender);
		_stock[msg.sender] += TOKENS_TO_MINT;
	}
	
	function _mint(uint256 num, address recipient) internal {
		uint256 supply = totalSupply();
		for (uint256 i = 0; i < num; i++) {
			_safeMint(recipient, supply + i);
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
}