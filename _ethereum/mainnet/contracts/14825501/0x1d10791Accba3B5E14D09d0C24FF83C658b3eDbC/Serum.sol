// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ERC20Upgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./IClaimable.sol";

import "./ILabGame.sol";

error NotReady();
error NotOwned(address _account, uint256 _tokenId);
error NotAuthorized(address _sender, address _expected);

// Serum V2.0
contract Serum is ERC20Upgradeable, AccessControlUpgradeable, PausableUpgradeable, IClaimable {
	bytes32 public constant CONTROLLER_ROLE = keccak256("CONTROLLER_ROLE");
	
	uint256 constant GEN0_RATE = 1000 ether;
	uint256 constant GEN1_RATE = 1200 ether;
	uint256 constant GEN2_RATE = 1500 ether;
	uint256 constant GEN3_RATE = 2000 ether;

	uint256 constant GEN0_TAX = 100; // 10.0%
	uint256 constant GEN1_TAX = 125; // 12.5%
	uint256 constant GEN2_TAX = 150; // 15.0%
	uint256 constant GEN3_TAX = 200; // 20.0%

	uint256 constant CLAIM_PERIOD = 1 days;

	uint256 constant TOTAL_SUPPLY = 277750000 ether; // @since V2.0

	mapping(uint256 => uint256) public tokenClaims; // tokenId => value

	uint256[4] public mutantEarnings;
	uint256[4] public mutantCounts;

	mapping(address => uint256) public pendingClaims; 

	ILabGame public labGame;

	/**
	 * Token constructor, sets owner permission
	 * @param _name ERC20 token name
	 * @param _symbol ERC20 token symbol
	 */
	function initialize(
		string memory _name,
		string memory _symbol
	) public initializer {
		__ERC20_init(_name, _symbol);
		__AccessControl_init();
		__Pausable_init();
		_setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
	}

	// -- EXTERNAL --

	/**
	 * Claim rewards for owned tokens
	 */
	function claim() external override whenNotPaused {
		uint256 totalSerum = totalSupply();
		if (totalSerum >= TOTAL_SUPPLY)
			revert NoClaimAvailable(_msgSender());

		uint256 count = labGame.balanceOf(_msgSender());
		uint256 amount;
		// Iterate wallet for scientists
		for (uint256 i; i < count; i++) {
			uint256 tokenId = labGame.tokenOfOwnerByIndex(_msgSender(), i);
			uint256 token = labGame.getToken(tokenId);
			if (token & 128 == 0)
				amount += _claimScientist(tokenId, token & 3);
		}
		// Pay mutant tax
		amount = _payTax(amount);
		// Iterate wallet for mutants
		for (uint256 i; i < count; i++) {
			uint256 tokenId = labGame.tokenOfOwnerByIndex(_msgSender(), i);
			uint256 token = labGame.getToken(tokenId);
			if (token & 128 != 0)
				amount += _claimMutant(tokenId, token & 3);
		}
		// Include pending claim balance
		amount += pendingClaims[_msgSender()];
		delete pendingClaims[_msgSender()];

		// Verify amount and mint
		if (totalSerum + amount > TOTAL_SUPPLY) amount = TOTAL_SUPPLY - totalSerum;
		if (amount == 0) revert NoClaimAvailable(_msgSender());
		_mint(_msgSender(), amount);
		emit Claimed(_msgSender(), amount);
	}

	/**
	 * Calculate pending claim
	 * @param _account Account to query pending claim for
	 * @return amount Amount of claimable serum
	 */
	function pendingClaim(address _account) external view override returns (uint256 amount) {
		uint256 count = labGame.balanceOf(_account);
		uint256 untaxed;
		for (uint256 i; i < count; i++) {
			uint256 tokenId = labGame.tokenOfOwnerByIndex(_account, i);
			uint256 token = labGame.getToken(tokenId);
			if (token & 128 != 0)
				amount += mutantEarnings[token & 3] - tokenClaims[tokenId];
			else
				untaxed +=
					(block.timestamp - tokenClaims[tokenId]) * 
					[ GEN0_RATE, GEN1_RATE, GEN2_RATE, GEN3_RATE ][token & 3] / 
					CLAIM_PERIOD;
		}
		amount += _pendingTax(untaxed);
		amount += pendingClaims[_account];
	}

	// -- LABGAME -- 

	modifier onlyLabGame {
		if (address(labGame) == address(0)) revert NotReady();
		if (_msgSender() != address(labGame)) revert NotAuthorized(_msgSender(), address(labGame));
		_;
	}

	/**
	 * Setup the intial value for a new token
	 * @param _tokenId ID of the token
	 */
	function initializeClaim(uint256 _tokenId) external override onlyLabGame whenNotPaused {
		uint256 token = labGame.getToken(_tokenId);
		if (token & 128 != 0) {
			tokenClaims[_tokenId] = mutantEarnings[token & 3];
			mutantCounts[token & 3]++;
		} else {
			tokenClaims[_tokenId] = block.timestamp;
		}
	}

	/**
	 * Claim token and save in owners pending balance before token transfer
	 * @param _account Owner of token
	 * @param _tokenId Token ID
	 */
	function updateClaim(address _account, uint256 _tokenId) external override onlyLabGame whenNotPaused {
		// Verify ownership
		if (_account != labGame.ownerOf(_tokenId)) revert NotOwned(_msgSender(), _tokenId);
		uint256 amount;
		// Claim the token
		uint256 token = labGame.getToken(_tokenId);
		if ((token & 128) != 0) {
			amount = _claimMutant(_tokenId, token & 3);
		} else {
			amount = _claimScientist(_tokenId, token & 3);
			amount = _payTax(amount);
		}
		// Save to pending balance
		pendingClaims[_account] += amount;
		emit Updated(_account, _tokenId);
	}

	// -- INTERNAL --

	/**
	 * Claim scientist token rewards
	 * @param _tokenId ID of the token
	 * @param _generation Generation of the token
	 * @return amount Amount of serum/blueprints for this token
	 */
	function _claimScientist(uint256 _tokenId, uint256 _generation) internal returns (uint256 amount) {
		amount = (block.timestamp - tokenClaims[_tokenId]) * [ GEN0_RATE, GEN1_RATE, GEN2_RATE, GEN3_RATE ][_generation] / CLAIM_PERIOD;
		tokenClaims[_tokenId] = block.timestamp;
	}
	
	/**
	 * Claim mutant token rewards
	 * @param _tokenId ID of the token
	 * @param _generation Generation of the token
	 * @return amount Amount of serum for this token
	 */
	function _claimMutant(uint256 _tokenId, uint256 _generation) internal returns (uint256 amount) {
		amount = (mutantEarnings[_generation] - tokenClaims[_tokenId]);
		tokenClaims[_tokenId] = mutantEarnings[_generation];
	}

	/**
	 * Pay mutant tax for an amount of serum
	 * @param _amount Untaxed amount
	 * @return Amount after tax
	 */
	function _payTax(uint256 _amount) internal returns (uint256) {
		uint256 amount = _amount;
		for (uint256 i; i < 4; i++) {
			uint256 mutantCount = mutantCounts[i];
			if (mutantCount == 0) continue;
			uint256 tax = _amount * [ GEN0_TAX, GEN1_TAX, GEN2_TAX, GEN3_TAX ][i] / 1000;
			mutantEarnings[i] += tax / mutantCount;
			amount -= tax;
		}
		return amount;
	}

  /**
	 * Calculates the tax for a pending claim amount
	 * @param _amount Untaxed amount
	 * @return Amount after tax
	 */
	function _pendingTax(uint256 _amount) internal view returns (uint256) {
		for (uint256 i; i < 4; i++) {
			uint256 mutantCount = mutantCounts[i];
			if (mutantCount == 0) continue;
			uint256 tax = _amount * [ GEN0_TAX, GEN1_TAX, GEN2_TAX, GEN3_TAX ][i] / 1000;
			_amount -= tax;
		}
		return _amount;
	}

	// -- CONTROLLER --

	/**
	 * Mint tokens to an address
	 * @param _to address to mint to
	 * @param _amount number of tokens to mint
	 */
	function mint(address _to, uint256 _amount) external whenNotPaused onlyRole(CONTROLLER_ROLE) {
		_mint(_to, _amount);
	}

	/**
	 * Burn tokens from an address
	 * @param _from address to burn from
	 * @param _amount number of tokens to burn
	 */
	function burn(address _from, uint256 _amount) external whenNotPaused onlyRole(CONTROLLER_ROLE) {
		_burn(_from, _amount);
	}
	
	// -- ADMIN --

	/**
	 * Set LabGame contract
	 * @param _labGame Address of labgame contract
	 */
	function setLabGame(address _labGame) external onlyRole(DEFAULT_ADMIN_ROLE) {
		labGame = ILabGame(_labGame);
	}

	/**
	 * Add address as a controller
	 * @param _controller controller address
	 */
	function addController(address _controller) external onlyRole(DEFAULT_ADMIN_ROLE) {
		grantRole(CONTROLLER_ROLE, _controller);
	}

	/**
	 * Remove address as a controller
	 * @param _controller controller address
	 */
	function removeController(address _controller) external onlyRole(DEFAULT_ADMIN_ROLE) {
		revokeRole(CONTROLLER_ROLE, _controller);
	}

	/**
	 * Pause the contract
	 */
	function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
		_pause();
	}
	
	/**
	 * Unpause the contract
	 */
	function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
		_unpause();
	}
}