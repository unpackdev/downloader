pragma solidity 0.6.6;


/**
 * @title IERC1400Partition partially fungible token standard
 * @dev ERC1400Partition interface
 */
interface IERC1400Partition {
	/**
	 * @dev ERC20 backwards-compatibility
	 */
	event Transfer(address indexed from, address indexed to, uint256 value);

	/********************** NEW FUNCTIONS **************************/

	/**
	 * @dev Returns the total supply of a given partition
	 * For ERC20 compatibility via proxy
	 * @param partition Requested partition
	 * @return uint256 _totalSupplyByPartition
	 */
	function totalSupplyByPartition(bytes32 partition)
		external
		view
		returns (uint256);

	/********************** ERC1400Partition EXTERNAL FUNCTIONS **************************/

	/**
	 * [ERC1400Partition INTERFACE (1/10)]
	 * @dev Get balance of a tokenholder for a specific partition.
	 * @param partition Name of the partition.
	 * @param tokenHolder Address for which the balance is returned.
	 * @return Amount of token of partition 'partition' held by 'tokenHolder' in the token contract.
	 */
	function balanceOfByPartition(bytes32 partition, address tokenHolder)
		external
		view
		returns (uint256);

	/**
	 * [ERC1400Partition INTERFACE (2/10)]
	 * @dev Get partitions index of a tokenholder.
	 * @param tokenHolder Address for which the partitions index are returned.
	 * @return Array of partitions index of 'tokenHolder'.
	 */
	function partitionsOf(address tokenHolder)
		external
		view
		returns (bytes32[] memory);

	/**
	 * [ERC1400Partition INTERFACE (3/10)]
	 * @dev Transfer tokens from a specific partition.
	 * @param partition Name of the partition.
	 * @param to Token recipient.
	 * @param value Number of tokens to transfer.
	 * @param data Information attached to the transfer, by the token holder.
	 * @return Destination partition.
	 */
	function transferByPartition(
		bytes32 partition,
		address to,
		uint256 value,
		bytes calldata data
	) external returns (bytes32);

	/**
	 * [ERC1400Partition INTERFACE (4/10)]
	 * @dev Transfer tokens from a specific partition through an operator.
	 * @param partition Name of the partition.
	 * @param from Token holder.
	 * @param to Token recipient.
	 * @param value Number of tokens to transfer.
	 * @param data Information attached to the transfer.
	 * @param operatorData Information attached to the transfer, by the operator.
	 * @return Destination partition.
	 */
	function operatorTransferByPartition(
		bytes32 partition,
		address from,
		address to,
		uint256 value,
		bytes calldata data,
		bytes calldata operatorData
	) external returns (bytes32);

	/**
	 * [ERC1400Partition INTERFACE (5/10)]
	 * function getDefaultPartitions
	 * default partition is always equal to _totalPartitions
	 */

	/**
	 * [ERC1400Partition INTERFACE (6/10)]
	 * function setDefaultPartitions
	 * default partition is always equal to _totalPartitions
	 */

	/**
	 * [ERC1400Partition INTERFACE (7/10)]
	 * @dev Get controllers for a given partition.
	 * Function used for ERC1400Raw and ERC20 backwards compatibility.
	 * @param partition Name of the partition.
	 * @return Array of controllers for partition.
	 */
	function controllersByPartition(bytes32 partition)
		external
		view
		returns (address[] memory);

	/**
	 * [ERC1400Partition INTERFACE (8/10)]
	 * @dev Set 'operator' as an operator for 'msg.sender' for a given partition.
	 * @param partition Name of the partition.
	 * @param operator Address to set as an operator for 'msg.sender'.
	 */
	function authorizeOperatorByPartition(bytes32 partition, address operator)
		external;

	/**
	 * [ERC1400Partition INTERFACE (9/10)]
	 * @dev Remove the right of the operator address to be an operator on a given
	 * partition for 'msg.sender' and to transfer and redeem tokens on its behalf.
	 * @param partition Name of the partition.
	 * @param operator Address to rescind as an operator on given partition for 'msg.sender'.
	 */
	function revokeOperatorByPartition(bytes32 partition, address operator)
		external;

	/**
	 * [ERC1400Partition INTERFACE (10/10)]
	 * @dev Indicate whether the operator address is an operator of the tokenHolder
	 * address for the given partition.
	 * @param partition Name of the partition.
	 * @param operator Address which may be an operator of tokenHolder for the given partition.
	 * @param tokenHolder Address of a token holder which may have the operator address as an operator for the given partition.
	 * @return 'true' if 'operator' is an operator of 'tokenHolder' for partition 'partition' and 'false' otherwise.
	 */
	function isOperatorForPartition(
		bytes32 partition,
		address operator,
		address tokenHolder
	) external view returns (bool); // 10/10

	/********************* ERC1400Partition OPTIONAL FUNCTIONS ***************************/

	/**
	 * [NOT MANDATORY FOR ERC1400Partition STANDARD]
	 * @dev Get list of existing partitions.
	 * @return Array of all exisiting partitions.
	 */
	function totalPartitions() external view returns (bytes32[] memory);

	/************** ERC1400Raw BACKWARDS RETROCOMPATIBILITY *************************/

	/**
	 * @dev Transfer the amount of tokens from the address 'msg.sender' to the address 'to'.
	 * @param to Token recipient.
	 * @param value Number of tokens to transfer.
	 * @param data Information attached to the transfer, by the token holder.
	 */
	function transferWithData(
		address to,
		uint256 value,
		bytes calldata data
	) external;

	/**
	 * @dev Transfer the amount of tokens on behalf of the address 'from' to the address 'to'.
	 * @param from Token holder (or 'address(0)' to set from to 'msg.sender').
	 * @param to Token recipient.
	 * @param value Number of tokens to transfer.
	 * @param data Information attached to the transfer, and intended for the token holder ('from').
	 */
	function transferFromWithData(
		address from,
		address to,
		uint256 value,
		bytes calldata data,
		bytes calldata operatorData
	) external;

	/**
	 * @dev Event emitted when tokens are transferred from a partition
	 */
	event TransferByPartition(
		bytes32 indexed fromPartition,
		address operator,
		address indexed from,
		address indexed to,
		uint256 value,
		bytes data,
		bytes operatorData
	);

	/**
	 * @dev Event emitted when tokens are transferred between partitions
	 */
	event ChangedPartition(
		bytes32 indexed fromPartition,
		bytes32 indexed toPartition,
		uint256 value
	);

	/**
	 * @dev Event emitted when an operator is authorized for a partition
	 */
	event AuthorizedOperatorByPartition(
		bytes32 indexed partition,
		address indexed operator,
		address indexed tokenHolder
	);

	/**
	 * @dev Event emitted when an operator authorization is revoked for a partition
	 */
	event RevokedOperatorByPartition(
		bytes32 indexed partition,
		address indexed operator,
		address indexed tokenHolder
	);
}
