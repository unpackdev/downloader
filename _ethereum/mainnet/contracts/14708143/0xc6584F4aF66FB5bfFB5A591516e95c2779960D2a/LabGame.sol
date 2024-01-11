// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ERC721EnumerableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./Generator.sol";
import "./Whitelist.sol";

import "./ISerum.sol";
import "./IMetadata.sol";
import "./IBlueprint.sol";

error NotWhitelisted(address _account);
error InvalidMintAmount(uint256 _amount);
error LimitExceeded(address _account);
error SoldOut();
error GenerationLimit(uint256 _generation);
error NotEnoughEther(uint256 _given, uint256 _expected);
error InvalidBurnLength(uint256 _given, uint256 _expected);
error BurnNotOwned(address _sender, uint256 _tokenId);
error InvalidBurnGeneration(uint256 _given, uint256 _expected);
error BlueprintNotReady();
error EarlyMintIsEnabled();
error EarlyMintNotEnabled();

// LabGame V2.0
contract LabGame is ERC721EnumerableUpgradeable, OwnableUpgradeable, PausableUpgradeable, Generator, Whitelist {
	uint256 constant GEN0_PRICE = 0 ether; // @since V2.0 Free mint
	uint256 constant GEN1_PRICE = 5_000 ether;
	uint256 constant GEN2_PRICE = 12_500 ether;
	uint256 constant GEN3_PRICE = 45_000 ether;
	
	uint256 constant GEN0_MAX = 1_111;
	uint256 constant GEN1_MAX = 2_222;
	uint256 constant GEN2_MAX = 3_333;
	uint256 constant GEN3_MAX = 4_444;

	uint256 constant WHITELIST_MINT_LIMIT = 2;
	uint256 constant PUBLIC_MINT_LIMIT = 5;
	uint256 constant EXTRA_MINT_LIMIT = 20;

	uint256 constant MAX_TRAITS = 16;
	uint256 constant TYPE_OFFSET = 9;

	mapping(uint256 => uint256) tokens;
	mapping(address => uint256) whitelistMints;
	mapping(address => uint256) publicMints;

	uint256 tokenOffset;

	ISerum public serum;
	IMetadata public metadata;
	IBlueprint public blueprint;

	uint8[][MAX_TRAITS] rarities;
	uint8[][MAX_TRAITS] aliases;

	bool public earlyMintEnabled; // @since V2.0
	mapping(address => bool) public extraMintAccounts;

	/**
	 * LabGame constructor
	 * @param _name ERC721 name
	 * @param _symbol ERC721 symbol
	 * @param _serum Serum contract address
	 * @param _metadata Metadata contract address
	 * @param _vrfCoordinator VRF Coordinator address
	 * @param _keyHash Gas lane key hash
	 * @param _subscriptionId VRF subscription id
	 * @param _callbackGasLimit VRF callback gas limit
	 */
	function initialize(
		string memory _name,
		string memory _symbol,
		address _serum,
		address _metadata,
		address _vrfCoordinator,
		bytes32 _keyHash,
		uint64 _subscriptionId,
		uint32 _callbackGasLimit
	) public initializer {
		__ERC721_init(_name, _symbol);
		__Ownable_init();
		__Pausable_init();
		__Generator_init(_vrfCoordinator, _keyHash, _subscriptionId, _callbackGasLimit);
		__Whitelist_init();

		serum = ISerum(_serum);
		metadata = IMetadata(_metadata);

		// Setup rarity and alias tables for token traits
		rarities[0] = [255, 255, 255, 255, 255, 255, 255, 255];
		aliases[0] = [0, 0, 0, 0, 0, 0, 0, 0];

		rarities[1] = [89, 236, 255, 44, 179, 249, 134];
		aliases[1] = [2, 2, 0, 1, 5, 2, 5];

		rarities[2] = [50, 73, 96, 119, 142, 164, 187, 210, 233, 255, 28];
		aliases[2] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 0];

		rarities[3] = [255, 128, 255, 192, 128, 192, 255, 255, 255, 64, 255, 255, 64, 255, 128, 255, 128, 128, 255, 128, 255, 255, 128, 255, 255];
		aliases[3] = [0, 6, 0, 24, 7, 24, 0, 0, 0, 3, 0, 0, 5, 0, 8, 0, 11, 15, 0, 18, 0, 0, 20, 0, 0];

		rarities[4] = [199, 209, 133, 255, 209, 209, 255, 133, 255, 133, 199, 255, 199, 66, 66, 199, 255, 133, 255, 255, 66, 255, 255, 66, 250, 240];
		aliases[4] = [22, 24, 8, 0, 24, 25, 0, 11, 0, 16, 24, 0, 25, 25, 1, 22, 0, 19, 0, 0, 4, 0, 0, 5, 8, 22];

		rarities[5] = [255, 204, 255, 204, 40, 235, 204, 204, 235, 204, 204, 40, 204, 204, 204, 204];
		aliases[5] = [0, 5, 0, 8, 0, 0, 5, 8, 2, 5, 8, 2, 5, 8, 5, 8];

		rarities[6] = [158, 254, 220, 220, 158, 158, 220, 220, 220, 220, 158, 158, 238, 79, 158, 238, 79, 220, 220, 238, 158, 220, 245, 245, 245, 253, 158, 255, 253, 158, 253];
		aliases[6] = [2, 27, 22, 23, 3, 6, 24, 25, 28, 30, 7, 8, 25, 1, 9, 28, 27, 22, 23, 30, 17, 24, 25, 28, 30, 1, 18, 0, 27, 21, 1];

		rarities[7] = [255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255];
		aliases[7] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];

		rarities[8] = [112, 112, 160, 160, 208, 64, 64, 208, 255, 255];
		aliases[8] = [2, 3, 4, 7, 8, 0, 1, 9, 0, 0];

		rarities[9] = [255, 255, 255, 255, 255, 255, 255, 255];
		aliases[9] = [0, 0, 0, 0, 0, 0, 0, 0];

		rarities[10] = [235, 250, 46, 30, 255, 76];
		aliases[10] = [4, 4, 1, 0, 0, 4];

		rarities[11] = [153, 204, 255, 102];
		aliases[11] = [1, 2, 0, 0];

		rarities[12] = [81, 138, 133, 30, 184, 189, 189, 138, 235, 240, 240, 255];
		aliases[12] = [2, 5, 4, 0, 8, 9, 10, 6, 11, 11, 11, 0];

		rarities[13] = [255, 255, 255, 255, 255, 255, 255, 255];
		aliases[13] = [0, 0, 0, 0, 0, 0, 0, 0];

		rarities[14] = [76, 192, 255];
		aliases[14] = [2, 2, 0];

		rarities[15] = [236, 236, 224, 224, 249, 249, 255];
		aliases[15] = [4, 5, 0, 1, 6, 6, 0];
	}

	// -- EXTERNAL --

	// @since V2.0 - Whitelist mint no longer needed

	/**
	 * Mint scientists & mutants
	 * @param _amount Number of tokens to mint
	 * @param _burnIds Token Ids to burn as payment (for gen 1 & 2)
	 */
	function mint(uint256 _amount, uint256[] calldata _burnIds) external payable whenNotPaused {
		if (earlyMintEnabled)
			revert EarlyMintIsEnabled();

		uint256 publicMintCount = publicMints[_msgSender()];

		// Verify amount
		// @since V2.0 Transaction limit of 10, account limit of 20
		if (_amount == 0 || _amount > PUBLIC_MINT_LIMIT) revert InvalidMintAmount(_amount);
		// Verify generation and price
		uint256 id = totalMinted();
		if (id >= GEN3_MAX) revert SoldOut();
		uint256 max = id + _amount;
		uint256 generation;

		// Generation 0
		if (id < GEN0_MAX) {
			if (max > GEN0_MAX) revert GenerationLimit(0);
			// @since V2.0 - No ether required to mint
			// Account limit of PUBLIC_MINT_LIMIT not including whitelist mints
			// @since V2.0 - Fix underflow bug
			uint256 currentBalance = balanceOf(_msgSender());
			uint256 whitelistMintCount = whitelistMints[_msgSender()];
			if (
				(currentBalance >= whitelistMintCount && currentBalance - whitelistMintCount + _amount > PUBLIC_MINT_LIMIT) ||
				(publicMintCount + _amount > PUBLIC_MINT_LIMIT)
			)	revert LimitExceeded(_msgSender());

		// Generation 1
		} else if (id < GEN1_MAX) {
			if (max > GEN1_MAX) revert GenerationLimit(1);
			serum.burn(_msgSender(), _amount * GEN1_PRICE);
			generation = 1;

		// Generation 2
		} else if (id < GEN2_MAX) {
			if (max > GEN2_MAX) revert GenerationLimit(2);
			serum.burn(_msgSender(), _amount * GEN2_PRICE);
			generation = 2;

		// Generation 3
		} else if (id < GEN3_MAX) {
			if (address(blueprint) == address(0)) revert BlueprintNotReady();
			if (max > GEN3_MAX) revert GenerationLimit(3);
			serum.burn(_msgSender(), _amount * GEN3_PRICE);
			generation = 3;
		}

		// Burn tokens to mint gen 1, 2, and 3
		uint256 burnLength = _burnIds.length;
		if (generation != 0) {
			if (burnLength != _amount) revert InvalidBurnLength(burnLength, _amount);
			for (uint256 i; i < burnLength; i++) {
				// Verify token to be burned
				if (_msgSender() != ownerOf(_burnIds[i])) revert BurnNotOwned(_msgSender(), _burnIds[i]);
				if (tokens[_burnIds[i]] & 3 != generation - 1) revert InvalidBurnGeneration(tokens[_burnIds[i]] & 3, generation - 1);
				_burn(_burnIds[i]);
			}
			// Add burned tokens to id offset
			tokenOffset += burnLength;

		// Generation 0 no burn needed
		} else {
			if (burnLength != 0) revert InvalidBurnLength(burnLength, 0);
		}
		
		publicMints[_msgSender()] = publicMintCount + _amount;
		// Request token mint
		// @since V2.0 - Single transaction mint
		// Token id to mint in [id + 1, id + _amount]
		max++;
		for (uint i = id + 1; i < max; i++) {
			uint256 seed = _random(i);
			_revealToken(i, seed);
		}
	}

	function earlyMint(uint256 _amount) external whenNotPaused {
		if (!earlyMintEnabled) revert EarlyMintNotEnabled(); // Only when early mint enabled
		uint256 whitelistMintCount = whitelistMints[_msgSender()];
		uint256 publicMintCount = publicMints[_msgSender()];
		bool hasExtraMints = extraMintAccounts[_msgSender()];
		if (whitelistMintCount == 0 && publicMintCount == 0 && hasExtraMints == false)
			revert EarlyMintIsEnabled();

		uint256 limit = hasExtraMints ? EXTRA_MINT_LIMIT : PUBLIC_MINT_LIMIT;
		// Verify amount
		// @since V2.0 Transaction limit of 10, account limit of 20
		if (_amount == 0 || _amount > limit) revert InvalidMintAmount(_amount);
		// Verify generation and price
		uint256 id = totalMinted();
		uint256 max = id + _amount;
		if (id >= GEN0_MAX || max > GEN0_MAX) revert GenerationLimit(0);

		// @since V2.0 - No ether required to mint
		// Account limit of PUBLIC_MINT_LIMIT not including whitelist mints
		// @since V2.0 - Fix underflow bug
		uint256 currentBalance = balanceOf(_msgSender());
		if (
			(currentBalance >= whitelistMintCount && currentBalance - whitelistMintCount + _amount > limit) ||
			(publicMintCount + _amount > limit)
		)	revert LimitExceeded(_msgSender());

		publicMints[_msgSender()] = publicMintCount + _amount;
		// Request token mint
		// @since V2.0 - Single transaction mint
		// Token id to mint in [id + 1, id + _amount]
		max++;
		for (uint i = id + 1; i < max; i++) {
			_revealToken(i, _random(i));
		}
	}

	/**
	 * Reveal pending mints
	 */
	function reveal() external whenNotPaused {
		(, uint256 count) = pendingOf(_msgSender());
		_reveal(_msgSender());
		// Tokens minted, update offset
		tokenOffset -= count;
	}

	/**
	 * Get the metadata uri for a token
	 * @param _tokenId Token ID to query
	 * @return Token metadata json URI
	 */
	function tokenURI(uint256 _tokenId) public view override returns (string memory) {
		if (!_exists(_tokenId)) revert ERC721_QueryForNonexistentToken(_tokenId);
		return metadata.tokenURI(_tokenId);
	}

	/**
	 * Get the total number of minted tokens
	 * @return Total number of minted tokens
	 */
	function totalMinted() public view returns (uint256) {
		return totalSupply() + tokenOffset;
	}

	/**
	 * Get the data of a token
	 * @param _tokenId Token ID to query
	 * @return Token structure
	 */
	function getToken(uint256 _tokenId) external view returns (uint256) {
		if (!_exists(_tokenId)) revert ERC721_QueryForNonexistentToken(_tokenId);
		return tokens[_tokenId];
	}

	// -- INTERNAL --

	function _beforeTokenTransfer(address _from, address _to, uint256 _tokenId) internal override {
		super._beforeTokenTransfer(_from, _to, _tokenId);
		// Update serum claim on transfer and burn
		if (_from != address(0))
			serum.updateClaim(_from, _tokenId);
	}

	/**
	 * Generate and mint pending token using random seed
	 * @param _tokenId Token ID to reveal
	 * @param _seed Random seed
	 */
	function _revealToken(uint256 _tokenId, uint256 _seed) internal override {
		// Calculate generation of token
		uint256 token;
		if (_tokenId <= GEN0_MAX) {}
		else if (_tokenId <= GEN1_MAX) token = 1;
		else if (_tokenId <= GEN2_MAX) token = 2;
		else if (_tokenId <= GEN3_MAX) token = 3;
		// Select scientist or mutant
		// @since V2.0 Mint mutants at 2%
		token |= (((_seed & 0xFFFF) % 100) < 2) ? 128 : 0;
		// Loop over tokens traits (9 scientist, 8 mutant)
		(uint256 start, uint256 count) = (token & 128 != 0) ? (TYPE_OFFSET, MAX_TRAITS - TYPE_OFFSET) : (0, TYPE_OFFSET);
		for (uint256 i; i < count; i++) {
			_seed >>= 16;
			token |= _selectTrait(_seed, start + i) << (8 * i + 8);
		}
		// Save traits
		tokens[_tokenId] = token;
		// Mint token
		_safeMint(_msgSender(), _tokenId);
		// Setup serum claim for token
		serum.initializeClaim(_tokenId);
		// Mint blueprint to gen3 tokens
		if (token & 3 == 3)
			blueprint.mint(_msgSender(), _seed >> 16);
	}

	/**
	 * Select a trait from the alias tables using a random seed (16 bit)
	 * @param _seed Random seed
	 * @param _trait Trait to select
	 * @return Index of the selected trait
	 */
	function _selectTrait(uint256 _seed, uint256 _trait) internal view returns (uint256) {
		uint256 i = (_seed & 0xFF) % rarities[_trait].length;
		return (((_seed >> 8) & 0xFF) < rarities[_trait][i]) ? i : aliases[_trait][i];
	}

	/**
	 * Generate a psuedo-random number
	 * @param _seed Seed for the RNG
	 * @return Random 256 bit number
	 */
	function _random(uint256 _seed) internal view returns (uint256) {
		return uint256(keccak256(abi.encodePacked(
			tx.origin,
			blockhash(block.number - 1),
			block.timestamp,
			_seed
		)));
	}

	// -- OWNER --

	/**
	 * Enable/disable holder only early mint
	 */
	function setEarlyMintEnabled(bool _earlyMintEnabled) external onlyOwner {
		earlyMintEnabled = _earlyMintEnabled;
	}

	/**
	 * Add account to the early mint
	 * @param _accounts Account to add
	 */
	function addEarlyMintAccounts(address[] calldata _accounts) external onlyOwner {
		for (uint256 i; i < _accounts.length; i++)
			whitelistMints[_accounts[i]]++;
	}

	/**
	 * Add account to the extra mint list
	 * @param _accounts Account to add
	 */
	function addExtraMintAccounts(address[] calldata _accounts) external onlyOwner {
		for (uint256 i; i < _accounts.length; i++)
			extraMintAccounts[_accounts[i]] = true;
	}

	/**
	 * Pause the contract
	 */
	function pause() external onlyOwner {
		_pause();
	}
	
	/**
	 * Unpause the contract
	 */
	function unpause() external onlyOwner {
		_unpause();
	}

	/**
	 * Set blueprint contract
	 * @param _blueprint Address of the blueprint contract
	 */
	function setBlueprint(address _blueprint) external onlyOwner {
		blueprint = IBlueprint(_blueprint);
	}

	/**
	 * Withdraw funds to owner
	 */
	function withdraw() external onlyOwner {
		(bool os, ) = payable(owner()).call{value: address(this).balance}("");
		require(os);
	}
}