// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.8.0;

import "./Module.sol";
import "./UsingTellor.sol";

contract TellorModule is Module, UsingTellor {
    // Events
    event ProposalAdded(bytes32 indexed queryId, string indexed proposalId);
    event TellorModuleSetup(
        address indexed initiator,
        address indexed avatar,
        address target
    );
    // Storage
    bool private initialized;
    uint32 public resultExpiration;
    bytes32 public constant DOMAIN_SEPARATOR_TYPEHASH =
        0x47e79534a245952e8b16893a336b85a3d9ea9fa8c573f3d803afb92a79469218;
    // keccak256(
    //     "EIP712Domain(uint256 chainId,address verifyingContract)"
    // );
    // Mapping of proposalHash to transactionHash to execution state
    mapping(bytes32 => mapping(bytes32 => bool))
        public executedProposalTransactions;
    bytes32 public constant INVALIDATED =
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    uint32 public cooldown;
    // Mapping of proposal hash to proposal id. Special case: INVALIDATED for proposal hashes that have been invalidated
    mapping(bytes32 => bytes32) public queryIds;
    bytes32 public constant TRANSACTION_TYPEHASH =
        0x72e9670a7ee00f5fbf1049b8c38e3f22fab7e9b85029e85cf9412f17fdd5c2ad;

    // keccak256(
    //     "Transaction(address to,uint256 value,bytes data,uint8 operation,uint256 nonce)"
    // );
    /*Functions*/
    /**
     * @param _avatar Address of the avatar (e.g. a Safe)
     * @param _target Address of the contract that will call exec function
     * @param _tellorAddress Address of the Tellor oracle contract
     * @param _cooldown Cooldown in seconds that should be required after a oracle provided result
     * @param _expiration Duration that a positive result of the oracle is valid in seconds (or 0 if valid forever)
     * @notice There need to be at least 60 seconds between end of cooldown and expiration
     */
    constructor(
        address _avatar,
        address _target,
        address payable _tellorAddress,
        uint32 _cooldown,
        uint32 _expiration
    ) UsingTellor(_tellorAddress) {
        bytes memory initParams = abi.encode(
            _avatar,
            _target,
            _tellorAddress,
            _cooldown,
            _expiration
        );
        setUp(initParams);
    }

    /**
     * @dev Function to add a proposal that should be considered for execution
     * @param _proposalId Id that should identify the proposal uniquely
     * @param _txHashes EIP-712 hashes of the transactions that should be executed
     */
    function addProposal(string memory _proposalId, bytes32[] memory _txHashes)
        public
    {
        // We generate the proposal string used for the oracle
        string memory _proposal = buildProposal(_proposalId, _txHashes);
        bytes32 _proposalHash = keccak256(bytes(_proposal));
        require(
            queryIds[_proposalHash] == bytes32(0),
            "Proposal has already been submitted"
        );
        bytes32 _queryId = getQueryId(_proposalId);
        // Set the proposal hash for this query id
        queryIds[_proposalHash] = _queryId;
        emit ProposalAdded(_queryId, _proposalId);
    }

    /**
     * @dev Build the proposal by combining the proposalId and the hex string of the hash of the txHashes
     * @param _proposalId Id of the proposal that proposes to execute the transactions represented by the txHashes
     * @param _txHashes EIP-712 Hashes of the transactions that should be executed
     */
    function buildProposal(
        string memory _proposalId,
        bytes32[] memory _txHashes
    ) public pure returns (string memory) {
        string memory _txsHash = _bytes32ToAsciiString(
            keccak256(abi.encodePacked(_txHashes))
        );
        return
            string(abi.encodePacked(_proposalId, bytes3(0xe2909f), _txsHash));
    }

    /**
     * @dev Executes the transactions of a proposal via the target if accepted
     * @param _proposalId Id that should identify the proposal uniquely
     * @param _txHashes EIP-712 hashes of the transactions that should be executed
     * @param _to Target of the transaction that should be executed
     * @param _value Wei value of the transaction that should be executed
     * @param _data Data of the transaction that should be executed
     * @param _operation Operation (Call or Delegatecall) of the transaction that should be executed
     * @notice The txIndex used by this function is always 0
     */
    function executeProposal(
        string memory _proposalId,
        bytes32[] memory _txHashes,
        address _to,
        uint256 _value,
        bytes memory _data,
        Enum.Operation _operation
    ) public {
        executeProposalWithIndex(
            _proposalId,
            _txHashes,
            _to,
            _value,
            _data,
            _operation,
            0
        );
    }

    /**
     * @dev Executes the transactions of a proposal via the target if accepted
     * @param _proposalId Id that should identify the proposal uniquely
     * @param _txHashes EIP-712 hashes of the transactions that should be executed
     * @param _to Target of the transaction that should be executed
     * @param _value Wei value of the transaction that should be executed
     * @param _data Data of the transaction that should be executed
     * @param _operation Operation (Call or Delegatecall) of the transaction that should be executed
     * @param _txIndex Index of the transaction hash in txHashes. This is used as the nonce for the transaction, to make the tx hash unique
     */
    function executeProposalWithIndex(
        string memory _proposalId,
        bytes32[] memory _txHashes,
        address _to,
        uint256 _value,
        bytes memory _data,
        Enum.Operation _operation,
        uint256 _txIndex
    ) public {
        // We use the hash of the proposal to check the execution state, as the other parameters might change, but the proposal not
        bytes32 _proposalHash = keccak256(
            bytes(buildProposal(_proposalId, _txHashes))
        );
        // Lookup query id for this proposal
        bytes32 _queryId = queryIds[_proposalHash];
        // Proposal hash needs to set to be eligible for execution
        require(
            _queryId != bytes32(0),
            "No query id set for provided proposal"
        );
        require(_queryId != INVALIDATED, "Proposal has been invalidated");
        bytes32 _txHash = getTransactionHash(
            _to,
            _value,
            _data,
            _operation,
            _txIndex
        );
        require(_txHashes[_txIndex] == _txHash, "Unexpected transaction hash");
        (
            bool _ifRetrieve,
            bytes memory _valueRetrieved,
            uint256 _timestampReceived
        ) = getDataBefore(_queryId, block.timestamp);
        require(_ifRetrieve, "Data not retrieved");
        // The result is valid in the time after the cooldown and before the expiration time (if set).
        require(
            _timestampReceived + uint256(cooldown) < block.timestamp,
            "Wait for additional cooldown"
        );
        bool _didPass = abi.decode(_valueRetrieved, (bool));
        require(_didPass, "Transaction was not approved");
        uint32 _expiration = resultExpiration;
        require(
            _expiration == 0 ||
                _timestampReceived + uint256(_expiration) >= block.timestamp,
            "Result has expired"
        );
        // Check this is either the first transaction in the list or that the previous proposal was already approved
        require(
            _txIndex == 0 ||
                executedProposalTransactions[_proposalHash][
                    _txHashes[_txIndex - 1]
                ],
            "Previous transaction not executed yet"
        );
        // Check that this proposal was not executed yet
        require(
            !executedProposalTransactions[_proposalHash][_txHash],
            "Cannot execute transaction again"
        );
        // Mark transaction as executed
        executedProposalTransactions[_proposalHash][_txHash] = true;
        // Execute the transaction via the target.
        require(
            exec(_to, _value, _data, _operation),
            "Module transaction failed"
        );
    }

    /**
     * @dev Generate the query id.
     * @param _proposalId Id that should identify the proposal uniquely
     * @notice It is required that this is the same as for the oracle implementation used.
     */
    function getQueryId(string memory _proposalId)
        public
        pure
        returns (bytes32)
    {
        bytes32 _queryId = keccak256(
            abi.encode("Snapshot", abi.encode(_proposalId))
        );
        return _queryId;
    }

    /**
     * @dev Returns the chain id used by this contract.
     */
    function getChainId() public view returns (uint256) {
        uint256 _id;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            _id := chainid()
        }
        return _id;
    }

    /**
     * @dev Generates the data for the module transaction hash (required for signing)
     * @param _to Target of the transaction that should be executed
     * @param _value Wei value of the transaction that should be executed
     * @param _data Data of the transaction that should be executed
     * @param _operation Operation (Call or Delegatecall) of the transaction that should be executed
     * @param _nonce Nonce of the transaction that should be executed
     */
    function generateTransactionHashData(
        address _to,
        uint256 _value,
        bytes memory _data,
        Enum.Operation _operation,
        uint256 _nonce
    ) internal view returns (bytes memory) {
        uint256 _chainId = getChainId();
        bytes32 _domainSeparator = keccak256(
            abi.encode(DOMAIN_SEPARATOR_TYPEHASH, _chainId, this)
        );
        bytes32 _transactionHash = keccak256(
            abi.encode(
                TRANSACTION_TYPEHASH,
                _to,
                _value,
                keccak256(_data),
                _operation,
                _nonce
            )
        );
        return
            abi.encodePacked(
                bytes1(0x19),
                bytes1(0x01),
                _domainSeparator,
                _transactionHash
            );
    }

    /**
     * @dev Generates the hash for the module transaction
     * @param _to Target of the transaction
     * @param _value Wei value of the transaction
     * @param _data Data of the transaction
     * @param _operation Operation (Call or Delegatecall) of the transaction
     * @param _nonce Nonce of the transaction
     */
    function getTransactionHash(
        address _to,
        uint256 _value,
        bytes memory _data,
        Enum.Operation _operation,
        uint256 _nonce
    ) public view returns (bytes32) {
        return
            keccak256(
                generateTransactionHashData(
                    _to,
                    _value,
                    _data,
                    _operation,
                    _nonce
                )
            );
    }

    /**
     * @dev Marks a proposal with an expired result as invalid, preventing execution of the connected transactions
     * @param _proposalHash Proposal hash calculated based on the proposal id and txHashes
     */
    function markProposalWithExpiredResultAsInvalid(bytes32 _proposalHash)
        public
    {
        uint32 _expirationDuration = resultExpiration;
        require(_expirationDuration > 0, "Results are valid forever");
        bytes32 _queryId = queryIds[_proposalHash];
        require(_queryId != INVALIDATED, "Proposal is already invalidated");
        require(
            _queryId != bytes32(0),
            "No query id set for provided proposal"
        );
        (
            bool _ifRetrieve,
            bytes memory _valueRetrieved,
            uint256 _timestampRetrieved
        ) = getDataBefore(_queryId, block.timestamp);
        require(_ifRetrieve, "Data not retrieved");
        bool _didPass = abi.decode(_valueRetrieved, (bool));
        require(_didPass, "Transaction was not approved");
        require(
            _timestampRetrieved + uint256(_expirationDuration) <
                block.timestamp,
            "Result has not expired yet"
        );
        queryIds[_proposalHash] = INVALIDATED;
    }

    /**
    //  * @dev Initializes the contract with the given parameters.
    //  * @param _initParams Initialization parameters for the contract
    //  */
    function setUp(bytes memory _initParams) public override {
        (
            address _avatar,
            address _target,
            address _tellorAddress,
            uint32 _cooldown,
            uint32 _expiration
        ) = abi.decode(
                _initParams,
                (address, address, address, uint32, uint32)
            );
        require(
            !initialized,
            "Initializable: contract is already initialized"
        );
        initialized = true;

        require(_avatar != address(0), "Avatar can not be zero address");
        require(_target != address(0), "Target can not be zero address");
        require(
            _expiration == 0 || _expiration - _cooldown >= 60,
            "There need to be at least 60s between end of cooldown and expiration"
        );
        avatar = _avatar;
        target = _target;
        tellor = ITellor(payable(_tellorAddress));
        resultExpiration = _expiration;
        cooldown = _cooldown;
        emit TellorModuleSetup(msg.sender, _avatar, _target);
    }

    /**
     * @dev converts bytes32 to string
     * @param _bytes bytes32 to be converted
     */
    function _bytes32ToAsciiString(bytes32 _bytes)
        internal
        pure
        returns (string memory)
    {
        bytes memory s = new bytes(64);
        for (uint256 i = 0; i < 32; i++) {
            uint8 b = uint8(bytes1(_bytes << (i * 8)));
            uint8 hi = uint8(b) / 16;
            uint8 lo = uint8(b) % 16;
            s[2 * i] = _char(hi);
            s[2 * i + 1] = _char(lo);
        }
        return string(s);
    }

    /**
     * @dev converts uint8 to char
     * @param _b uint8 to be converted
     */
    function _char(uint8 _b) internal pure returns (bytes1 c) {
        if (_b < 10) return bytes1(_b + 0x30);
        else return bytes1(_b + 0x57);
    }
}
