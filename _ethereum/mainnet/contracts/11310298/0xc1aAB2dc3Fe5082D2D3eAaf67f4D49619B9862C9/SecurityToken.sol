pragma solidity 0.6.6;

import "./Initializable.sol";

import "./ERC1400ERC20.sol";
import "./IERC1400.sol";


/**
 * @author Simon Dosch
 * @title SecurityToken
 * @dev Main contract of the micobo Security Token Contract Suite
 * inspired by and modeled after https://github.com/ConsenSys/UniversalToken
 * implements access control for GSN
 * implements new function bulkIssueByPartition
 * implements IERC1400
 * inherits ERC1400ERC20
 */
contract SecurityToken is ERC1400ERC20, IERC1400, Initializable {
	/**
	 * @dev Returns the version string of the {SecurityToken} for which this recipient implementation was built.
	 */
	function version() public view returns (string memory) {
		this;
		return "1.0.0";
	}

	// INITIALIZATION
	/**
	 * @dev Initialize ERC1400 + register
	 * the contract implementation in ERC1820Registry.
	 * @param name Name of the token.
	 * @param symbol Symbol of the token.
	 * @param granularity Granularity of the token.
	 */
	function initialize(
		string calldata name,
		string calldata symbol,
		uint256 granularity,
		uint256 cap,
		address admin,
		address controller,
		address issuer,
		address redeemer,
		address module_editor
	) external initializer {
		_add(bytes32("ADMIN"), admin);
		_add(bytes32("CONTROLLER"), controller);
		_add(bytes32("ISSUER"), issuer);
		_add(bytes32("REDEEMER"), redeemer);
		_add(bytes32("MODULE_EDITOR"), module_editor);

		_cap = cap;
		emit CapSet(cap);

		setInterfaceImplementation("ERC1400Token", address(this));

		_isIssuable = true;
		_isControllable = true;

		_owner = admin;
		emit OwnershipTransferred(address(0), admin);

		// ERC1400Raw
		_name = name;
		_symbol = symbol;
		_totalSupply = 0;

		// Token granularity can not be lower than 1
		require(granularity >= 1, "granularity too low");
		_granularity = granularity;

		// GSN
		_gsnMode = gsnMode.ALL;

		// Default RelayHub address, deployed on mainnet and all testnets at the same address
		_relayHub = 0xD216153c06E857cD7f72665E0aF1d7D82172F494;

		_RELAYED_CALL_ACCEPTED = 0;
		_RELAYED_CALL_REJECTED = 11;

		// How much gas is forwarded to postRelayedCall
		_POST_RELAYED_CALL_MAX_GAS = 100000;

		// Reentrancy
		_initializeReentrancyGuard();
	}

	// GSN
	/**
	 * @dev Adding access control by overriding this function!
	 * @return true if sender is GSN_CONTROLLER
	 */
	function _isGSNController() internal override view returns (bool) {
		return hasRole(bytes32("GSN_CONTROLLER"), _msgSender());
	}

	// BULK ISSUANCE
	/**
	 * @dev Mints to a number of token holder at the same time
	 * Must be issuable and tokenHolders and values must bne same length
	 * @param partition partition id tokens should be minted for
	 * @param tokenHolders addresses of all token receiver in the same order as "values"
	 * @param values amounts of tokens to be minted in the same order as "tokenHolders"
	 * @param data Additional data for issueByPartition
	 */
	function bulkIssueByPartition(
		bytes32 partition,
		address[] memory tokenHolders,
		uint256[] memory values,
		bytes memory data
	) public {
		require(_isIssuable, "token not issuable");
		require(tokenHolders.length <= 100, "too many tokenHolders");
		require(
			tokenHolders.length == values.length,
			"different array lengths"
		);

		for (uint256 i = 0; i < tokenHolders.length; i++) {
			require(_totalSupply.add(values[i]) <= _cap, "exceeds cap");
			_issueByPartition(
				partition,
				_msgSender(),
				tokenHolders[i],
				values[i],
				data,
				""
			);
		}
	}

	/********************** ERC1400 EXTERNAL FUNCTIONS **************************/

	/**
	 * [ERC1400 INTERFACE (1/9)]
	 * @dev Access a document associated with the token.
	 * @param documentName Short name (represented as a bytes32) associated to the document.
	 * @return Requested document + document hash.
	 */
	function getDocument(bytes32 documentName)
		external
		override
		view
		returns (string memory, bytes32)
	{
		return (
			_documents[documentName].docURI,
			_documents[documentName].docHash
		);
	}

	/**
	 * [ERC1400 INTERFACE (2/9)]
	 * @dev Associate a document with the token.
	 * @param documentName Short name (represented as a bytes32) associated to the document.
	 * @param uri Document content.
	 * @param documentHash Hash of the document [optional parameter].
	 */
	function setDocument(
		bytes32 documentName,
		string calldata uri,
		bytes32 documentHash
	) external override {
		require(
			hasRole(bytes32("DOCUMENT_EDITOR"), _msgSender()),
			"!DOCUMENT_EDITOR"
		);
		_documents[documentName] = Doc({ docURI: uri, docHash: documentHash });
		emit Document(documentName, uri, documentHash);
	}

	/**
	 * [ERC1400 INTERFACE (3/9)]
	 * @dev Know if the token can be controlled by operators.
	 * If a token returns 'false' for 'isControllable()'' then it MUST always return 'false' in the future.
	 * @return bool 'true' if the token can still be controlled by operators, 'false' if it can't anymore.
	 */
	function isControllable() external override view returns (bool) {
		return _isControllable;
	}

	/**
	 * [ERC1400 INTERFACE (4/9)]
	 * @dev Know if new tokens can be issued in the future.
	 * @return bool 'true' if tokens can still be issued by the issuer, 'false' if they can't anymore.
	 */
	function isIssuable() external override view returns (bool) {
		return _isIssuable;
	}

	/**
	 * [ERC1400 INTERFACE (5/9)]
	 * @dev Issue tokens from a specific partition.
	 * @param partition Name of the partition.
	 * @param tokenHolder Address for which we want to issue tokens.
	 * @param value Number of tokens issued.
	 * @param data Information attached to the issuance, by the issuer.
	 */
	function issueByPartition(
		bytes32 partition,
		address tokenHolder,
		uint256 value,
		bytes calldata data // onlyMinter is taken care of in _issue function
	) external override {
		require(_isIssuable, "token not issuable");

		// total cap is always the sum of all partitionCaps, so it can't be violated

		require(_totalSupply.add(value) <= _cap, "exceeds cap");

		_issueByPartition(
			partition,
			_msgSender(),
			tokenHolder,
			value,
			data,
			""
		);
	}

	/**
	 * [ERC1400 INTERFACE (6/9)]
	 * @dev Redeem tokens of a specific partition.
	 * only controllers can redeem
	 * @param partition Name of the partition.
	 * @param value Number of tokens redeemed.
	 * @param data Information attached to the redemption, by the redeemer.
	 */
	function redeemByPartition(
		bytes32 partition,
		uint256 value,
		bytes calldata data
	) external override {
		// only REDEEMER can burn tokens (checked in _redeem())

		_redeemByPartition(
			partition,
			_msgSender(),
			_msgSender(),
			value,
			data,
			""
		);
	}

	/**
	 * [ERC1400 INTERFACE (7/9)]
	 * @dev Redeem tokens of a specific partition.
	 * @param partition Name of the partition.
	 * @param tokenHolder Address for which we want to redeem tokens.
	 * @param value Number of tokens redeemed.
	 * @param data Information attached to the redemption.
	 * @param operatorData Information attached to the redemption, by the operator.
	 */
	function operatorRedeemByPartition(
		bytes32 partition,
		address tokenHolder,
		uint256 value,
		bytes calldata data,
		bytes calldata operatorData
	) external override {
		// only REDEEMER can burn tokens (checked in _redeem())

		require(
			_isOperatorForPartition(partition, _msgSender(), tokenHolder),
			"!CONTROLLER or !operator"
		);
		// Transfer Blocked - Identity restriction

		_redeemByPartition(
			partition,
			_msgSender(),
			tokenHolder,
			value,
			data,
			operatorData
		);
	}

	/**
	 * [ERC1400 INTERFACE (8/9)]
	 * function canTransferByPartition
	 * not implemented
	 */

	/**
	 * [ERC1400 INTERFACE (9/9)]
	 * function canOperatorTransferByPartition
	 * not implemented
	 */

	/********************** ERC1400 INTERNAL FUNCTIONS **************************/

	/**
	 * [INTERNAL]
	 * @dev Issue tokens from a specific partition.
	 * @param toPartition Name of the partition.
	 * @param operator The address performing the issuance.
	 * @param to Token recipient.
	 * @param value Number of tokens to issue.
	 * @param data Information attached to the issuance.
	 * @param operatorData Information attached to the issuance, by the operator (if any).
	 */

	function _issueByPartition(
		bytes32 toPartition,
		address operator,
		address to,
		uint256 value,
		bytes memory data,
		bytes memory operatorData
	) internal {
		_issue(operator, to, value, data, operatorData);
		_addTokenToPartition(to, toPartition, value);

		emit IssuedByPartition(
			toPartition,
			operator,
			to,
			value,
			data,
			operatorData
		);

		// purely for better visibility on etherscan
		emit Transfer(address(0), to, value);
	}

	/**
	 * [INTERNAL]
	 * @dev Redeem tokens of a specific partition.
	 * @param fromPartition Name of the partition.
	 * @param operator The address performing the redemption.
	 * @param from Token holder whose tokens will be redeemed.
	 * @param value Number of tokens to redeem.
	 * @param data Information attached to the redemption.
	 * @param operatorData Information attached to the redemption, by the operator (if any).
	 */

	function _redeemByPartition(
		bytes32 fromPartition,
		address operator,
		address from,
		uint256 value,
		bytes memory data,
		bytes memory operatorData
	) internal {
		require(
			_balanceOfByPartition[from][fromPartition] >= value,
			"insufficient balance"
		);
		// Transfer Blocked - Sender balance insufficient

		_removeTokenFromPartition(from, fromPartition, value);
		_redeem(operator, from, value, data, operatorData);

		emit RedeemedByPartition(
			fromPartition,
			operator,
			from,
			value,
			data,
			operatorData
		);

		// purely for better visibility on etherscan
		emit Transfer(from, address(0), value);
	}

	/********************** ERC1400 OPTIONAL FUNCTIONS **************************/

	/**
	 * [NOT MANDATORY FOR ERC1400 STANDARD]
	 * @dev Definitely renounce the possibility to control tokens on behalf of tokenHolders.
	 * Once set to false, '_isControllable' can never be set to 'true' again.
	 */
	function renounceControl() external override {
		require(hasRole(bytes32("ADMIN"), _msgSender()), "!ADMIN");
		_isControllable = false;
	}

	/**
	 * [NOT MANDATORY FOR ERC1400 STANDARD]
	 * @dev Definitely renounce the possibility to issue new tokens.
	 * Once set to false, '_isIssuable' can never be set to 'true' again.
	 */
	function renounceIssuance() external override {
		require(hasRole(bytes32("ADMIN"), _msgSender()), "!ADMIN");
		_isIssuable = false;
	}
}
