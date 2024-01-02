// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./InitializableAccessControl.sol";
import "./TradeableShares.sol";
import "./SharesFactory.sol";
import "./SharesSubjectLib.sol";
import "./FriendTechBondingCurve.sol";

/**
 * @title Abstract Shares
 *
 * @notice Contains the logic which is currently common for the ETHShares
 *      and ERC20Shares TradeableShares implementations.
 *      Once these contracts diverge enough in their logic, this abstract contract
 *      may cease to exist.
 *
 * @dev Based on the friend.tech FriendtechSharesV1.sol
 */
abstract contract AbstractShares is TradeableShares, FriendTechBondingCurve, InitializableAccessControl {
	/// @dev Shares subject is an NFT; NFT owner receives the subject fee
	SharesSubject private sharesSubject;
	/// @dev Protocol fee destination is an address collecting the protocol fee
	address private protocolFeeDestination;
	/// @dev Protocol fee percent, immutable; maximum value: 10^18 (< 2^60)
	uint64 private /*immutable*/ protocolFeePercent;
	/// @dev Holders rewards fee destination is a contract collecting the holders fee, immutable
	HoldersRewardsDistributor private /*immutable*/ holdersFeeDestination;
	/// @dev Holders rewards fee percent, immutable
	uint64 private /*immutable*/ holdersFeePercent;
	/// @dev Subject fee percent, immutable
	uint64 private /*immutable*/ subjectFeePercent;

	/// @dev Total shares supply, sum of all the individual balances in `sharesBalances`
	uint256 internal sharesSupply;
	/// @dev Individual shares balances: Holder => Balance
	mapping(address => uint256) internal sharesBalances;

	/**
	 * @dev Fired in `updateSharesSubject`
	 *
	 * @param oldSubject old shares subject
	 * @param newSubject new shares subject
	 * @param factory the factory contract notified about the update
	 */
	event SharesSubjectUpdated(SharesSubject oldSubject, SharesSubject newSubject, SharesFactory factory);

	/**
	 * @dev Fired in `updateProtocolFeeDestination`
	 *
	 * @param oldProtocolFeeDestination old protocol fee destination
	 * @param newProtocolFeeDestination new protocol fee destination
	 */
	event ProtocolFeeDestinationUpdated(address oldProtocolFeeDestination, address newProtocolFeeDestination);

	/**
	 * @dev Fire in `disableHoldersFee` no more than once
	 *      for the entire lifespan of the contract
	 *
	 * @param oldProtocolFeePercent old protocol fee percent
	 * @param newProtocolFeePercent new protocol fee percent, new >= old
	 */
	event HoldersFeeDisabled(uint256 oldProtocolFeePercent, uint256 newProtocolFeePercent);

	/**
	 * @notice Protocol fee destination manager is responsible for updating the address collecting the
	 *      protocol fee destination, that is `protocolFeeDestination`; the manager cannot update the fee percent
	 *
	 * @dev This role should be granted to the MultiSig, not to EOA and not to
	 *      RBAC managed smart contract, so that this functionality is not scalable;
	 *      this reduces the risk of misuse, and/or malicious use
	 *
	 * @dev Role ROLE_PROTOCOL_FEE_MANAGER is required to execute `updateProtocolFeeDestination` function
	 */
	uint32 public constant ROLE_PROTOCOL_FEE_MANAGER = 0x0001_0000;

	/**
	 * @notice Holders fee [disable] manager can disable the shares holders fee functionality;
	 *      the manager cannot enable it back
	 *
	 * @dev This role should be granted to the MultiSig, not to EOA and not to
	 *      RBAC managed smart contract, so that this functionality is not scalable;
	 *      this reduces the risk of misuse, and/or malicious use
	 *
	 * @dev Role ROLE_HOLDERS_FEE_MANAGER is required to execute `disableHoldersFee` function
	 */
	uint32 public constant ROLE_HOLDERS_FEE_MANAGER = 0x0002_0000;

	/**
	 * @notice Shares subject manager is responsible for updating the "shares subject"
	 *      in case of emergency, for example if underlying NFT was stolen
	 *
	 * @dev This role should be granted to the MultiSig, not to EOA and not to
	 *      RBAC managed smart contract, so that this functionality is not scalable;
	 *      this reduces the risk of misuse, and/or malicious use
	 *
	 * @dev Role ROLE_SHARES_SUBJECT_MANAGER is required to execute `updateSharesSubject` function
	 */
	uint32 public constant ROLE_SHARES_SUBJECT_MANAGER = 0x0008_0000;

	/**
	 * @dev "Constructor replacement" for initializable, must be execute during or immediately after deployment
	 *      see https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#initializers
	 *
	 * @param _owner the address receiving all the RBAC permissions on the contract
	 * @param _sharesSubject shares subject, usually defined as NFT (ERC721 contract address + NFT ID)
	 * @param _protocolFeeDestination protocol fee destination, the address protocol fee is sent to
	 * @param _protocolFeePercent protocol fee percent, applied to all the buy and sell operations;
	 *      the fee percent is defined with the 18 decimals, 10^18 corresponds to 100%
	 * @param _holdersFeeDestination shares holders fee destination, the HoldersRewardsDistributor contract
	 *      the shares holders fee is sent to
	 * @param _holdersFeePercent shares holders fee percent, applied to all the buy and sell operations,
	 *      the fee percent is defined with the 18 decimals, 10^18 corresponds to 100%
	 * @param _subjectFeePercent subject fee percent, applied to all the buy and sell operations,
	 *      the fee percent is defined with the 18 decimals, 10^18 corresponds to 100%
	 */
	function _postConstruct(
		address _owner,
		SharesSubject memory _sharesSubject,
		address _protocolFeeDestination,
		uint64 _protocolFeePercent,
		HoldersRewardsDistributor _holdersFeeDestination,
		uint64 _holdersFeePercent,
		uint64 _subjectFeePercent
	) internal onlyInitializing {
		// execute parent initializer
		_postConstruct(_owner);
		// this initializer is called only from the factory, we do not verify the
		// validity of the inputs generated by the factory itself
		// if the factory goes buggy/malicious after the upgrade, all the
		// shares contracts deployed after should be considered invalid
		sharesSubject = _sharesSubject;
		protocolFeeDestination = _protocolFeeDestination;
		protocolFeePercent = _protocolFeePercent;
		holdersFeeDestination = _holdersFeeDestination;
		holdersFeePercent = _holdersFeePercent;
		subjectFeePercent = _subjectFeePercent;
	}

	/**
	 * @inheritdoc TradeableShares
	 */
	function getSharesSubject() public view returns(SharesSubject memory) {
		// read value from the storage
		return sharesSubject;
	}

	/**
	 * @notice Updates the shares subject
	 *
	 * @dev This is a restricted access function which should be accessible only from the
	 *      MultiSig wallet controlling the protocol, so that its usage is not scalable
	 *
	 * @param _sharesSubject new subject to set
	 */
	function updateSharesSubject(SharesSubject calldata _sharesSubject) public {
		// delegate to `updateSharesSubject` with the zero factory
		updateSharesSubject(_sharesSubject, SharesFactory(address(0)));
	}

	/**
	 * @notice Updates the shares subject and optionally notifies the factory about the update;
	 *      update fails if the factory notification fails
	 *
	 * @dev This is a restricted access function which should be accessible only from the
	 *      MultiSig wallet controlling the protocol, so that its usage is not scalable
	 *
	 * @param _sharesSubject new subject to set
	 * @param _factory shares factory contract to notify about the update, optional
	 *      if set to zero, the notification is not done
	 */
	function updateSharesSubject(SharesSubject calldata _sharesSubject, SharesFactory _factory) public {
		// verify the access permission
		require(isSenderInRole(ROLE_SHARES_SUBJECT_MANAGER), "access denied");

		// emit an event first - to log both old and new values
		emit SharesSubjectUpdated(sharesSubject, _sharesSubject, _factory);

		// update contract's state
		sharesSubject = _sharesSubject;

		// if factory is set (factory notification requested)
		if(address(_factory) != address(0)) {
			// notify factory contract
			_factory.notifySubjectUpdated();
		}
	}

	/**
	 * @inheritdoc TradeableShares
	 */
	function getProtocolFeeDestination() public view returns(address) {
		// read the value from storage
		return protocolFeeDestination;
	}

	/**
	 * @notice Updates the protocol fee destination address `protocolFeeDestination`
	 *
	 * @dev This is a restricted access function which should be accessible only from the
	 *      MultiSig wallet controlling the protocol, so that its usage is not scalable
	 *
	 * @param _protocolFeeDestination new protocol fee destination address to set
	 */
	function updateProtocolFeeDestination(address _protocolFeeDestination) public {
		// verify the access permission
		require(isSenderInRole(ROLE_PROTOCOL_FEE_MANAGER), "access denied");

		// emit an event first - to log both old and new values
		emit ProtocolFeeDestinationUpdated(protocolFeeDestination, _protocolFeeDestination);

		// update contract's state
		protocolFeeDestination = _protocolFeeDestination;
	}

	/**
	 * @inheritdoc TradeableShares
	 */
	function getProtocolFeePercent() public view returns(uint256) {
		// read the value from storage (immutable)
		return protocolFeePercent;
	}

	/**
	 * @inheritdoc TradeableShares
	 */
	function getProtocolFeeInfo() public view returns(address feeDestination, uint256 feePercent) {
		// read fee destination first
		feeDestination = getProtocolFeeDestination();
		// if it's zero, zero down the fee as well
		feePercent = feeDestination == address(0)? 0: getProtocolFeePercent();
	}

	/**
	 * @inheritdoc TradeableShares
	 */
	function getHoldersFeeDestination() public view returns(HoldersRewardsDistributor) {
		// read the value from storage (immutable)
		return holdersFeeDestination;
	}

	/**
	 * @notice Disables shares holders fee functionality; detaches shares contract from
	 *      the HoldersRewardsDistributor, stops sending fees, stops sending syncs
	 *
	 * @notice Increases the protocol fee by the value of the disabled shares holders fee,
	 *      so that the sum of all the fees remains the same
	 *
	 * @notice Once disabled, the holders fee functionality cannot be enabled back
	 */
	function disableHoldersFee() public {
		// verify the access permission
		require(isSenderInRole(ROLE_HOLDERS_FEE_MANAGER), "access denied");

		// verify the holders functionality is enabled
		require(address(holdersFeeDestination) != address(0) || holdersFeePercent != 0, "not enabled");

		// emit an event first - to log both old and new values
		emit HoldersFeeDisabled(protocolFeePercent, protocolFeePercent + holdersFeePercent);

		// shares holders fee goes to the protocol from now on
		protocolFeePercent += holdersFeePercent;

		// zero the shares holders fee
		holdersFeeDestination = HoldersRewardsDistributor(address(0));
		holdersFeePercent = 0;
	}

	/**
	 * @inheritdoc TradeableShares
	 */
	function getHoldersFeePercent() public view returns(uint256) {
		// read the value from storage (immutable)
		return holdersFeePercent;
	}

	/**
	 * @inheritdoc TradeableShares
	 */
	function getHoldersFeeInfo() public view returns(HoldersRewardsDistributor feeDestination, uint256 feePercent) {
		// read fee destination first
		feeDestination = getHoldersFeeDestination();
		// if it's zero, zero down the fee as well
		feePercent = address(feeDestination) == address(0)? 0: getHoldersFeePercent();
	}

	/**
	 * @inheritdoc TradeableShares
	 */
	function getSubjectFeeInfo() public view returns(address feeDestination, uint256 feePercent) {
		// read fee destination first
		feeDestination = getSharesIssuer();
		// if it's zero, zero down the fee as well
		feePercent = feeDestination == address(0)? 0: getSubjectFeePercent();
	}

	/**
	 * @inheritdoc TradeableShares
	 */
	function getSubjectFeePercent() public view returns(uint256) {
		// read the value from storage (immutable)
		return subjectFeePercent;
	}

	/**
	 * @inheritdoc TradeableShares
	 */
	function getSharesIssuer() public view returns(address nftOwner) {
		// derive the NFT owner defined by the subject
		return SharesSubjectLib.getSharesIssuer(sharesSubject);
	}

	/**
	 * @inheritdoc TradeableShares
	 */
	function getSharesBalance(address _holder) public view returns(uint256 balance) {
		// read the value from storage
		return sharesBalances[_holder];
	}

	/**
	 * @inheritdoc TradeableShares
	 */
	function getSharesSupply() public view returns(uint256 supply) {
		// read the value from storage
		return sharesSupply;
	}

	/**
	 * @inheritdoc TradeableShares
	 */
	function getBuyPrice(uint256 _supply, uint256 _amount) public pure returns(uint256) {
		// this is the original friend tech formula
		return getPrice(_supply, _amount);
	}

	/**
	 * @inheritdoc TradeableShares
	 */
	function getSellPrice(uint256 _supply, uint256 _amount) public pure returns(uint256) {
		// this is the original friend tech formula
		return getPrice(_supply - _amount, _amount);
	}

	/**
	 * @inheritdoc TradeableShares
	 */
	function getBuyPriceAfterFee(
		uint256 _supply,
		uint256 _amount,
		uint256 _protocolFeePercent,
		uint256 _holdersFeePercent,
		uint256 _subjectFeePercent
	) public pure returns(uint256) {
		// this is the original friend tech formula
		uint256 price = getBuyPrice(_supply, _amount);
		uint256 protocolFee = price * _protocolFeePercent / 1 ether;
		uint256 holdersFee = price * _holdersFeePercent / 1 ether;
		uint256 subjectFee = price * _subjectFeePercent / 1 ether;
		return price + protocolFee + holdersFee + subjectFee;
	}

	/**
	 * @inheritdoc TradeableShares
	 */
	function getSellPriceAfterFee(
		uint256 _supply,
		uint256 _amount,
		uint256 _protocolFeePercent,
		uint256 _holdersFeePercent,
		uint256 _subjectFeePercent
	) public pure returns(uint256) {
		// this is the original friend tech formula
		uint256 price = getSellPrice(_supply, _amount);
		uint256 protocolFee = price * _protocolFeePercent / 1 ether;
		uint256 holdersFee = price * _holdersFeePercent / 1 ether;
		uint256 subjectFee = price * _subjectFeePercent / 1 ether;
		return price - protocolFee - holdersFee - subjectFee;
	}

	/**
	 * @inheritdoc TradeableShares
	 */
	function getBuyPrice(uint256 _amount) public view returns(uint256) {
		// delegate to `getBuyPrice`
		return getBuyPrice(getSharesSupply(), _amount);
	}

	/**
	 * @inheritdoc TradeableShares
	 */
	function getSellPrice(uint256 _amount) public view returns(uint256) {
		// delegate to `getSellPrice`
		return getSellPrice(getSharesSupply(), _amount);
	}

	/**
	 * @inheritdoc TradeableShares
	 */
	function getBuyPriceAfterFee(uint256 _amount) public view returns(uint256) {
		// read the effective fees values
		(, uint256 _protocolFeePercent) = getProtocolFeeInfo();
		(, uint256 _holdersFeePercent) = getHoldersFeeInfo();
		(, uint256 _subjectFeePercent) = getSubjectFeeInfo();

		// delegate to `getBuyPriceAfterFee`
		return getBuyPriceAfterFee(getSharesSupply(), _amount, _protocolFeePercent, _holdersFeePercent, _subjectFeePercent);
	}

	/**
	 * @inheritdoc TradeableShares
	 */
	function getSellPriceAfterFee(uint256 _amount) public view returns(uint256) {
		// read the effective fees values
		(, uint256 _protocolFeePercent) = getProtocolFeeInfo();
		(, uint256 _holdersFeePercent) = getHoldersFeeInfo();
		(, uint256 _subjectFeePercent) = getSubjectFeeInfo();

		// delegate to `getSellPriceAfterFee`
		return getSellPriceAfterFee(getSharesSupply(), _amount, _protocolFeePercent, _holdersFeePercent, _subjectFeePercent);
	}
}
