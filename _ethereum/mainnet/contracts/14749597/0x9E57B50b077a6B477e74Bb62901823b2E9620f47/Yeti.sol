// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./Authority.sol";
import "./ILogic.sol";


contract Yeti is ERC721, ERC721Enumerable, Authority {
	using Counters for Counters.Counter;

	Counters.Counter private _tokenIdCounter;

	string private uriBase;
	
	bool public openMintNft = false;

	mapping(address => bool) public isBlacklisted;
	bool public onlyAuthorizedContracts = true;
	mapping(address => bool) public isAuthorizedContract;
	
	uint public constant maxNft = 50000;

	address public logic;

	constructor(
		string memory uri
	) ERC721("YETI", "YETI") {
		uriBase = uri;
	}

	// Modifiers
	modifier isAuthorized(address addr) {
		require(!isBlacklisted[addr], "Yeti: Blacklisted");
		require(!onlyAuthorizedContracts || 
				isAuthorizedContract[addr] || 
				_isNotContract(addr),
			"Yeti: Unauthorized address");
		_;
	}

	// Core
	function safeMint() external isAuthorized(msg.sender) {
		require(openMintNft, "Yeti: Minting closed");

		uint tokenId = _tokenIdCounter.current();

		require(tokenId < maxNft, "Yeti: All nfts are already minted");

		_safeMint(msg.sender, tokenId);
		_tokenIdCounter.increment();

		ILogic(logic).safeMint(msg.sender, tokenId);
	}

	function safeClaim(uint tokenId, bool stake) external {
		address owner = ownerOf(tokenId); // gas

		require(owner == msg.sender || isAuthority[msg.sender], "Yeti: Not Owner");
		require(!isBlacklisted[owner], "Yeti: Blacklisted");

		ILogic(logic).safeClaim(owner, tokenId, stake);
	}
	
	function safeMintBatch(uint count) external isAuthorized(msg.sender) {
		require(openMintNft, "Yeti: Minting closed");

		require(count > 0, "Yeti: count lower than 1");

		uint[] memory tokenIds = new uint[](count);

		for (uint i = 0; i < count; i++) {
			tokenIds[i] = _tokenIdCounter.current();
			_safeMint(msg.sender, tokenIds[i]);
			_tokenIdCounter.increment();
		}

		require(tokenIds[count - 1] < maxNft, "Yeti: All nfts are already minted");

		ILogic(logic).safeMintBatch(msg.sender, tokenIds);
	}
	
	function safeClaimBatch(uint[] calldata tokenIds, bool stake) external {
		require(tokenIds.length > 0, "Yeti: count lower than 1");

		address owner = ownerOf(tokenIds[0]);

		require(owner == msg.sender || isAuthority[msg.sender], "Yeti: Not Owner");
		require(!isBlacklisted[owner], "Yeti: Blacklisted");

		for (uint i = 1; i < tokenIds.length; i++) {
			require(ownerOf(tokenIds[i]) == owner, 
				"Yeti: Owner Discrepency");
		}

		ILogic(logic).safeClaimBatch(owner, tokenIds, stake);
	}

	// Setters
	function setOpenMintNft(bool _new) external onlyAuthority {
		openMintNft = _new;
	}
	
	function setLogic(address _new) external onlyAuthority {
		logic = _new;
	}

	function setUriBase(string calldata _new) external onlyAuthority {
		uriBase = _new;
	}

	function setIsBlacklisted(address _new, bool _value) external onlyAuthority {
		isBlacklisted[_new] = _value;
	}

	function setOnlyAuthorizedContracts(bool _new) external onlyAuthority {
		onlyAuthorizedContracts = _new;
	}

	function setIsAuthorizedContract(address _new, bool _value) external onlyAuthority {
		isAuthorizedContract[_new] = _value;
	}

	// Web3
	function baseURI() external view returns(string memory) {
		return _baseURI();
	}

	function tokensOfOwner(address user) external view returns(uint256[] memory) {
		uint balance = balanceOf(user); // gas
		uint[] memory result = new uint256[](balance);
		for(uint i = 0; i < balance; i++)
			result[i] = tokenOfOwnerByIndex(user, i);
		return result;
	}

	function tokensOfOwnerByIndexesBetween(
		address user,
		uint iStart,
		uint iEnd
	)
		external
		view
		returns(uint[] memory)
	{
		uint[] memory result = new uint256[](iEnd - iStart);
		for(uint i = iStart; i < iEnd; i++)
			result[i - iStart] = tokenOfOwnerByIndex(user, i);
		return result;
	}

	// Internal
	function _isNotContract(address addr) internal view returns (bool) {
		uint size;
		assembly { size := extcodesize(addr) }
		return size == 0;
	}

	// Overrides
	function supportsInterface(bytes4 interfaceId)
		public
		view
		override(ERC721, ERC721Enumerable)
		returns (bool)
	{
		return super.supportsInterface(interfaceId);
	}

	function _baseURI() internal view override returns(string memory) {
		return uriBase;
	}

	function _beforeTokenTransfer(
		address from,
		address to,
		uint256 tokenId
	)
		internal
		override(ERC721, ERC721Enumerable)
	{
		super._beforeTokenTransfer(from, to, tokenId);
	}

	function _setApprovalForAll(
		address owner,
		address operator,
		bool approved
	)
		internal
		override(ERC721)
		isAuthorized(owner)
		isAuthorized(operator)
	{
		super._setApprovalForAll(owner, operator, approved);
	}

	function _approve(
		address to, 
		uint256 tokenId
	) 
		internal 
		override(ERC721)
		isAuthorized(to)
	{
		super._approve(to, tokenId);
	}

	function _transfer(
		address from,
		address to,
		uint256 tokenId
	)
		internal
		override
		isAuthorized(from)
		isAuthorized(to)
	{
		super._transfer(from, to, tokenId);
	}
}
