// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
 * Copyright (c) 2022 Mighty Bear Games
 */

import "./ReentrancyGuardUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./PausableUpgradeable.sol";

import "./IPolar1337.sol";
import "./Whitelists.sol";

error NotEnoughSupply();
error PhaseNotStarted(uint256 startTime);
error PhaseOver(uint256 endTime);
error NotWhitelisted(address address_);
error MintLimitExceeded(uint256 limit);
error MintAllowanceExceeded(address address_, uint256 allowance);

/**
 * @notice This is a 3-phase minter contract that includes a guaranteed mint, allow list, and public sale.
 */
contract Polar1337Minter is
	AccessControlUpgradeable,
	PausableUpgradeable,
	ReentrancyGuardUpgradeable
{
	// ------------------------------
	// 			V1 Variables
	// ------------------------------

	/// @notice The address of the Polar1337 contract
	IPolar1337 public mightyNetGP;

	/// @notice Tracks the total count of bears for sale
	uint256 public supplyLimit;

	/// @dev Used for incrementing the token IDs
	uint256 public currentTokenId;

	using Whitelists for Whitelists.MerkleProofWhitelist;

	/// @notice The start timestamp for the guaranteed mint
	uint256 public guaranteedStartTime;

	/// @notice The start timestamp for the allow list phase
	uint256 public allowListStartTime;

	/// @notice The start timestamp for the public phase
	uint256 public publicStartTime;

	/// @notice Tracks the number of tokens an address can still mint through the guaranteed mint
	mapping(address => uint256) public addressToGuaranteedMints;

	/// @notice The whitelist for the allow list phase
	Whitelists.MerkleProofWhitelist private allowListWhitelist;

	/// @notice Tracks addresses that have claimed on allowlist and public phase
	mapping(address => bool) public addressToClaimed;

	/// @notice The maximum number of tokens that can be minted per transaction
	uint256 public mintLimit;

	/*
	 * DO NOT ADD OR REMOVE VARIABLES ABOVE THIS LINE. INSTEAD, CREATE A NEW VERSION SECTION BELOW.
	 * MOVE THIS COMMENT BLOCK TO THE END OF THE LATEST VERSION SECTION PRE-DEPLOYMENT.
	 */

	function initialize(IPolar1337 mightyNetGP_) public initializer {
		// Call parent initializers
		__AccessControl_init();
		__Pausable_init();
		__ReentrancyGuard_init();

		// Set defaults
		_grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

		setSupplyLimit(1337);
		currentTokenId = 0;

		uint256 defaultStartTime = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

		setGuaranteedStartTime(defaultStartTime);
		setAllowListStartTime(defaultStartTime);
		setPublicStartTime(defaultStartTime);

		mintLimit = 20;

		// Set constructor arguments
		setPolar1337Address(mightyNetGP_);
	}

	/*
	 Timeline:
	 
	 guaranteedMint  :|------------|
	 allowListSale   :             |------------|
	 publicSale      :                          |------------|
	 */

	// ------------------------------
	// 		Guaranteed Mint Sale
	// ------------------------------

	/**
	@notice Mint a free passes on the guaranteed mint phase
	@param numPasses The number of passes to mint
	*/
	function guaranteedMint(uint256 numPasses)
		external
		nonReentrant
		whenNotPaused
		inGuaranteedPhase
		whenSupplyRemains(numPasses)
		withinMintLimit(numPasses)
	{
		uint256 mints = addressToGuaranteedMints[msg.sender];

		if (numPasses > mints) {
			revert MintAllowanceExceeded(msg.sender, mints);
		}

		addressToGuaranteedMints[msg.sender] -= numPasses;

		// Mark address as claimed to prevent claiming on other phases
		addressToClaimed[msg.sender] = true;

		_mint(msg.sender, numPasses);
	}

	/**
	@notice Returns true if in the guaranteed phase
	 */
	function isInGuaranteedPhase() external view returns (bool) {
		return
			_hasStarted(guaranteedStartTime) &&
			!_hasStarted(allowListStartTime);
	}

	/**
	 * @notice Sets the number of tokens an address can mint in guaranteed phase
	 * @param user address of the user
	 * @param mints uint256 of the number of passes the user can mint
	 */
	function setGuaranteedMints(address user, uint256 mints)
		external
		onlyRole(DEFAULT_ADMIN_ROLE)
	{
		addressToGuaranteedMints[user] = mints;
	}

	// ------------------------------
	// 		   Allow List Sale
	// ------------------------------

	/**
	@notice Mint a free pass in the allow list phase
	@param merkleProof bytes32[] of the merkle proof of the minting address
	*/
	function allowListMint(bytes32[] calldata merkleProof)
		external
		nonReentrant
		whenNotPaused
		inAllowListPhase
		whenSupplyRemains(1)
		onlyWhitelisted(msg.sender, merkleProof, allowListWhitelist)
		whenHasNotClaimed(msg.sender)
	{
		addressToClaimed[msg.sender] = true;

		_mint(msg.sender, 1);
	}

	/**
    @notice Returns true it the user is included in the allow list whitelist
    @param user address of the user
    @param merkleProof uint256[] of the merkle proof of the user address
    */
	function isAllowListWhitelisted(
		address user,
		bytes32[] calldata merkleProof
	) external view returns (bool) {
		return allowListWhitelist.isWhitelisted(user, merkleProof);
	}

	/**
	@notice Returns true if the allow list sale has started
	 */
	function isInAllowListPhase() external view returns (bool) {
		return _hasStarted(allowListStartTime) && !_hasStarted(publicStartTime);
	}

	/**
	@notice Returns the root hash of the allow list Merkle tree
	 */
	function allowListMerkleRoot() external view returns (bytes32) {
		return allowListWhitelist.getRootHash();
	}

	/**
	 * @notice Sets whether the address has claimed a pass in any phase
	 * @param user address of the user
	 * @param claimed bool of whether the user has claimed
	 */
	function setAddressToClaimed(address user, bool claimed)
		external
		onlyRole(DEFAULT_ADMIN_ROLE)
	{
		addressToClaimed[user] = claimed;
	}

	// ------------------------------
	// 			Public Sale
	// ------------------------------

	/**
	@notice Mint a free pass in the public phase
	*/
	function publicMint()
		external
		nonReentrant
		whenNotPaused
		inPublicPhase
		whenSupplyRemains(1)
		whenHasNotClaimed(msg.sender)
	{
		addressToClaimed[msg.sender] = true;

		_mint(msg.sender, 1);
	}

	/**
	@notice Returns true if the public sale has started
	*/
	function isInPublicPhase() external view returns (bool) {
		return _hasStarted(publicStartTime);
	}

	// ------------------------------
	// 			  Minting
	// ------------------------------

	function _mint(address to, uint256 numPasses) internal {
		for (uint256 i = 0; i < numPasses; i++) {
			// Generate token id
			currentTokenId += 1;

			mightyNetGP.mint(to, currentTokenId);
		}
	}

	function availableSupply() external view returns (uint256) {
		return supplyLimit - currentTokenId;
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
	// 			  Setters
	// ------------------------------

	/// @notice Sets the address of the Polar1337 contract
	function setPolar1337Address(IPolar1337 mightyNetGP_)
		public
		onlyRole(DEFAULT_ADMIN_ROLE)
	{
		mightyNetGP = mightyNetGP_;
	}

	/// @notice Sets the number of available tokens
	function setSupplyLimit(uint256 supplyLimit_)
		public
		onlyRole(DEFAULT_ADMIN_ROLE)
	{
		supplyLimit = supplyLimit_;
	}

	/**
	@notice A convenient way to set phase times at once
	@param guaranteedStartTime_ uint256 of the guaranteed start time
	@param allowListStartTime_ uint256 the allow list start time
	@param publicStartTime_ uint256 the public sale start time
	*/
	function setPhaseTimes(
		uint256 guaranteedStartTime_,
		uint256 allowListStartTime_,
		uint256 publicStartTime_
	) external onlyRole(DEFAULT_ADMIN_ROLE) {
		setGuaranteedStartTime(guaranteedStartTime_);
		setAllowListStartTime(allowListStartTime_);
		setPublicStartTime(publicStartTime_);
	}

	/**
	@notice Sets the guaranteed mint start time
	@param guaranteedStartTime_ uint256 the guaranteed mint start time
	*/
	function setGuaranteedStartTime(uint256 guaranteedStartTime_)
		public
		onlyRole(DEFAULT_ADMIN_ROLE)
	{
		guaranteedStartTime = guaranteedStartTime_;
	}

	/**
	@notice Sets the allow list start time
	@param allowListStartTime_ uint256 the allow list start time
	*/
	function setAllowListStartTime(uint256 allowListStartTime_)
		public
		onlyRole(DEFAULT_ADMIN_ROLE)
	{
		allowListStartTime = allowListStartTime_;
	}

	/**
	@notice Sets the public start time
	@param publicStartTime_ uint256 the public sale start time
	*/
	function setPublicStartTime(uint256 publicStartTime_)
		public
		onlyRole(DEFAULT_ADMIN_ROLE)
	{
		publicStartTime = publicStartTime_;
	}

	/**
	@notice Sets the root hash of the allow list Merkle tree
	@param rootHash bytes32 the root hash of the allow list Merkle tree
	*/
	function setAllowListMerkleRoot(bytes32 rootHash)
		external
		onlyRole(DEFAULT_ADMIN_ROLE)
	{
		allowListWhitelist.setRootHash(rootHash);
	}

	/**
	 * @notice Sets the number of passess that can be minted in one transaction
	 * @param limit uint256 the number of passess that can be minted in one transaction
	 */
	function setMintLimit(uint256 limit) external onlyRole(DEFAULT_ADMIN_ROLE) {
		mintLimit = limit;
	}

	// ------------------------------
	// 			  Modifiers
	// ------------------------------

	/**
	@dev Modifier to make a function callable only when there is enough bears left for sale
	
	Requirements:

	- Number of bears sold must be less than the maximum for sale
	*/
	modifier whenSupplyRemains(uint256 mintAmount) {
		if (currentTokenId + mintAmount > supplyLimit) {
			revert NotEnoughSupply();
		}
		_;
	}

	/**
	@dev Modifier to make a function callable only when an address has not claimed their mint in allow list or public phase
	
	Requirements:

	- Address must not have claimed a mint yet
	*/
	modifier whenHasNotClaimed(address user) {
		if (addressToClaimed[user]) {
			revert MintAllowanceExceeded(msg.sender, 0);
		}
		_;
	}

	/**
    @dev Modifier to make a function callable only when in the guaranteedMint phase

    Requirements:

    - Current block timestamp must be greater than the guaranteed mint start time
	- Current block timestamp must be less than the allow list start time
    */
	modifier inGuaranteedPhase() {
		if (!_hasStarted(guaranteedStartTime)) {
			revert PhaseNotStarted(guaranteedStartTime);
		}
		if (_hasStarted(allowListStartTime)) {
			revert PhaseOver(allowListStartTime);
		}
		_;
	}

	/**
    @dev Modifier to make a function callable only when in the allow list phase

    Requirements:

    - Current block timestamp must be greater than the allow list start time
	- Current block timestamp must be less than the public sale start time
    */
	modifier inAllowListPhase() {
		if (!_hasStarted(allowListStartTime)) {
			revert PhaseNotStarted(allowListStartTime);
		}
		if (_hasStarted(publicStartTime)) {
			revert PhaseOver(publicStartTime);
		}
		_;
	}

	/**
    @dev Modifier to make a function callable only when in the public sale phase

    Requirements:

    - Current block timestamp must be greater than the public sale start time
    */
	modifier inPublicPhase() {
		if (!_hasStarted(publicStartTime)) {
			revert PhaseNotStarted(publicStartTime);
		}
		_;
	}

	/**
    @dev Modifier to make a function callable only when the user is included in the allow list whitelist

    Requirements:

    - Merkle proof of user address must be valid
    */
	modifier onlyWhitelisted(
		address user,
		bytes32[] calldata merkleProof,
		Whitelists.MerkleProofWhitelist storage whitelist
	) {
		if (!whitelist.isWhitelisted(user, merkleProof)) {
			revert NotWhitelisted(user);
		}
		_;
	}

	/**
    @dev Modifier to make a function callable only when the requested number of passes is valid
    Requirements:

    - The requested number of passes must be less than or equal to mint limit
    */
	modifier withinMintLimit(uint256 numPasses) {
		if (numPasses > mintLimit) {
			revert MintLimitExceeded(mintLimit);
		}
		_;
	}

	/**
	 @notice Returns true if the start time has passed
	 @param startTime uint256 of the start time
	 */
	function _hasStarted(uint256 startTime) internal view returns (bool) {
		return block.timestamp > startTime;
	}
}
