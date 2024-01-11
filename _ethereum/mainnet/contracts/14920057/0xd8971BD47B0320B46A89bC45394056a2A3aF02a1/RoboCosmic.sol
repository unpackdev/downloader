// SPDX-License-Identifier: MIT

// ======================================= #
//  Official Deployed RoboCosmic Contract  #
// ======================================= #
// Dev: twitter.com/shinerNFT
// ...to the moon!

pragma solidity ^0.8.7;

import "./ERC721A.sol";
import "./Ownable.sol";

interface OpenSea { function proxies(address) external view returns (address); }

contract RoboCosmic is ERC721A, Ownable
{
	uint256 public constant MAX_SUPPLY = 11111;
	uint256 public constant PER_MINT_PRICE = 0.01 ether;
	string internal _baseTokenURI = 'https://metadata.robocosmic.online/';
	bool public _paused = true;
	string internal _baseContractURI;

	constructor(string memory _contractURI) ERC721A('RoboCosmic', 'RBC')
	{
		_baseContractURI = _contractURI;
		_mint(owner(), 25); // Initial Mint
	}

	modifier onlyAccounts() { require(msg.sender == tx.origin, 'NO_ALLOWED_ORIGIN'); _; }

	function mint(uint256 quantity)
		external
		payable
		onlyAccounts
	{
		require(_paused == false, 'SALE_CLOSED');
		require(_numberMinted(msg.sender) == 0, 'MAX_EXCEEDED');
		require(quantity == 1 || quantity == 6, 'WRONG_QUANTITY');
		uint256 currentPrice = quantity == 1 ? 0 : ((quantity * PER_MINT_PRICE) - PER_MINT_PRICE);
		require(currentPrice == msg.value, 'WRONG_ETH_AMOUNT');
		require(_totalMinted() + quantity <= MAX_SUPPLY, 'MAX_SUPPLY_EXCEEDED');

		_mint(msg.sender, quantity);
	}

	function mintSpecific(address[] calldata _addresses)
		public
		onlyOwner
	{
		require(_addresses.length > 0, "NO_PROVIDED_ADDRESSES");
		require(_addresses.length + _totalMinted() <= MAX_SUPPLY, "MAX_SUPPLY_EXCEEDED");

		for (uint i = 0; i < _addresses.length;)
		{
			_mint(_addresses[i], 1);
			unchecked { i++; }
		}
	}

	function flipStatus()
		external
		onlyOwner
	{
		_paused = !_paused;
	}

	function setBaseURI(string memory baseTokenURI)
		external
		onlyOwner
	{
		_baseTokenURI = baseTokenURI;
	}

	function setContractURI(string memory _contractURI)
		external
		onlyOwner
	{
		_baseContractURI = _contractURI;
	}

	function _baseURI()
		internal
		view
		override(ERC721A)
		returns (string memory)
	{
		return _baseTokenURI;
	}

	function contractURI()
		public
		view
		returns (string memory)
	{
		return _baseContractURI;
	}

	function numberMinted(address _address)
		external
		view
		returns (uint256)
	{
		return _numberMinted(_address);
	}

	function withdraw()
		external
		onlyOwner
	{
		(bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
		require(success, "Transfer failed.");
	}

	function _startTokenId()
		internal
		view
		virtual
		override(ERC721A)
		returns (uint256)
	{
		return 1;
	}

	function isApprovedForAll(address owner, address operator)
		public
		view
		override(ERC721A)
		returns (bool)
	{
		// OPENSEA
		if (operator == OpenSea(0xa5409ec958C83C3f309868babACA7c86DCB077c1).proxies(owner)) return true;
		// LOOKSRARE
		else if (operator == 0xf42aa99F011A1fA7CDA90E5E98b277E306BcA83e) return true;
		// RARIBLE
		else if (operator == 0x4feE7B061C97C9c496b01DbcE9CDb10c02f0a0Be) return true;
		// X2Y2
		else if (operator == 0xF849de01B080aDC3A814FaBE1E2087475cF2E354) return true;

		return super.isApprovedForAll(owner, operator);
	}
}
