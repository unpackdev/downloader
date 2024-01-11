// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./ECDSA.sol";
import "./ERC721Enumerable.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract MoonMuttz is ERC721, Ownable {
	using Address for address;
	using Strings for uint256;
	using SafeMath for uint256;

	// Base URI
	string private _nftBaseURI = 'ipfs://bafybeih77vtcpbini7uhz25xkfjdengkiw3xnodwd3oeegytsmzymksz2i/';
	string private _extension = '.json';

	// Token Supply
	uint256 private immutable _totalSupply = 10000;
	uint256 private immutable _totalPresaleSupply = 3000;
	uint256 private currentSupply = 0;
	uint256 private maxPerWallet = 5;

	// Date of release;
	uint256 public releaseTimestamp = 1660856400;

	// Token Price
	uint256 public tokenPrice = 0.08 ether;
	uint256 public presalePrice = 0.06 ether;

	// Contract Owner
	address private _contractOwner;
	address private _signer;

	// Mapping from token ID to owner address
	mapping(uint256 => address) private _owners;

	// Mapping owner address to token count
	mapping(address => uint256) private _balances;

	bool public preSaleActive = true;
	bool public publicSaleActive = false;

	// events
	event tokensMinted(address mintedBy, uint256 numberOfTokensMinted);

	event baseUriUpdated(string oldBaseUri, string newBaseUri);

	constructor() ERC721('Moon Muttz', 'Muttz') {
		_contractOwner = _msgSender();
	}

	function getSignerAddress(address caller, bytes calldata signature) internal pure returns (address) {
		bytes32 dataHash = keccak256(abi.encodePacked(caller));

		bytes32 message = ECDSA.toEthSignedMessageHash(dataHash);
		return ECDSA.recover(message, signature);
	}

	function getCurrentPrice() public view returns (uint256) {
		if (preSaleActive) {
			return presalePrice;
		} else {
			return tokenPrice;
		}
	}

	function buyTokensOnPresale(uint256 tokensNumber, bytes calldata signature) public payable {
		require(preSaleActive, 'Sale is closed at this moment');
		require(block.timestamp >= releaseTimestamp, 'Purchase is not available now');
		require(tokensNumber <= maxPerWallet, 'You cannot purchase more than 5 tokens at once');
		require(
			(tokensNumber.mul(getCurrentPrice())) == msg.value,
			"Received value doesn't match the requested tokens"
		);
		require(
			(currentSupply.add(tokensNumber)) <= _totalPresaleSupply,
			'You try to mint more tokens than totalPresaleSupply'
		);

		address signer = getSignerAddress(msg.sender, signature);
		require(signer != address(0) && signer == _signer, 'claim: Invalid signature!');
		mint(tokensNumber);
	}

	function buyTokens(uint256 tokensNumber) public payable {
		require(publicSaleActive, 'Sale is closed at this moment');
		require(tokensNumber <= maxPerWallet, 'You cannot purchase more than 5 tokens at once');
		require((tokensNumber.mul(getCurrentPrice())) == msg.value, 'Received value doesnt match the requested tokens');
		require((currentSupply.add(tokensNumber)) <= _totalSupply, 'You try to mint more tokens than totalSupply');

		mint(tokensNumber);
	}

	function mint(uint256 tokensNumber) internal {
		for (uint256 i = 0; i < tokensNumber; i++) {
			currentSupply++;
			_safeMint(msg.sender, currentSupply);
		}
	}

	function withdraw() public onlyOwner {
		uint256 value = address(this).balance;
		bool sent = payable(_msgSender()).send(value);
		require(sent, 'Error during withdraw transfer');
	}

	function setReleaseDate(uint256 _releaseTimestamp) public onlyOwner {
		require(_releaseTimestamp > block.timestamp, 'timestamp should be greater than block timestamp');
		releaseTimestamp = _releaseTimestamp;
	}

	function totalSupply() external view returns (uint256) {
		return currentSupply;
	}

	function triggerPresale() public onlyOwner {
		require(!publicSaleActive, 'Public sale already active');

		preSaleActive = !preSaleActive;
	}

	function changePresalePrice(uint256 _newPresalePrice) public onlyOwner {
		presalePrice = _newPresalePrice;
	}

	function changeTokenPrice(uint256 _newTokenPrice) public onlyOwner {
		tokenPrice = _newTokenPrice;
	}

	function activatePublicSale() public onlyOwner {
		require(!preSaleActive, 'Deactivate pre-sale first');
		publicSaleActive = !publicSaleActive;
	}

	function setBaseURI(string memory newBaseURI) public onlyOwner {
		string memory currentURI = _nftBaseURI;
		_nftBaseURI = newBaseURI;
		emit baseUriUpdated(currentURI, newBaseURI);
	}

	function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
		require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');

		string memory baseURI = _baseURI();
		return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), _extension)) : '';
	}

	function _baseURI() internal view override returns (string memory) {
		return _nftBaseURI;
	}

	function changeSignerAddress(address newSigner) public onlyOwner {
		_signer = newSigner;
	}
}
