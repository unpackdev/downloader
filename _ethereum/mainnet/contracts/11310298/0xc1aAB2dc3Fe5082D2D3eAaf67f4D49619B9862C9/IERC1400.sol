pragma solidity 0.6.6;


/**
 * @title IERC1400 token standard
 * @dev ERC1400 interface
 */
interface IERC1400 {
	// Document Management
	/**
	 * [ERC1400 INTERFACE (1/9)]
	 * @dev Access a document associated with the token.
	 * @param documentName Short name (represented as a bytes32) associated to the document.
	 * @return Requested document + document hash.
	 */
	function getDocument(bytes32 documentName)
		external
		view
		returns (string memory, bytes32); // 1/9

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
	) external; // 2/9

	/**
	 * @dev Event emitted when a new document is set
	 */
	event Document(bytes32 indexed name, string uri, bytes32 documentHash);

	/**
	 * [ERC1400 INTERFACE (3/9)]
	 * @dev Know if the token can be controlled by operators.
	 * If a token returns 'false' for 'isControllable()'' then it MUST always return 'false' in the future.
	 * @return bool 'true' if the token can still be controlled by operators, 'false' if it can't anymore.
	 */
	function isControllable() external view returns (bool); // 3/9

	/**
	 * [ERC1400 INTERFACE (4/9)]
	 * @dev Know if new tokens can be issued in the future.
	 * @return bool 'true' if tokens can still be issued by the issuer, 'false' if they can't anymore.
	 */
	function isIssuable() external view returns (bool); // 4/9

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
		bytes calldata data
	) external; // 5/9

	/**
	 * @dev Event emitted when tokens were issued to a partition
	 */
	event IssuedByPartition(
		bytes32 indexed partition,
		address indexed operator,
		address indexed to,
		uint256 value,
		bytes data,
		bytes operatorData
	);

	/**
	 * [ERC1400 INTERFACE (6/9)]
	 * @dev Redeem tokens of a specific partition.
	 * @param partition Name of the partition.
	 * @param value Number of tokens redeemed.
	 * @param data Information attached to the redemption, by the redeemer.
	 */
	function redeemByPartition(
		bytes32 partition,
		uint256 value,
		bytes calldata data
	) external; // 6/9

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
	) external; // 7/9

	/**
	 * @dev Event emitted when tokens are redeemed from a partition
	 */
	event RedeemedByPartition(
		bytes32 indexed partition,
		address indexed operator,
		address indexed from,
		uint256 value,
		bytes data,
		bytes operatorData
	);

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

	/********************** ERC1400 OPTIONAL FUNCTIONS **************************/

	/**
	 * [NOT MANDATORY FOR ERC1400 STANDARD]
	 * @dev Definitely renounce the possibility to control tokens on behalf of tokenHolders.
	 * Once set to false, '_isControllable' can never be set to 'true' again.
	 */
	function renounceControl() external;

	/**
	 * [NOT MANDATORY FOR ERC1400 STANDARD]
	 * @dev Definitely renounce the possibility to issue new tokens.
	 * Once set to false, '_isIssuable' can never be set to 'true' again.
	 */
	function renounceIssuance() external;
}
