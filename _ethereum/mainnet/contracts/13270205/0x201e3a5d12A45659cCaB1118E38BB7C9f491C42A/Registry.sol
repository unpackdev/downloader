// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;
pragma experimental ABIEncoderV2;

import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./ILegacyRegistry.sol";

/**
 * @title Registry contract for storing token proposals
 * @dev For storing token proposals. This can be understood as a state contract with minimal CRUD logic.
 */
contract Registry is Initializable, OwnableUpgradeable {
	struct Creator {
		address token;
		string name;
		string symbol;
		uint256 totalSupply;
		uint256 vestingPeriodInDays;
		address proposer;
		address vestingBeneficiary;
		uint8 initialPlatformPercentage;
		uint8 decimals;
		uint8 initialPercentage;
		bool approved;
	}

	struct CreatorReferral {
		address referral;
		uint8 referralPercentage;
	}

	mapping(bytes32 => Creator) public rolodex;
	mapping(bytes32 => CreatorReferral) public creatorReferral;
	mapping(string => bytes32) nameToIndex;
	mapping(string => bytes32) symbolToIndex;

	address legacyRegistry;

	event LogProposalSubmit(
		string name,
		string symbol,
		address proposer,
		bytes32 indexed hashIndex
	);

	event LogProposalReferralSubmit(
		address referral,
		uint8 referralPercentage,
		bytes32 indexed hashIndex
	);

	event LogProposalImported(
		string name,
		string symbol,
		address proposer,
		bytes32 indexed hashIndex
	);
	event LogProposalApprove(string name, address indexed tokenAddress);

	function initialize() public initializer {
		__Ownable_init();
	}

	/**
	 * @dev Submit token proposal to be stored, only called by Owner, which is set to be the Manager contract
	 * @param _name string Name of token
	 * @param _symbol string Symbol of token
	 * @param _decimals uint8 Decimals of token
	 * @param _totalSupply uint256 Total Supply of token
	 * @param _initialPercentage uint8 Initial Percentage of total supply to Vesting Beneficiary
	 * @param _vestingPeriodInDays uint256 Number of days that the remaining of total supply will be linearly vested for
	 * @param _vestingBeneficiary address Address of Vesting Beneficiary
	 * @param _proposer address Address of Proposer of Token, also the msg.sender of function call in Manager contract
	 * @param _initialPlatformPercentage Roll 1.5
	 * @return hashIndex bytes32 It will return a hash index which is calculated as keccak256(_name, _symbol, _proposer)
	 */
	function submitProposal(
		string memory _name,
		string memory _symbol,
		uint8 _decimals,
		uint256 _totalSupply,
		uint8 _initialPercentage,
		uint256 _vestingPeriodInDays,
		address _vestingBeneficiary,
		address _proposer,
		uint8 _initialPlatformPercentage
	) public onlyOwner returns (bytes32 hashIndex) {
		nameDoesNotExist(_name);
		symbolDoesNotExist(_symbol);
		hashIndex = keccak256(abi.encodePacked(_name, _symbol, _proposer));
		rolodex[hashIndex] = Creator({
			token: address(0),
			name: _name,
			symbol: _symbol,
			decimals: _decimals,
			totalSupply: _totalSupply,
			proposer: _proposer,
			vestingBeneficiary: _vestingBeneficiary,
			initialPercentage: _initialPercentage,
			vestingPeriodInDays: _vestingPeriodInDays,
			approved: false,
			initialPlatformPercentage: _initialPlatformPercentage
		});

		emit LogProposalSubmit(_name, _symbol, msg.sender, hashIndex);
	}

	function submitProposalReferral(
		bytes32 _hashIndex,
		address _referral,
		uint8 _referralPercentage
	) public onlyOwner {
		creatorReferral[_hashIndex] = CreatorReferral({
			referral: _referral,
			referralPercentage: _referralPercentage
		});
		emit LogProposalReferralSubmit(
			_referral,
			_referralPercentage,
			_hashIndex
		);
	}

	/**
	 * @dev Approve token proposal, only called by Owner, which is set to be the Manager contract
	 * @param _hashIndex bytes32 Hash Index of Token proposal
	 * @param _token address Address of Token which has already been launched
	 * @return bool Whether it has completed the function
	 * @dev Notice that the only things that have changed from an approved proposal to one that is not
	 * is simply the .token and .approved object variables.
	 */
	function approveProposal(bytes32 _hashIndex, address _token)
		external
		onlyOwner
		returns (bool)
	{
		Creator memory c = rolodex[_hashIndex];
		nameDoesNotExist(c.name);
		symbolDoesNotExist(c.symbol);
		rolodex[_hashIndex].token = _token;
		rolodex[_hashIndex].approved = true;
		nameToIndex[c.name] = _hashIndex;
		symbolToIndex[c.symbol] = _hashIndex;
		emit LogProposalApprove(c.name, _token);
		return true;
	}

	//Getters

	function getIndexByName(string memory _name) public view returns (bytes32) {
		return nameToIndex[_name];
	}

	function getIndexBySymbol(string memory _symbol)
		public
		view
		returns (bytes32)
	{
		return symbolToIndex[_symbol];
	}

	function getCreatorByIndex(bytes32 _hashIndex)
		external
		view
		returns (Creator memory)
	{
		return rolodex[_hashIndex];
	}

	function getCreatorReferralByIndex(bytes32 _hashIndex)
		external
		view
		returns (CreatorReferral memory)
	{
		return creatorReferral[_hashIndex];
	}

	function getCreatorByName(string memory _name)
		external
		view
		returns (Creator memory)
	{
		bytes32 _hashIndex = nameToIndex[_name];
		return rolodex[_hashIndex];
	}

	function getCreatorBySymbol(string memory _symbol)
		external
		view
		returns (Creator memory)
	{
		bytes32 _hashIndex = symbolToIndex[_symbol];
		return rolodex[_hashIndex];
	}

	//Assertive functions

	function nameDoesNotExist(string memory _name) internal view {
		require(nameToIndex[_name] == 0x0, "Name already exists");
	}

	function symbolDoesNotExist(string memory _name) internal view {
		require(symbolToIndex[_name] == 0x0, "Symbol already exists");
	}

	// Import functions
	function importByIndex(bytes32 _hashIndex, address _oldRegistry)
		external
		onlyOwner
	{
		Registry old = Registry(_oldRegistry);
		Creator memory proposal = old.getCreatorByIndex(_hashIndex);
		nameDoesNotExist(proposal.name);
		symbolDoesNotExist(proposal.symbol);

		rolodex[_hashIndex] = proposal;
		if (proposal.approved) {
			nameToIndex[proposal.name] = _hashIndex;
			symbolToIndex[proposal.symbol] = _hashIndex;
		}
		emit LogProposalImported(
			proposal.name,
			proposal.symbol,
			proposal.proposer,
			_hashIndex
		);
	}

	// Legacy registry tools

	function setLegacyRegistryAddress(address _legacyRegistry)
		external
		onlyOwner
	{
		legacyRegistry = _legacyRegistry;
	}

	function legacyProposalsByIndex(bytes32 hashIndex)
		external
		view
		returns (Creator memory)
	{
		ILegacyRegistry legacy = ILegacyRegistry(legacyRegistry);
		ILegacyRegistry.Creator memory legacyCreator =
			legacy.rolodex(hashIndex);
		Creator memory creator =
			Creator({
				token: legacyCreator.token,
				name: legacyCreator.name,
				symbol: legacyCreator.symbol,
				decimals: legacyCreator.decimals,
				totalSupply: legacyCreator.totalSupply,
				proposer: legacyCreator.proposer,
				vestingBeneficiary: legacyCreator.vestingBeneficiary,
				initialPercentage: legacyCreator.initialPercentage,
				vestingPeriodInDays: legacyCreator.vestingPeriodInWeeks * 7,
				approved: legacyCreator.approved,
				initialPlatformPercentage: 0
			});

		return creator;
	}

	function legacyProposals(string memory _name)
		external
		view
		returns (Creator memory)
	{
		ILegacyRegistry legacy = ILegacyRegistry(legacyRegistry);
		bytes32 hashIndex = legacy.getIndexSymbol(_name);
		return this.legacyProposalsByIndex(hashIndex);
	}
}
