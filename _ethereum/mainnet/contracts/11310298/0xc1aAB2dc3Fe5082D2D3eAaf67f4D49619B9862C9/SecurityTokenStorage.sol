pragma solidity 0.6.6;

import "./IConstraintModule.sol";


contract SecurityTokenStorage {
	// Administrable
	/**
	 * @dev Contains all the roles mapped to wether an account holds it or not
	 */
	mapping(bytes32 => mapping(address => bool)) internal _roles;

	// Constrainable
	/**
	 * @dev Contains active constraint modules for a given partition
	 */
	mapping(bytes32 => IConstraintModule[]) internal _modulesByPartition;

	// ERC1400Raw
	string internal _name;
	string internal _symbol;
	uint256 internal _granularity;
	uint256 internal _totalSupply;

	/**
	 * @dev Indicate whether the token can still be controlled by operators or not anymore.
	 */
	bool internal _isControllable;

	/**
	 * @dev Indicates the paused state
	 */
	bool internal _paused;

	/**
	 * @dev Mapping from tokenHolder to balance.
	 */
	mapping(address => uint256) internal _balances;

	/**
	 * @dev Mapping from (operator, tokenHolder) to authorized status. [TOKEN-HOLDER-SPECIFIC]
	 */
	mapping(address => mapping(address => bool)) internal _authorizedOperator;

	// ERC1400Partition
	/**
	 * @dev Contains complete list of partitions that hold tokens.
	 * Is used for ERC20 transfer
	 */
	bytes32[] internal _totalPartitions;

	/**
	 * @dev Mapping from partition to their index.
	 */
	mapping(bytes32 => uint256) internal _indexOfTotalPartitions;

	/**
	 * @dev Mapping from partition to global balance of corresponding partition.
	 */
	mapping(bytes32 => uint256) internal _totalSupplyByPartition;

	/**
	 * @dev Mapping from tokenHolder to their partitions.
	 */
	mapping(address => bytes32[]) internal _partitionsOf;

	/**
	 * @dev Mapping from (tokenHolder, partition) to their index.
	 */
	mapping(address => mapping(bytes32 => uint256)) internal _indexOfPartitionsOf;

	/**
	 * @dev Mapping from (tokenHolder, partition) to balance of corresponding partition.
	 */
	mapping(address => mapping(bytes32 => uint256)) internal _balanceOfByPartition;

	/**************** Mappings to find partition operators ************************/
	/**
	 * @dev Mapping from (tokenHolder, partition, operator) to 'approved for partition' status. [TOKEN-HOLDER-SPECIFIC]
	 */
	mapping(address => mapping(bytes32 => mapping(address => bool))) internal _authorizedOperatorByPartition;

	/**
	 * @dev Mapping from partition to controllers for the partition. [NOT TOKEN-HOLDER-SPECIFIC]
	 */
	mapping(bytes32 => address[]) internal _controllersByPartition;

	// INFO partition controllers can be set by the admin just like other roles
	// Mapping from (partition, operator) to PartitionController status. [NOT TOKEN-HOLDER-SPECIFIC]
	// mapping(bytes32 => mapping(address => bool)) internal _isControllerByPartition;
	/****************************************************************************/

	// ERC1400ERC20
	/**
	 * @dev Mapping from (tokenHolder, spender) to allowed value.
	 */
	mapping(address => mapping(address => uint256)) internal _allowances;

	// ERC1400
	struct Doc {
		string docURI;
		bytes32 docHash;
	}

	/**
	 * @dev Mapping for token URIs.
	 */
	mapping(bytes32 => Doc) internal _documents;

	/**
	 * @dev Indicate whether the token can still be issued by the issuer or not anymore.
	 */
	bool internal _isIssuable;

	// Capped
	/**
	 * @dev Overall cap of the security token
	 */
	uint256 internal _cap;

	// Ownable
	/**
	 * @dev Owner of the security token
	 */
	address internal _owner;

	// GSN
	/**
	 * @dev Enum describing the possible GSN modes
	 */
	enum gsnMode { ALL, MODULE, NONE }

	/**
	 * @dev Can be set to accept ALL, NONE or MODULE mode
	 * Initialized with ALL
	 */
	gsnMode internal _gsnMode;

	/**
	 * @dev Default RelayHub address, deployed on mainnet and all testnets at the same address
	 */
	address internal _relayHub;

	uint256 internal _RELAYED_CALL_ACCEPTED;
	uint256 internal _RELAYED_CALL_REJECTED;

	/**
	 * @dev How much gas is forwarded to postRelayedCall
	 */
	uint256 internal _POST_RELAYED_CALL_MAX_GAS;

	// ReentrancyGuard
	bool internal _notEntered;
}
