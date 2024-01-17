// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
 * Copyright (c) 2022 Mighty Bear Games
 */

import "./ERC721PausableUpgradeable.sol";
import "./ERC721BurnableUpgradeable.sol";
import "./ERC721RoyaltyUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";

import "./IMightyNetGenesisPass.sol";

error Unauthorized();

contract MightyNetGenesisPass is
	ERC721PausableUpgradeable,
	ERC721BurnableUpgradeable,
	ERC721RoyaltyUpgradeable,
	OwnableUpgradeable,
	AccessControlUpgradeable,
	ReentrancyGuardUpgradeable,
	IMightyNetGenesisPass
{
	// ------------------------------
	// 			V1 Variables
	// ------------------------------

	// Metadata
	string public baseURI;
	string public contractURI;

	// Minting
	address public minter;

	/*
	 * DO NOT ADD OR REMOVE VARIABLES ABOVE THIS LINE. INSTEAD, CREATE A NEW VERSION SECTION BELOW.
	 * MOVE THIS COMMENT BLOCK TO THE END OF THE LATEST VERSION SECTION PRE-DEPLOYMENT.
	 */

	function initialize(string memory baseURI_, string memory contractURI_)
		public
		initializer
	{
		// Call parent initializers
		__ERC721_init("MightyNet Genesis Pass", "1337");
		__ERC721Pausable_init();
		__ERC721Burnable_init();
		__ERC721Royalty_init();
		__Ownable_init();
		__AccessControl_init();
		__ReentrancyGuard_init();

		// Set defaults
		_grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

		_setDefaultRoyalty(msg.sender, 750);

		// Set constructor arguments
		setBaseURI(baseURI_);
		setContractURI(contractURI_);
	}

	// ------------------------------
	// 			  Minting
	// ------------------------------

	function mint(address to, uint256 tokenId)
		external
		override
		nonReentrant
		whenNotPaused
		onlyMinter
	{
		_mint(to, tokenId);
	}

	// ------------------------------
	// 			 Burning
	// ------------------------------

	function _burn(uint256 tokenId)
		internal
		virtual
		override(ERC721Upgradeable, ERC721RoyaltyUpgradeable)
	{
		super._burn(tokenId);
	}

	// ------------------------------
	// 			 Transfers
	// ------------------------------

	function _beforeTokenTransfer(
		address from,
		address to,
		uint256 tokenId
	)
		internal
		virtual
		override(ERC721Upgradeable, ERC721PausableUpgradeable)
		whenNotPaused
	{
		super._beforeTokenTransfer(from, to, tokenId);
	}

	// ------------------------------
	// 			  Queries
	// ------------------------------

	function exists(uint256 tokenId) external view returns (bool) {
		return _exists(tokenId);
	}

	// ------------------------------
	// 			  Metadata
	// ------------------------------

	function _baseURI() internal view override returns (string memory) {
		return baseURI;
	}

	// ------------------------------
	// 			  Pausing
	// ------------------------------

	function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
		_pause();
	}

	function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
		_unpause();
	}

	// ------------------------------
	// 			 Royalties
	// ------------------------------

	function setDefaultRoyalty(address receiver, uint96 feeNumerator)
		external
		onlyRole(DEFAULT_ADMIN_ROLE)
	{
		_setDefaultRoyalty(receiver, feeNumerator);
	}

	function deleteDefaultRoyalty() external onlyRole(DEFAULT_ADMIN_ROLE) {
		_deleteDefaultRoyalty();
	}

	function setTokenRoyalty(
		uint256 tokenId,
		address receiver,
		uint96 feeNumerator
	) external onlyRole(DEFAULT_ADMIN_ROLE) {
		_setTokenRoyalty(tokenId, receiver, feeNumerator);
	}

	function resetTokenRoyalty(uint256 tokenId)
		external
		onlyRole(DEFAULT_ADMIN_ROLE)
	{
		_resetTokenRoyalty(tokenId);
	}

	// ------------------------------
	// 			  Setters
	// ------------------------------

	function setBaseURI(string memory baseURI_)
		public
		onlyRole(DEFAULT_ADMIN_ROLE)
	{
		baseURI = baseURI_;
	}

	function setContractURI(string memory contractURI_)
		public
		onlyRole(DEFAULT_ADMIN_ROLE)
	{
		contractURI = contractURI_;
	}

	function setMinter(address minter_) public onlyRole(DEFAULT_ADMIN_ROLE) {
		minter = minter_;
	}

	// ------------------------------
	// 			  Modifiers
	// ------------------------------

	modifier onlyMinter() {
		if (msg.sender != minter) {
			revert Unauthorized();
		}
		_;
	}

	// ------------------------------
	// 		   Miscellaneous
	// ------------------------------

	function supportsInterface(bytes4 interfaceId)
		public
		view
		virtual
		override(
			ERC721Upgradeable,
			ERC721RoyaltyUpgradeable,
			IERC165Upgradeable,
			AccessControlUpgradeable
		)
		returns (bool)
	{
		return super.supportsInterface(interfaceId);
	}
}
