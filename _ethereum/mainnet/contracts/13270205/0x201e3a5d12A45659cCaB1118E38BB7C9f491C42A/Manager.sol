// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;
pragma experimental ABIEncoderV2;

import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./Registry.sol";
import "./TokenFactory.sol";

/**
 * FOR THE AUDITOR
 * This contract was designed with the idea that it would be owned by
 * another multi-party governance-like contract such as a multi-sig
 * or a yet-to-be researched governance protocol to be placed on top of
 */

/**
 * @title Manager contract for receiving proposals and creating tokens
 * @dev For receiving token proposals and creating said tokens from such parameters.
 * @dev State is separated onto Registry contract
 * @dev To set up a working version of the entire platform, first create TokenFactory,
 * Registry, then transfer ownership to the Manager contract. Ensure as well that TokenVesting is
 * created for a valid TokenFactory. See the hardhat
 * test, especially test/manager.js to understand how this would be done offline.
 */
contract Manager is Initializable, OwnableUpgradeable {
	using SafeMath for uint256;

	Registry public RegistryInstance;
	TokenFactory public TokenFactoryInstance;

	event LogTokenFactoryChanged(address oldTF, address newTF);
	event LogRegistryChanged(address oldR, address newR);
	event LogManagerMigrated(address indexed newManager);

	/**
	 * @dev Constructor on Manager
	 * @param _registry address Address of Registry contract
	 * @param _tokenFactory address Address of TokenFactory contract
	 * @notice It is recommended that all the component contracts be launched before Manager
	 */
	function initialize(address _registry, address _tokenFactory)
		public
		initializer
	{
		require(
			_registry != address(0) && _tokenFactory != address(0),
			"Params can't be ZERO"
		);
		__Ownable_init();
		TokenFactoryInstance = TokenFactory(_tokenFactory);
		RegistryInstance = Registry(_registry);
	}

	/**
	 * @dev Submit Token Proposal
	 * @param _name string Name parameter of Token
	 * @param _symbol string Symbol parameter of Token
	 * @param _decimals uint8 Decimals parameter of Token, restricted to < 18
	 * @param _totalSupply uint256 Total Supply paramter of Token
	 * @param _initialPercentage uint8 Initial percentage of total supply that the Vesting Beneficiary will receive from launch, restricted to < 100
	 * @param _vestingPeriodInDays uint256 Number of days that the remaining of total supply will be linearly vested for, restricted to > 1
	 * @param _vestingBeneficiary address Address of the Vesting Beneficiary
	 * @param _initialPlatformPercentage Roll 1.5
	 * @return hashIndex bytes32 Hash Index which is composed by the keccak256(name, symbol, msg.sender)
	 */

	function submitProposal(
		string memory _name,
		string memory _symbol,
		uint8 _decimals,
		uint256 _totalSupply,
		uint8 _initialPercentage,
		uint256 _vestingPeriodInDays,
		address _vestingBeneficiary,
		uint8 _initialPlatformPercentage
	)
		public
		validatePercentage(_initialPercentage)
		validatePercentage(_initialPlatformPercentage)
		validateDecimals(_decimals)
		isInitialized()
		returns (bytes32 hashIndex)
	{
		hashIndex = RegistryInstance.submitProposal(
			_name,
			_symbol,
			_decimals,
			_totalSupply,
			_initialPercentage,
			_vestingPeriodInDays,
			_vestingBeneficiary,
			msg.sender,
			_initialPlatformPercentage
		);
	}

	function submitReferral(
		bytes32 _hashIndex,
		address _referral,
		uint8 _referralPercentage
	) public validatePercentage(_referralPercentage) isInitialized() {
		RegistryInstance.submitProposalReferral(
			_hashIndex,
			_referral,
			_referralPercentage
		);
	}

	/**
	 * @dev Approve Token Proposal
	 * @param _hashIndex bytes32 Hash Index of Token Proposal, given by keccak256(name, symbol, msg.sender)
	 */
	function approveProposal(bytes32 _hashIndex)
		external
		isInitialized()
		onlyOwner
	{
		Registry.Creator memory approvedProposal =
			RegistryInstance.getCreatorByIndex(_hashIndex);

		Registry.CreatorReferral memory approvedProposalReferral =
			RegistryInstance.getCreatorReferralByIndex(_hashIndex);

		uint16 initialPercentage =
			uint16(approvedProposal.initialPercentage) +
				uint16(approvedProposal.initialPlatformPercentage) +
				uint16(approvedProposalReferral.referralPercentage);
		require(
			initialPercentage <= uint16(type(uint8).max),
			"Invalid uint8 value"
		);
		validatePercentageFunc(uint8(initialPercentage));

		address ac =
			TokenFactoryInstance.createToken(
				approvedProposal.name,
				approvedProposal.symbol,
				approvedProposal.decimals,
				approvedProposal.totalSupply,
				approvedProposal.initialPercentage,
				approvedProposal.vestingPeriodInDays,
				approvedProposal.vestingBeneficiary,
				approvedProposal.initialPlatformPercentage,
				approvedProposalReferral.referral,
				approvedProposalReferral.referralPercentage
			);
		bool success = RegistryInstance.approveProposal(_hashIndex, ac);
		require(success, "Registry approve proposal has to succeed");
	}

	/*
	 * CHANGE PLATFORM VARIABLES AND INSTANCES
	 */

	function setPlatformWallet(address _newPlatformWallet)
		external
		onlyOwner
		isInitialized()
	{
		TokenFactoryInstance.setPlatformWallet(_newPlatformWallet);
	}

	/*
	 * CHANGE VESING BENEFICIARY
	 */

	function setVestingAddress(address _token, address _vestingBeneficiary)
		public
	{
		require(
			_vestingBeneficiary != address(0),
			"MANAGER: beneficiary can not be zero"
		);
		TokenFactoryInstance.setVestingAddress(
			msg.sender,
			_token,
			_vestingBeneficiary
		);
	}

	function setVestingReferral(address _token, address _vestingReferral)
		public
	{
		require(
			_vestingReferral != address(0),
			"MANAGER: beneficiary can not be zero"
		);
		TokenFactoryInstance.setVestingReferral(
			msg.sender,
			_token,
			_vestingReferral
		);
	}

	// --------------------------------------------
	// This are to keep compatibility with Owner version sol050
	// --------------------------------------------
	function parseAddr(bytes memory data) public pure returns (address parsed) {
		assembly {
			parsed := mload(add(data, 32))
		}
	}

	function getTokenVestingStatic(address tokenFactoryContract)
		internal
		view
		returns (address)
	{
		bytes memory callcodeTokenVesting =
			abi.encodeWithSignature("getTokenVesting()");
		(bool success, bytes memory returnData) =
			address(tokenFactoryContract).staticcall(callcodeTokenVesting);
		require(
			success,
			"input address has to be a valid TokenFactory contract"
		);
		return parseAddr(returnData);
	}

	// --------------------------------------------
	// --------------------------------------------

	function setTokenFactory(address _newTokenFactory) external onlyOwner {
		require(
			OwnableUpgradeable(_newTokenFactory).owner() == address(this),
			"new TokenFactory has to be owned by Manager"
		);
		require(
			getTokenVestingStatic(_newTokenFactory) ==
				address(TokenFactoryInstance.TokenVestingInstance()),
			"TokenVesting has to be the same"
		);
		TokenFactoryInstance.migrateTokenFactory(_newTokenFactory);
		require(
			OwnableUpgradeable(getTokenVestingStatic(_newTokenFactory))
				.owner() == address(_newTokenFactory),
			"TokenFactory does not own TokenVesting"
		);
		emit LogTokenFactoryChanged(
			address(TokenFactoryInstance),
			address(_newTokenFactory)
		);
		TokenFactoryInstance = TokenFactory(_newTokenFactory);
	}

	function setRegistry(address _newRegistry) external onlyOwner {
		require(
			OwnableUpgradeable(_newRegistry).owner() == address(this),
			"new Registry has to be owned by Manager"
		);
		emit LogRegistryChanged(address(RegistryInstance), _newRegistry);
		RegistryInstance = Registry(_newRegistry);
	}

	function setTokenVesting(address _newTokenVesting) external onlyOwner {
		TokenFactoryInstance.setTokenVesting(_newTokenVesting);
	}

	function migrateManager(address _newManager)
		external
		onlyOwner
		isInitialized()
	{
		RegistryInstance.transferOwnership(_newManager);
		TokenFactoryInstance.transferOwnership(_newManager);
		emit LogManagerMigrated(_newManager);
	}

	function validatePercentageFunc(uint8 percentage) internal pure {
		require(
			percentage >= 0 && percentage <= 100,
			"has to be above 0 and below 100"
		);
	}

	modifier validatePercentage(uint8 percentage) {
		require(
			percentage >= 0 && percentage <= 100,
			"has to be above 0 and below 100"
		);
		_;
	}

	modifier validateDecimals(uint8 decimals) {
		require(
			decimals >= 0 && decimals <= 18,
			"has to be above or equal 0 and below 19"
		);
		_;
	}

	modifier isInitialized() {
		require(initialized(), "manager not initialized");
		_;
	}

	function initialized() public view returns (bool) {
		address tokenVestingInstance =
			address(TokenFactoryInstance.TokenVestingInstance());
		return
			(RegistryInstance.owner() == address(this)) &&
			(TokenFactoryInstance.owner() == address(this));
	}
}
