// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./MultiOwnable.sol";
import "./ReentrancyGuard.sol";

contract UEPlots is ERC721Enumerable, MultiOwnable, ReentrancyGuard {
	using Strings for uint256;

	uint256 private constant START_TOKEN_ID = 100000;

	mapping(address => bool) public whitelistClaimed;
	uint256 public numWhitelistClaimed = 0;
	bool public whitelistEnabled = false;

	mapping(address => uint256) public whitelist;
	mapping(address => address) _nextWhitelistMember;
	uint256 public listSize = 0;
	address constant GUARD = address(1);

	string public baseUri = 'https://metadata.unrealestates.io/';

	uint256 public cost;
	uint256 public maxSupply;

	constructor(
		string memory _tokenName,
		string memory _tokenSymbol,
		uint256 _maxSupply
	) ERC721(_tokenName, _tokenSymbol) {
		setCost(0);
		maxSupply = _maxSupply;
		_nextWhitelistMember[GUARD] = GUARD;
	}

	function contractURI() public pure returns (string memory) {
		return 'https://metadata.unrealestates.io/contract';
	}

	function inWhitelist(address add) internal view returns (bool) {
		return _nextWhitelistMember[add] != address(0);
	}

	function setWhitelistEnabled(bool _state) public onlyOwner {
		whitelistEnabled = _state;
	}

	function getWhitelist()
		public
		view
		returns (address[] memory _adds, uint256[] memory _tokenIDs)
	{
		address[] memory adds = new address[](listSize);
		uint256[] memory tokenIDs = new uint256[](listSize);

		address currentAddress = _nextWhitelistMember[GUARD];
		for (uint256 i = 0; currentAddress != GUARD; i++) {
			adds[i] = currentAddress;
			tokenIDs[i] = whitelist[currentAddress];
			currentAddress = _nextWhitelistMember[currentAddress];
		}
		return (adds, tokenIDs);
	}

	function addToWhitelist(address[] memory adds, uint256[] memory tokenIDs)
		public
		onlyOwner
	{
		require(
			adds.length == tokenIDs.length,
			'Different number of Addresses and TokenIDs!'
		);

		for (uint256 i = 0; i < adds.length; i++) {
			require(!inWhitelist(adds[i]), 'Address already in whitelist!');
		}

		for (uint256 i = 0; i < adds.length; i++) {
			whitelist[adds[i]] = tokenIDs[i];

			_nextWhitelistMember[adds[i]] = _nextWhitelistMember[GUARD];
			_nextWhitelistMember[GUARD] = adds[i];
		}
		listSize += adds.length;
	}

	function setWhitelistClaimed(address add, bool set) public onlyOwner {
		whitelistClaimed[add] = set;
	}

	function removeFromWhitelist(address[] memory adds) public onlyOwner {
		for (uint256 i = 0; i < adds.length; i++) {
			require(inWhitelist(adds[i]), 'Address not in whitelist!');
		}

		uint256 deleted = 0;
		for (uint256 i = 0; i < adds.length; i++) {
			address currentAddress = _nextWhitelistMember[GUARD];
			address prev = GUARD;
			address addressToDelete = adds[i];
			while (currentAddress != GUARD) {
				if (currentAddress == addressToDelete) {
					_nextWhitelistMember[prev] = _nextWhitelistMember[
						currentAddress
					];
					delete _nextWhitelistMember[currentAddress];
					delete whitelist[currentAddress];
					deleted++;
					break;
				}

				prev = currentAddress;
				currentAddress = _nextWhitelistMember[currentAddress];
			}
		}

		listSize -= deleted;
	}

	function emptyWhitelist() public onlyOwner {
		address currentAddress = _nextWhitelistMember[GUARD];
		for (uint256 i = 0; currentAddress != GUARD; i++) {
			address next = _nextWhitelistMember[currentAddress];

			delete _nextWhitelistMember[currentAddress];

			currentAddress = next;
		}
		_nextWhitelistMember[GUARD] = GUARD;
		listSize = 0;
	}

	modifier mintCompliance() {
		require(totalSupply() + 1 <= maxSupply, 'Max supply exceeded!');
		require(whitelistEnabled, 'Not enabled!');
		_;
	}

	modifier mintPriceCompliance() {
		require(msg.value >= cost, 'Insufficient funds!');
		_;
	}

	function whitelistMint(address _receiver) internal {
		require(!whitelistClaimed[_msgSender()], 'Address already claimed!');
		require(inWhitelist(_msgSender()), 'Address not in whitelist!');
		require(
			whitelist[_msgSender()] >= START_TOKEN_ID,
			'Address does not have a plot associated with it!'
		);

		uint256 tokenID = whitelist[_msgSender()];

		require(!_exists(tokenID), 'Token ID already exists!');

		_safeMint(_receiver, tokenID);

		whitelistClaimed[_msgSender()] = true;
		numWhitelistClaimed++;
	}

	function mint() public payable mintCompliance mintPriceCompliance {
		whitelistMint(_msgSender());
	}

	function whitelistMintSpecific(address _receiver, uint256 tokenID)
		internal
	{
		require(!_exists(tokenID), 'Token ID already exists.');
		require(inWhitelist(_msgSender()), 'Address not in whitelist!');
		require(
			whitelist[_msgSender()] == 1,
			'Address not allowed to mint specific NFTs!'
		);

		_safeMint(_receiver, tokenID);
	}

	function mintSpecific(uint256 tokenID)
		public
		payable
		mintCompliance
		mintPriceCompliance
	{
		whitelistMintSpecific(_msgSender(), tokenID);
	}

	function mintSpecificForAddress(address _receiver, uint256 tokenID)
		public
		payable
		mintCompliance
		mintPriceCompliance
	{
		whitelistMintSpecific(_receiver, tokenID);
	}

	function walletOfOwner(address _owner)
		public
		view
		returns (uint256[] memory)
	{
		uint256 ownerTokenCount = balanceOf(_owner);
		uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);

		for (uint256 i = 0; i < ownerTokenCount; i++) {
			ownedTokenIds[i] = tokenOfOwnerByIndex(_owner, i);
		}

		return ownedTokenIds;
	}

	function tokenURI(uint256 _tokenId)
		public
		view
		virtual
		override
		returns (string memory)
	{
		require(_exists(_tokenId), 'URI query for nonexistent token');

		string memory currentBaseURI = _baseURI();
		return
			bytes(currentBaseURI).length > 0
				? string(abi.encodePacked(currentBaseURI, _tokenId.toString()))
				: '';
	}

	function setBasePrefix(string memory uri) public onlyOwner {
		baseUri = uri;
	}

	function withdraw() public onlyOwner nonReentrant {
		// This will transfer the remaining contract balance to the owner.
		// Do not remove this otherwise you will not be able to withdraw the funds.
		// =============================================================================
		(bool os, ) = payable(owner()).call{ value: address(this).balance }('');
		require(os);
		// =============================================================================
	}

	function setCost(uint256 _cost) public onlyOwner {
		cost = _cost;
	}

	function _baseURI() internal view virtual override returns (string memory) {
		return baseUri;
	}
}
