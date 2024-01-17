// SPDX-License-Identifier: copyleft-next-0.3.1
// CollyptoManager Contract v1.0.0
pragma solidity ^0.8.17 < 0.9.0;
import "./Collypto.sol";

/**
 * @title Collypto Manager
 * @author Matthew McKnight - Collypto Technologies, Inc.
 * @notice This contract provides stratified access control to all utility and
 * management functions in the Collypto contract.
 * @dev This contract is the implementation of the Collypto Manager on the
 * Ethereum blockchain.
 *
 * OVERVIEW
 * This contract operates as an application specific multiplexed multisignature
 * access control system with social recovery. Operations are stratified into a
 * defined set of operator classes, where each class may conduct a defined set
 * of operations. Management and utility operations are enacted via a proposal
 * system where the proposal ID is generated using the enumerated {Operations}
 * value and data parameters of the operation itself. We have not designed this
 * contract to be upgradable. When we need to update it, we will simply
 * discontinue use of the current contract instance in favor of the newest
 * version of the contract.
 * 
 * PROPOSAL SYSTEM
 * When a utility or management operation function is called by an authorized
 * operator, a proposal is created with an ID that is generated using a
 * uniquely deterministic hash of its input parameters. When a given proposal
 * receives a majority of approvals from its authorized operators, this
 * contract will attempt to execute it on the Collypto contract and will return
 * the most recent proposal object available (after its final approval), in
 * addition to the Boolean result of its execution.
 *
 * Proposals are stored in the format defined in the {Proposal} struct, and
 * {Proposal} records are stored in the {_proposalMap} for O(1) retrieval, and
 * all active proposal IDs are maintained in the {_proposalList} for aggregated
 * reference and deletion. Consequently, this contract does not support
 * redundant proposals, and a {Proposal} record with a given {id} value and
 * parameters may be recreated and executed multiple times, but the {index}
 * value of each subsequent {Proposal} record will be unique for a given
 * instance of this contract, because it represents the value of
 * {_currentProposalIndex} when that proposal was created, and the value of
 * {_currentProposalIndex} cannot be reset.
 *
 * When an operator calls a utility or management function using an Ethereum
 * account belonging to the required operator class, this contract will
 * determine whether or not they represent a majority of operators of that
 * class. If the required operator class has less than two operators, the
 * operation will execute immediately, and the {id} value of the generated
 * {Proposal} record will be returned with the execution result, otherwise,
 * that {Proposal} record will be stored in the {_proposalMap}, its {id} value
 * will be added to the {_proposalList}, and the {id} value of the generated
 * {Proposal} record will be returned with a "false" value indicating that the
 * proposal was not immediately executed. Subsequent calls to the same utility
 * operation with identical input parameters will add the approval of the
 * calling operator's address (if authorized) to the {approvers} list of the
 * target {Proposal} record and the {_hasApproved} mapping for O(1) access.
 * 
 * When an approval breaks the majority threshold of greater than half of the
 * authorized operators of a given class, the proposal will be executed, the
 * corresponding {Proposal} record will be deleted, and the {id} value of that
 * {Proposal} record will be returned to the calling operator with a
 * Boolean value representing the execution result of that proposal.
 *
 * OPERATOR CLASSES
 * There are nine distinct operator classes in this contract that may be used
 * to conduct various operations within the Collypto contract and this contract
 * itself. A "management operation" can be defined as any operation that may
 * only be conducted by an operator with a Prime key, and a "utility
 * operation" can be defined as any operation to be executed in the Collypto
 * contract that requires a key belonging to any of the other eight classes in
 * the {OperatorClasses} enumeration. Operator authorizations are maintained in
 * the {_authorizedOperatorMap} for O(1) retrieval, and the list of authorized
 * operators for each operator class is maintained in the
 * {_authorizedOperatorList} for aggregated reference and removal.
 *
 * STANDARD OPERATIONS ({getCollyptoAddress}, {getProposalRecord},
 * {getActiveProposals}, {totalActiveProposals}, {getCurrentProposalIndex},
 * {getCurrentOperators}, {revokeApproval})
 * This contract contains seven standard operations that may be conducted by an
 * operator using any Ethereum account to retrieve proposal information, view
 * authorized operators by class, or revoke an approval on a proposal that was
 * previously approved by that account.
 *
 * UTILITY OPERATIONS ({updateUserStatus}, {forceTransfer}, {freeze},
 * {unfreeze}, {lock}, {unlock}, {mint}, {burn})
 * This contract contains eight utility operations that correspond to the
 * utility operations of the Collypto contract. Each utility operation may only
 * be conducted by an operator using an Ethereum account that is authorized as
 * the operator class required for the specified operation.
 *
 * MANAGEMENT OPERATIONS ({pause}, {unpause}, {addManager}, {removeManager},
 * {updateCollyptoAddress}, {removeProposal}, {purgeProposals}, {addOperator},
 * {removeOperator}, {purgeOperators})
 * This contract contains ten management operations that are used to maintain
 * the address and running state of the Collypto contract and regulate
 * operators and proposals within this contract. Management operations may only
 * be conducted by an operator using an Ethereum account with Prime
 * authorization.
 *
 * COLLYPTO CONTRACT MANAGEMENT ({pause}, {unpause}, {addManager},
 * {removeManager}, {updateCollyptoAddress})
 * All Collypto contract operations are multiplexed through the proposal system
 * and directed upon execution to the address maintained in {_collyptoAddress}.
 * In the event that we need to update the Collypto contract in a way that
 * doesn't require a corresponding code change in this contract, we may update
 * the Collypto reference address using the {updateCollyptoAddress} function.
 *
 * The {addManager} function allows Prime operators to add a new management
 * contract address to the Collypto contract (for updating this contract), and
 * the {removeManager} function allows Prime operators to remove the current
 * management address of this contract from the Collypto manager list after the
 * new contract address has been successfully added. The {pause} and {unpause}
 * functions allow Prime operators to pause the running state of the Collypto
 * contract and unpause it to respectively suspend and resume users' ability to
 * conduct standard Collypto operations.
 *
 * PROPOSAL REMOVAL ({removeProposal}, {purgeProposals})
 * There are two management functions that may be utilized by Prime operators
 * to permenantly delete proposals, removing their corresponding {Proposal}
 * records from the {_proposalMap} and {_proposalList} (all proposals in those
 * mappings are considered "active proposals"). The {removeProposal} function
 * removes a single {Proposal} record with the {id} value provided, and the
 * {purgeProposals} function removes all active proposals.
 *
 * OPERATOR MANAGEMENT ({addOperator}, {removeOperator}, {purgeOperators})
 * In the event that we need to add one or more authorized operators to a given
 * operator class, we can utilize the {addOperator} function to add individual
 * address authorizations for that class. To revoke operator authorizations, we
 * can utilize the {removeOperator} function with a provided operator class and
 * address to remove the provided address from the authorization mappings, or
 * we can utilize {purgeOperators} with a provided operator class to clear all
 * authorizations for that class (in the event that a majority of authorized
 * accounts are compromised). Prime operators cannot be purged, and a majority
 * compromise of Prime operators means that we would need to purge managers
 * from the Collypto contract itself and redeploy this contract.
 */
contract CollyptoManager {
    /**
     * @dev Enumeration containing all valid class values that may be assigned
     * to an operator using the {_authorizedOperatorMap} mapping and the
     * {_authorizedOperatorList} array
     */    
    enum OperatorClasses { 
        Prime,        
        Arbiter,
        Dispatch,
        Freeze,
        Unfreeze,
        Lock,
        Unlock,
        Mint,
        Burn
    }

    /**
     * @dev Enumeration containing values that correspond to all valid
     * operations that may be conducted by an operator using a management or
     * utility key
     */         
    enum Operations {
        Pause,        
        Unpause,
        AddManager,
        RemoveManager,
        UpdateCollyptoAddress,
        RemoveProposal,
        PurgeProposals,                
        AddOperator,
        RemoveOperator,
        PurgeOperators,
        SetUserStatus,
        ForceTransfer,
        Freeze,
        Unfreeze,
        Lock,
        Unlock,
        Mint,       
        Burn
    }

    /**
     * @dev Struct encapsulating all required proposal properties utilized in
     * consensus logic
     */
    struct Proposal {
        uint256 id;
        uint256 index;
        Operations operation;
        address[] addressList;
        uint256 data;
        address[] approvers;
    }
    
    /**
     * @dev Mapping of Prime and Utility operators (indexed by operator class
     * and Ethereum account address)
     */
    mapping(OperatorClasses => mapping(address => bool))
        private _authorizedOperatorMap;

    /**
     * @dev Mapping of lists of all operators in each operator class (indexed
     * by operator class)
     */
    mapping(OperatorClasses => address[])
        private _authorizedOperatorList;

    /// @dev Mapping of active {Proposal} records (indexed by proposal ID)
    mapping(uint256 => Proposal) private _proposalMap;

    /// @dev Complete list of IDs of all active proposals ({Proposal} records)
    uint256[] private _proposalList;

    /**
     * @dev Mapping that indicates whether an operator has approved any given
     * proposal (indexed by proposal ID and the operator's Ethereum account
     * address)
     */        
    mapping(uint256 => mapping(address => bool)) private _hasApproved;

    /// @dev Current address of the Collypto contract
    address private _collyptoAddress;

    /// @dev Most recent proposal index
    uint256 private _currentProposalIndex;

    /**
     * @dev Event emitted when a {Proposal} record is created with an {id}
     * value of `proposalId` and {index} value of `proposalIndex` by an
     * operator using the Ethereum account at `creatorAddress`
     */ 
    event ProposalCreated(
        uint256 indexed proposalId,
        uint256 indexed proposalIndex,
        address indexed creatorAddress
    );

    /**
     * @dev Event emitted when a {Proposal} record is removed with an {id}
     * value of `proposalId` and {index} value of `proposalIndex`
     */ 
    event ProposalRemoved(
        uint256 indexed proposalId,
        uint256 indexed proposalIndex
    );

    /**
     * @dev Event emitted when a {Proposal} record is executed with an {id}
     * value of `proposalId` and {index} value of `proposalIndex`
     */ 
    event ProposalExecuted(
        uint256 indexed proposalId,
        uint256 indexed proposalIndex
    );

    /**
     * @dev Event emitted when all active proposals are purged from this
     * contract
     */
    event ProposalsPurged();

    /**
     * @dev Event emitted when an approval is added to the {Proposal} record
     * with an {id} value of `proposalId` by an operator using the Ethereum
     * account at `operatorAddress`
     */
    event ApprovalAdded(
        uint256 indexed proposalId,
        address indexed operatorAddress
    );

    /**
     * @dev Event emitted when an approval is revoked from the {Proposal}
     * record with an {id} value of `proposalId` by an operator using the
     * Ethereum account at `operatorAddress`
     */
    event ApprovalRevoked(
        uint256 indexed proposalId,
        address indexed operatorAddress
    );

    /**
     * @dev Event emitted when authorization for the Ethereum account at
     * `operatorAddress` is added to operator class `operatorClass`
     */
    event OperatorAdded(
        uint256 indexed operatorClass,
        address indexed operatorAddress
    );

    /**
     * @dev Event emitted when authorization for the Ethereum account at
     * `operatorAddress` is removed from operator class `operatorClass`
     */
    event OperatorRemoved(
        uint256 indexed operatorClass,
        address indexed operatorAddress
    );
    
    /**
     * @dev Event emitted when all authorizations are purged from operator
     * class `operatorClass`
     */
    event OperatorsPurged(uint256 indexed operatorClass);

    /**
     * @dev Event emitted when the reference address of the Collypto contract
     * is updated to `targetAddress`
     */
    event CollyptoAddressUpdated(address indexed targetAddress);

    /**
     * @dev Modifier that determines if an operator is authorized to perform
     * the transaction and reverts on "false"
     */
    modifier isAuthorized(OperatorClasses operatorClass) {    
        // Operator must belong to the specified class to continue
        require(_authorizedOperatorMap[operatorClass][msg.sender]);
        _;
    }

    /**
     * @notice Initializes this contract with a Collypto contract address value
     * of `collyptoAddress` and assigns the Ethereum address of the deployment
     * operator as the initial Prime address
     * @param collyptoAddress The reference address of the Collypto contract
     */
    constructor(address collyptoAddress) {
        address operator = msg.sender;
        _authorizedOperatorMap[OperatorClasses.Prime][operator] = true;
        
        // Default prime address is the deployment operator address
        _authorizedOperatorList[OperatorClasses.Prime].push(operator);

        _collyptoAddress = collyptoAddress;
        _currentProposalIndex = 0;
    }

    /**
     * @notice Returns the current address of the Collypto contract
     * @return collyptoAddress The current address of the Collypto contract
     */
    function getCollyptoAddress()
        public
        view
        returns (address collyptoAddress)
    {
        return _collyptoAddress;
    }    

    /**
     * @notice Returns all properties of the {Proposal} record with an {id}
     * value of `proposalId`
     * @param proposalId The {id} of the {Proposal} record to be returned
     * @return id The {id} value of the retrieved {Proposal} record
     * @return index The {index} value of the retrieved {Proposal} record
     * @return operation The {operation} value corresponding to the operation
     * to be executed in the retrieved {Proposal} record
     * @return addressList The {addressList} array corresponding to the list of
     * addresses in the retrieved {Proposal} record
     * @return data The {data} value representing the hashed data in the
     * retrieved {Proposal} record     
     * @return approvers The {approvers} array corresponding to the list of
     * approvers in the retrieved {Proposal} record
     */
    function getProposalRecord(uint256 proposalId)
        public
        view
        returns (
            uint256 id,
            uint256 index,
            Operations operation,
            address[] memory addressList,
            uint256 data,
            address[] memory approvers
        )
    {
        Proposal storage proposal = _proposalMap[proposalId];

        return (
            proposal.id,
            proposal.index,
            proposal.operation,
            proposal.addressList,
            proposal.data,            
            proposal.approvers
        );
    }

    /**
     * @notice Returns the list of proposal IDs of all active proposals
     * @return proposalIds The list of proposal IDs of all active proposals
     */
    function getActiveProposals()
        public
        view
        returns (uint256[] memory proposalIds)
    {
        return _proposalList;
    }

    /**
    * @notice Returns the total number of active {Proposal} records in
    * {_proposalList}
    * @return total The total number of active {Proposal} records in
    * {_proposalList}
    */
    function totalActiveProposals()
        public
        view
        returns (uint256 total)
    {
        return _proposalList.length;
    }
    
    /**
    * @notice Returns the index of the most recently created {Proposal} record
    * @return proposalIndex The index of the most recently created {Proposal}
    * record
    */
    function getCurrentProposalIndex()
        public
        view
        returns (uint256 proposalIndex)
    {
        return _currentProposalIndex;
    } 

    /**
     * @notice Returns the current list of operator addresses that are
     * authorized for operator class `operatorClass` operations
     * @param operatorClass The {OperatorClasses} value of operator requested
     * @return operators The list of operators that are authorized to conduct
     * operations of the provided {operatorClass}
     */
    function getCurrentOperators(OperatorClasses operatorClass)
        public
        view
        returns (address[] memory operators)
    {
        return _authorizedOperatorList[operatorClass];
    }

    /**
     * @notice Revokes the current operator's approval of the {Proposal} record
     * with an {id} value of `proposalId` and emits an {ApprovalRevoked} event
     * @dev This operation will revert upon execution if the operator or any
     * provided arguments violates any of the rules in the {_revokeApproval}
     * function.
     * @param proposalId The {id} value of the {Proposal} record where the
     * current operator's approval will be revoked
     * @return success A Boolean value indicating whether the operator's
     * approval has been revoked for the proposal with an {id} value of
     * {proposalId}
     */
    function revokeApproval(uint256 proposalId) public returns (bool success) {
        address operator = msg.sender;

        return _revokeApproval(proposalId, operator);
    }

    /**
     * @notice Submits, approves, or executes a proposal (depending on majority
     * requirements) to conduct a {updateUserStatus} operation in the Collypto
     * contract, updating the {UserStatus} record of the Ethereum account at
     * `targetAddress` to contain a {status} value of `status` and an {info}
     * value of `info` and emits a {ProposalCreated} event upon proposal
     * creation, {ApprovalAdded} events for each additional approval, and a
     * {ProposalExecuted} event upon execution
     * @dev This is a restricted utility function. This operation will revert
     * if any of the provided arguments violate any of the rules in the
     * {updateUserStatus} function of the Collypto contract.
     * @param targetAddress The address of the Ethereum account to be updated
     * @param status The {status} value to be assigned to the {UserStatus}
     * record of the target Ethereum account
     * @param info The {info} value to be assigned to the {UserStatus} record
     * of the target Ethereum account
     * @return proposalId The {id} value of the {Proposal} record generated or
     * approved by the current operator
     * @return executed A Boolean value indicating whether the proposal was
     * executed
     */    
    function updateUserStatus(
        address targetAddress,
        Collypto.Statuses status,
        string memory info
    )
        public
        isAuthorized(OperatorClasses.Arbiter)
        returns (uint256 proposalId, bool executed)
    {
        address operator = msg.sender;         
        address[] memory addressList = new address[](1);
        addressList[0] = targetAddress;

        bool hasMajority;
        Proposal memory updatedProposal;
        (updatedProposal, hasMajority) =
            _submitProposal(
                operator,
                Operations.SetUserStatus,
                addressList,
                uint256(keccak256(abi.encodePacked(status, info)))
            );

        if (hasMajority) {
            _removeProposal(updatedProposal.id, true);
            return (
                updatedProposal.id,
                Collypto(_collyptoAddress).updateUserStatus(
                    targetAddress,
                    status,
                    info
                )
            );
        } else {
            return (updatedProposal.id, false);
        }
    }

    /**
     * @notice Submits, approves, or executes a proposal (depending on majority
     * requirements) to conduct a {forceTransfer} operation in the Collypto
     * contract, moving `amount` slivers from the Ethereum account at `from` to
     * the Ethereum account at `to` (regardless of user or account status) and
     * emits a {ProposalCreated} event upon proposal creation, {ApprovalAdded}
     * events for each additional approval, and a {ProposalExecuted} event upon
     * execution
     * @dev This is a restricted utility function. This operation will revert
     * if any of the provided arguments violates any of the rules in the
     * {forceTransfer} function of the Collypto contract.
     * @param from The address of the sender's Ethereum account
     * @param to The address of the recipient's Ethereum account
     * @param amount The amount of credits (in slivers) to be transferred
     * @return proposalId The {id} value of the {Proposal} record generated or
     * approved by the current operator
     * @return executed A Boolean value indicating whether the proposal was
     * executed
     */
    function forceTransfer(address from, address to, uint256 amount)
        public
        isAuthorized(OperatorClasses.Dispatch)
        returns (uint256 proposalId, bool executed)
    {       
        address operator = msg.sender;          
        address[] memory addressList = new address[](2);
        addressList[0] = from;
        addressList[1] = to;

        bool hasMajority;
        Proposal memory updatedProposal;
        (updatedProposal, hasMajority) =
            _submitProposal(
                operator,
                Operations.ForceTransfer,
                addressList,
                amount
            );

        if (hasMajority) {
            _removeProposal(updatedProposal.id, true);
            return (
                updatedProposal.id,
                Collypto(_collyptoAddress).forceTransfer(from, to, amount)
            );
        } else {
            return (updatedProposal.id, false);
        }  
    }

    /**
     * @notice Submits, approves, or executes a proposal (depending on majority
     * requirements) to conduct a {freeze} operation in the Collypto contract,
     * freezing `amount` slivers in the Ethereum account at `targetAddress` and
     * emits a {ProposalCreated} event upon proposal creation, {ApprovalAdded}
     * events for each additional approval, and a {ProposalExecuted} event upon
     * execution
     * @dev This is a restricted utility function.
     * @param targetAddress The address of the Ethereum account where credits
     * will be frozen
     * @param amount The total number of credits (in slivers) to be frozen
     * @return proposalId The {id} value of the {Proposal} record generated or
     * approved by the current operator
     * @return executed A Boolean value indicating whether the proposal was
     * executed
     */
    function freeze(address targetAddress, uint256 amount)
        public
        isAuthorized(OperatorClasses.Freeze)
        returns (uint256 proposalId, bool executed)
    {
        address operator = msg.sender;      
        address[] memory addressList = new address[](1);
        addressList[0] = targetAddress;

        bool hasMajority;
        Proposal memory updatedProposal;
        (updatedProposal, hasMajority) =
            _submitProposal(operator, Operations.Freeze, addressList, amount);

        if (hasMajority) {
            _removeProposal(updatedProposal.id, true);
            return (
                updatedProposal.id,
                Collypto(_collyptoAddress).freeze(targetAddress, amount)
            );
        } else {
            return (updatedProposal.id, false);
        }  
    }

    /**
     * @notice Submits, approves, or executes a proposal (depending on majority
     * requirements) to conduct an {unfreeze} operation in the Collypto
     * contract, unfreezing `amount` slivers in the Ethereum account at
     * `targetAddress` and emits a {ProposalCreated} event upon proposal
     * creation, {ApprovalAdded} events for each additional approval, and a
     * {ProposalExecuted} event upon execution
     * @dev This is a restricted utility function.
     * @param targetAddress The address of the Ethereum account where credits
     * will be unfrozen
     * @param amount The total number of credits (in slivers) to be unfrozen
     * @return proposalId The {id} value of the {Proposal} record generated or
     * approved by the current operator
     * @return executed A Boolean value indicating whether the proposal was
     * executed
     */
    function unfreeze(address targetAddress, uint256 amount)
        public
        isAuthorized(OperatorClasses.Unfreeze)
        returns (uint256 proposalId, bool executed)
    {
        address operator = msg.sender;
        address[] memory addressList = new address[](1);
        addressList[0] = targetAddress;

        bool hasMajority;
        Proposal memory updatedProposal;
        (updatedProposal, hasMajority) =
            _submitProposal(
                operator,
                Operations.Unfreeze,
                addressList,
                amount
            );

        if (hasMajority) {
            _removeProposal(updatedProposal.id, true);
            return (
                updatedProposal.id,
                Collypto(_collyptoAddress).unfreeze(targetAddress, amount)
            );
        } else {
            return (updatedProposal.id, false);
        }  
    }

    /**
     * @notice Submits, approves, or executes a proposal (depending on majority
     * requirements) to conduct a {lock} operation in the Collypto contract, 
     * locking the Ethereum account at `targetAddress` and emits a
     * {ProposalCreated} event upon proposal creation, {ApprovalAdded} events
     * for each additional approval, and a {ProposalExecuted} event upon
     * execution
     * @dev This is a restricted utility function. This operation will revert
     * if it violates any of the rules in the {lock} function of the Collypto
     * contract.
     * @param targetAddress The address of the Ethereum account to be locked
     * @return proposalId The {id} value of the {Proposal} record generated or
     * approved by the current operator
     * @return executed A Boolean value indicating whether the proposal was
     * executed
     */        
    function lock(address targetAddress)
        public
        isAuthorized(OperatorClasses.Lock)
        returns (uint256 proposalId, bool executed)
    {       
        address operator = msg.sender;     
        address[] memory addressList = new address[](1);
        addressList[0] = targetAddress;

        bool hasMajority;
        Proposal memory updatedProposal;
        (updatedProposal, hasMajority) =
            _submitProposal(
                operator,
                Operations.Lock,
                addressList,
                0
            );

        if (hasMajority) {
            _removeProposal(updatedProposal.id, true);
            return (
                updatedProposal.id,
                Collypto(_collyptoAddress).lock(targetAddress)
            );
        } else {
            return (updatedProposal.id, false);
        }  
    }

    /**
     * @notice Submits, approves, or executes a proposal (depending on majority
     * requirements) to conduct an {unlock} operation in the Collypto contract, 
     * unlocking the Ethereum account at `targetAddress` and emits a
     * {ProposalCreated} event upon proposal creation, {ApprovalAdded} events
     * for each additional approval, and a {ProposalExecuted} event upon
     * execution
     * @dev This is a restricted utility function. This operation will revert
     * if it violates any of the rules in the {unlock} function of the Collypto
     * contract.
     * @param targetAddress The address of the Ethereum account to be unlocked
     * @return proposalId The {id} value of the {Proposal} record generated or
     * approved by the current operator
     * @return executed A Boolean value indicating whether the proposal was
     * executed
     */   
    function unlock(address targetAddress)
        public
        isAuthorized(OperatorClasses.Unlock)
        returns (uint256 proposalId, bool executed)
    {        
        address operator = msg.sender;
        address[] memory addressList = new address[](1);
        addressList[0] = targetAddress;

        bool hasMajority;
        Proposal memory updatedProposal;
        (updatedProposal, hasMajority) =
            _submitProposal(operator, Operations.Unlock, addressList, 0);

        if (hasMajority) {
            _removeProposal(updatedProposal.id, true);
            return (
                updatedProposal.id,
                Collypto(_collyptoAddress).unlock(targetAddress)
            );
        } else {
            return (updatedProposal.id, false);
        }  
    }

    /**
     * @notice Submits, approves, or executes a proposal (depending on majority
     * requirements) to conduct a {mint} operation in the Collypto contract, 
     * minting `amount` slivers in the Ethereum account at `targetAddress` and
     * emits a {ProposalCreated} event upon proposal creation, {ApprovalAdded}
     * events for each additional approval, and a {ProposalExecuted} event upon
     * execution
     * @dev This is a restricted utility function. This operation will revert
     * if any of the provided arguments violates any of the rules in the {mint}
     * function of the Collypto contract.
     * @param targetAddress The address of the Ethereum account where credits
     * will be minted
     * @param amount The total number of credits (in slivers) to be minted
     * @return proposalId The {id} value of the {Proposal} record generated or
     * approved by the current operator
     * @return executed A Boolean value indicating whether the proposal was
     * executed
     */       
    function mint(address targetAddress, uint256 amount)
        public
        isAuthorized(OperatorClasses.Mint)
        returns (uint256 proposalId, bool executed)
    {       
        address operator = msg.sender;               
        address[] memory addressList = new address[](1);
        addressList[0] = targetAddress;

        bool hasMajority;
        Proposal memory updatedProposal;
        (updatedProposal, hasMajority) =
            _submitProposal(operator, Operations.Mint, addressList, amount);

        if (hasMajority) {
            _removeProposal(updatedProposal.id, true);
            return (
                updatedProposal.id,
                Collypto(_collyptoAddress).mint(targetAddress, amount)
            );
        } else {
            return (updatedProposal.id, false);
        }  
    }     

    /**
     * @notice Submits, approves, or executes a proposal (depending on majority
     * requirements) to conduct a {burn} operation in the Collypto contract, 
     * burning `amount` slivers in the Ethereum account at `targetAddress` and
     * emits a {ProposalCreated} event upon proposal creation, {ApprovalAdded}
     * events for each additional approval, and a {ProposalExecuted} event upon
     * execution
     * @dev This is a restricted utility function. This operation will revert
     * if any of the provided arguments violates any of the rules in the {burn}
     * function of the Collypto contract.
     * @param targetAddress The address of the Ethereum account where credits
     * will be burned
     * @param amount The total number of credits (in slivers) to be burned
     * @return proposalId The {id} value of the {Proposal} record generated or
     * approved by the current operator
     * @return executed A Boolean value indicating whether the proposal was
     * executed
     */ 
    function burn(address targetAddress, uint256 amount)
        public
        isAuthorized(OperatorClasses.Burn)
        returns (uint256 proposalId, bool executed)
    {
        address operator = msg.sender;        
        address[] memory addressList = new address[](1);
        addressList[0] = targetAddress;

        bool hasMajority;
        Proposal memory updatedProposal;
        (updatedProposal, hasMajority) =
            _submitProposal(operator, Operations.Burn, addressList, amount);

        if (hasMajority) {
            _removeProposal(updatedProposal.id, true);
            return (
                updatedProposal.id,
                Collypto(_collyptoAddress).burn(targetAddress, amount)
            );
        } else {
            return (updatedProposal.id, false);
        }  
    }

    /**
     * @notice Submits, approves, or executes a proposal (depending on majority
     * requirements) to conduct a {pause} operation in the Collypto contract,
     * blocking all standard (non-view) user operations and emits a
     * {ProposalCreated} event upon proposal creation, {ApprovalAdded} events
     * for each additional approval, and a {ProposalExecuted} event upon
     * execution
     * @dev This is a restricted management function. This operation will
     * revert upon execution if its timing would violate any of the rules in
     * the {pause} function of the Collypto contract.
     * @return proposalId The {id} value of the {Proposal} record generated or
     * approved by the current operator
     * @return executed A Boolean value indicating whether the proposal was
     * executed
     */   
    function pause()
        public
        isAuthorized(OperatorClasses.Prime)
        returns (uint256 proposalId, bool executed)
    {
        address operator = msg.sender;       
        address[] memory addressList = new address[](1);
        addressList[0] = address(this);

        bool hasMajority;
        Proposal memory updatedProposal;
        (updatedProposal, hasMajority) =
            _submitProposal(operator, Operations.Pause, addressList, 0);

        if (hasMajority) {
            _removeProposal(updatedProposal.id, true);
            return (updatedProposal.id, Collypto(_collyptoAddress).pause());
        } else {
            return (updatedProposal.id, false);
        }        
    }

    /**
     * @notice Submits, approves, or executes a proposal (depending on majority
     * requirements) to conduct an {unpause} operation in the Collypto
     * contract, unblocking all standard (non-view) user operations and emits a
     * {ProposalCreated} event upon proposal creation, {ApprovalAdded} events
     * for each additional approval, and a {ProposalExecuted} event upon
     * execution
     * @dev This is a restricted management function. This operation will
     * revert upon execution if its timing would violate any of the rules in
     * the {unpause} function of the Collypto contract.
     * @return proposalId The {id} value of the {Proposal} record generated or
     * approved by the current operator
     * @return executed A Boolean value indicating whether the proposal was
     * executed
     */      
    function unpause()
        public
        isAuthorized(OperatorClasses.Prime)
        returns (uint256 proposalId, bool executed)
    {
        address operator = msg.sender;       
        address[] memory addressList = new address[](1);
        addressList[0] = address(this);

        bool hasMajority;
        Proposal memory updatedProposal;
        (updatedProposal, hasMajority) =
            _submitProposal(operator, Operations.Unpause, addressList, 0);

        if (hasMajority) {
            _removeProposal(updatedProposal.id, true);
            return (updatedProposal.id, Collypto(_collyptoAddress).unpause());
        } else {
            return (updatedProposal.id, false);
        } 
    }

    /**
     * @notice Submits, approves, or executes a proposal (depending on majority
     * requirements) to add the manager account at address `managerAddress` to
     * the manager list of the Collypto contract and emits a {ProposalCreated}
     * event upon proposal creation, {ApprovalAdded} events for each additional
     * approval, and a {ProposalExecuted} event upon execution
     * @dev This is a restricted management function. This operation will
     * revert if {managerAddress} is the zero address or violates any of the
     * rules in the {addManager} function of the Collypto contract.
     * @param managerAddress The address of the Ethereum account to be added to
     * the manager list of the Collypto contract
     * @return proposalId The {id} value of the {Proposal} record generated or
     * approved by the current operator
     * @return executed A Boolean value indicating whether the proposal was
     * executed
     */     
    function addManager(
        address managerAddress
    )
        public
        isAuthorized(OperatorClasses.Prime)
        returns (uint256 proposalId, bool executed)
    {        
        // Cannot add the zero address to the manager list
        require(managerAddress != address(0));

        address operator = msg.sender;
        address[] memory addressList = new address[](1);
        addressList[0] = managerAddress;

        bool hasMajority;
        Proposal memory updatedProposal;
        (updatedProposal, hasMajority) =
            _submitProposal(
                operator,
                Operations.AddManager,
                addressList,
                0
            );

        if (hasMajority) {
            _removeProposal(updatedProposal.id, true);
            return (
                updatedProposal.id,
                Collypto(_collyptoAddress).addManager(managerAddress)
            );
        } else {
            return (updatedProposal.id, false);
        }  
    }

    /**
     * @notice Submits, approves, or executes a proposal (depending on majority
     * requirements) to remove the manager account at address `managerAddress`
     * from the manager list of the Collypto contract and emits a
     * {ProposalCreated} event upon proposal creation, {ApprovalAdded} events
     * for each additional approval, and a {ProposalExecuted} event upon
     * execution
     * @dev This is a restricted management function. This operation will
     * revert if {managerAddress} is the zero address or violates any of the
     * rules in the {removeManager} function of the Collypto contract.
     * @param managerAddress The address of the Ethereum account to be removed
     * from the manager list of the Collypto contract
     * @return proposalId The {id} value of the {Proposal} record generated or
     * approved by the current operator
     * @return executed A Boolean value indicating whether the proposal was
     * executed
     */     
    function removeManager(
        address managerAddress
    )
        public
        isAuthorized(OperatorClasses.Prime)
        returns (uint256 proposalId, bool executed)
    {        
        // Cannot remove the zero address from the manager list
        require(managerAddress != address(0));

        address operator = msg.sender;
        address[] memory addressList = new address[](1);
        addressList[0] = managerAddress;

        bool hasMajority;
        Proposal memory updatedProposal;
        (updatedProposal, hasMajority) =
            _submitProposal(
                operator,
                Operations.RemoveManager,
                addressList,
                0
            );

        if (hasMajority) {
            _removeProposal(updatedProposal.id, true);
            return (
                updatedProposal.id,
                Collypto(_collyptoAddress).removeManager(managerAddress)
            );
        } else {
            return (updatedProposal.id, false);
        }
    }

    /**
     * @notice Submits, approves, or executes a proposal (depending on majority
     * requirements) to update the reference address of the Collypto contract
     * to `targetAddress` and emits a {ProposalCreated} event upon proposal
     * creation, {ApprovalAdded} events for each additional approval, and a
     * {ProposalExecuted} and a {CollyptoAddressUpdated} event upon execution
     * @dev This is a restricted management function.
     * @param targetAddress The updated reference address of the Collypto
     * contract
     * @return proposalId The {id} value of the {Proposal} record generated or
     * approved by the current operator
     * @return executed A Boolean value indicating whether the proposal was
     * executed
     */ 
    function updateCollyptoAddress(address targetAddress)
        public
        isAuthorized(OperatorClasses.Prime)
        returns (uint256 proposalId, bool executed)
    {
        address operator = msg.sender;  
        address[] memory addressList = new address[](1);
        addressList[0] = targetAddress;

        bool hasMajority;
        Proposal memory updatedProposal;
        (updatedProposal, hasMajority) =
            _submitProposal(
                operator,
                Operations.UpdateCollyptoAddress,
                addressList,
                0
            );

        if (hasMajority) {
            _removeProposal(updatedProposal.id, true);
            return (updatedProposal.id, _updateCollyptoAddress(targetAddress));
        } else {
            return (updatedProposal.id, false);
        } 
    }    

    /**
     * @notice Submits, approves, or executes a proposal (depending on majority
     * requirements) to remove the active {Proposal} record with an {id} value
     * of `proposalId` and emits a {ProposalCreated} event upon proposal
     * creation, {ApprovalAdded} events for each additional approval, and a
     * {ProposalExecuted} and a {ProposalRemoved} event upon execution
     * @dev This is a restricted management function. This function
     * automatically removes the removal {Proposal} record itself from the
     * active proposals list and mapping once its underlying removal operation
     * is executed. This operation will revert upon execution if any of the
     * provided arguments violates any of the rules in the {_removeOperator}
     * function.
     * @param proposalId The {id} value of the {Proposal} record to be removed
     * @return proposalId The {id} value of the {Proposal} record generated or
     * approved by the current operator
     * @return executed A Boolean value indicating whether the proposal was
     * executed
     */ 
    function removeProposal(uint256 id)
        public
        isAuthorized(OperatorClasses.Prime)
        returns (uint256 proposalId, bool executed)
    {       
        address operator = msg.sender;
        address[] memory addressList = new address[](1);
        addressList[0] = address(this);

        bool hasMajority;
        Proposal memory updatedProposal;
        (updatedProposal, hasMajority) =
            _submitProposal(
                operator,
                Operations.RemoveProposal,
                addressList,
                id
            );

        if (hasMajority) {
            _removeProposal(updatedProposal.id, true);
            return (updatedProposal.id, _removeProposal(id, false));
        } else {
            return (updatedProposal.id, false);
        } 
    }

    /**
     * @notice Submits, approves, or executes a proposal (depending on majority
     * requirements) to purge all active {Proposal} records and emits a
     * {ProposalCreated} event upon proposal creation, {ApprovalAdded} events
     * for each additional approval, and a {ProposalExecuted} and a
     * {ProposalsPurged} event upon execution
     * @dev This is a restricted management function.
     * @return proposalId The {id} value of the {Proposal} record generated or
     * approved by the current operator
     * @return executed A Boolean value indicating whether the proposal was
     * executed
     */ 
    function purgeProposals()
        public
        isAuthorized(OperatorClasses.Prime)
        returns (uint256 proposalId, bool executed)
    {       
        address operator = msg.sender;
        address[] memory addressList = new address[](1);
        addressList[0] = address(this);

        bool hasMajority;
        Proposal memory updatedProposal;
        (updatedProposal, hasMajority) =
            _submitProposal(
                operator,
                Operations.PurgeProposals,
                addressList,
                0
            );

        if (hasMajority) {
            emit ProposalExecuted(updatedProposal.id, updatedProposal.index);
            return (updatedProposal.id, _purgeProposals());
        } else {
            return (updatedProposal.id, false);
        } 
    }
    
    /**
     * @notice Submits, approves, or executes a proposal (depending on majority
     * requirements) to authorize the operator at address `operatorAddress` to
     * conduct `operatorClass` operations and emits a {ProposalCreated} event
     * upon proposal creation, {ApprovalAdded} events for each additional
     * approval, and a {ProposalExecuted} and an {OperatorAdded} event upon
     * execution
     * @dev This is a restricted management function. This operation will
     * revert upon execution if `operatorClass` does not correspond to a valid
     * {OperatorClasses} value, `operatorAddress` is the zero address, or if
     * any of the provided arguments violates any rules in the {_addOperator}
     * function.
     * @param operatorClass The operator class authorization to be assigned to
     * the operator at {operatorAddress}
     * @param operatorAddress The address of the Ethereum account to be
     * authorized to conduct operations of class {operatorClass}
     * @return proposalId The {id} value of the {Proposal} record generated or
     * approved by the current operator
     * @return executed A Boolean value indicating whether the proposal was
     * executed
     */     
    function addOperator(
        OperatorClasses operatorClass,
        address operatorAddress
    )
        public
        isAuthorized(OperatorClasses.Prime)
        returns (uint256 proposalId, bool executed)
    {
        // Specified operator class must be a valid operator class 
        require(_isValidOperatorClass(operatorClass));
        
        // New operator address cannot be the zero address
        require(operatorAddress != address(0));

        address operator = msg.sender;
        address[] memory addressList = new address[](1);
        addressList[0] = operatorAddress;

        bool hasMajority;
        Proposal memory updatedProposal;
        (updatedProposal, hasMajority) =
            _submitProposal(
                operator,
                Operations.AddOperator,
                addressList,
                uint256(operatorClass)
            );

        if (hasMajority) {
            _removeProposal(updatedProposal.id, true);
            return (
                updatedProposal.id,
                _addOperator(operatorClass, operatorAddress)
            );
        } else {
            return (updatedProposal.id, false);
        }  
    }
       
    /**
     * @notice Submits, approves, or executes a proposal (depending on majority
     * requirements) to remove authorization for the operator at
     * `operatorAddress` to conduct `operatorClass` operations and emits a
     * {ProposalCreated} event upon proposal creation, {ApprovalAdded} events
     * for each additional approval, and a {ProposalExecuted} event, a variable
     * number of {ProposalRemoved} and {ApprovalRevoked} events (depending on
     * the number of active proposals approved by the operator at
     * `operatorAddress`), and an {OperatorRemoved} event upon execution
     * @dev This is a restricted management function. This operation will
     * revert upon execution if `operatorClass` does not correspond to a valid
     * {OperatorClasses} value, `operatorAddress` is the zero address, or if
     * any of the provided arguments violates any of the rules in the
     * {_removeOperator} function.
     * @param operatorClass The operator class authorization to be removed from
     * the operator at {operatorAddress}
     * @param operatorAddress The address of the Ethereum account to remove
     * authorization to conduct operations of class {operatorClass}
     * @return proposalId The {id} value of the {Proposal} record generated or
     * approved by the current operator
     * @return executed A Boolean value indicating whether the proposal was
     * executed
     */        
    function removeOperator(
        OperatorClasses operatorClass,
        address operatorAddress
    )
        public
        isAuthorized(OperatorClasses.Prime)
        returns (uint256 proposalId, bool executed)
    {
        // Specified operator class must be a valid operator class
        require(_isValidOperatorClass(operatorClass));
        
        // Operator address cannot be the zero address
        require(operatorAddress != address(0));

        address operator = msg.sender;         
        address[] memory addressList = new address[](1);
        addressList[0] = operatorAddress;

        bool hasMajority;
        Proposal memory updatedProposal;
        (updatedProposal, hasMajority) =
            _submitProposal(
                operator,
                Operations.RemoveOperator,
                addressList,
                uint256(operatorClass)
            );

        if (hasMajority) {
            _removeProposal(updatedProposal.id, true);        
            return (
                updatedProposal.id,
                _removeOperator(operatorClass, operatorAddress)
            );
        } else {
            return (updatedProposal.id, false);
        }  
    }
    
    /**
     * @notice Submits, approves, or executes a proposal (depending on majority
     * requirements) to purge authorization for all currently authorized
     * operators to conduct `operatorClass` operations and emits a
     * {ProposalCreated} event upon proposal creation, {ApprovalAdded} events
     * for each additional approval, and a {ProposalExecuted} event, a variable
     * number of {ProposalRemoved} events (depending on the number of active
     * proposals corresponding to `operatorClass`) and an {OperatorsPurged}
     * event upon execution
     * @dev This is a restricted management function. This operation will
     * revert upon execution if `operatorClass` does not correspond to a valid
     * {OperatorClasses} value or `operatorClass` is "Prime".
     * @param operatorClass The operator class authorization to be purged
     * @return proposalId The {id} value of the {Proposal} record generated or
     * approved by the current operator
     * @return executed A Boolean value indicating whether the proposal was
     * executed
     */           
    function purgeOperators(OperatorClasses operatorClass)
        public
        isAuthorized(OperatorClasses.Prime)
        returns (uint256 proposalId, bool executed)
    {
        // Cannot purge operators from an invalid operator class
        require(_isValidOperatorClass(operatorClass));
        
        // Cannot purge Prime operators
        require(operatorClass != OperatorClasses.Prime);

        address operator = msg.sender;
        address[] memory addressList = new address[](1);
        addressList[0] = address(this);

        bool hasMajority;
        Proposal memory updatedProposal;
        (updatedProposal, hasMajority) =
            _submitProposal(
                operator,
                Operations.PurgeOperators,
                addressList,
                uint256(operatorClass)
            );

        if (hasMajority) {
            _removeProposal(updatedProposal.id, true);
            return (updatedProposal.id, _purgeOperators(operatorClass));
        } else {
            return (updatedProposal.id, false);
        }  
    }

    /**
     * @dev This function revokes approval of the operator at `operator` for
     * the proposal with an {id} value of `proposalId` and emits an
     * {ApprovalRevoked} event. This operation will revert if there is no
     * active proposal with an {id} value of `proposalId` or the current
     * operator has not authorized the target proposal.
     * @param proposalId The {id} value of the {Proposal} record where approval
     * will be revoked for {operator}
     * @param operator The address of the Etheruem account of the operator
     * whose approval will be revoked
     * @return success A Boolean value indicating whether the approval was
     * revoked successfully
     */
    function _revokeApproval(uint256 proposalId, address operator)
        internal
        returns (bool success)
    {
        // Proposal must exist with the {id} value specified
        require(_proposalExists(proposalId));
        
        Proposal storage targetProposal = _proposalMap[proposalId];
       
        // Operator must have already approved the specified proposal
        require(_hasApproved[proposalId][operator]);

        _hasApproved[proposalId][operator] = false;

        uint256 totalApprovers = targetProposal.approvers.length;

        for (uint256 i = 0; i < totalApprovers; i++) {
            if (targetProposal.approvers[i] == operator) {                                    
                uint256 lastApproverIndex = totalApprovers - 1;

                if ((totalApprovers > 1) && (i != lastApproverIndex)) {
                    targetProposal.approvers[i] =
                        targetProposal.approvers[lastApproverIndex];
                }
                
                targetProposal.approvers.pop();
                
                emit ApprovalRevoked(proposalId, operator); 

                return true;
            }              
        }

        return false;
    }

    /**
    * @dev This function updates the reference address of the Collypto contract
    * in {_collyptoAddress} to `contractAddress` and emits a
    * {CollyptoAddressUpdated} event.
    * @param contractAddress The updated reference address of the Collypto
    * contract
    * @return success A Boolean value indicating that the reference address of
    * the Collypto contract has been updated successfully 
    */
    function _updateCollyptoAddress(address contractAddress)
        internal
        returns (bool success)
    {
        _collyptoAddress = contractAddress;

        emit CollyptoAddressUpdated(contractAddress);

        return true;
    }

    /**
     * @dev This function returns a Boolean value indicating whether an active
     * {Proposal} record exists with an {id} value of `proposalId`.
     * @param proposalId The {id} value of the target {Proposal} record
     * @return exists A Boolean value indicating whether there is an active
     * {Proposal} record with the {id} value of {proposalId}
     */
    function _proposalExists(uint256 proposalId)
        internal
        view
        returns (bool exists)
    {
        return _proposalMap[proposalId].id > 0;
    }

    /**
     * @dev This function evaluates and returns an integer representing the
     * a unique proposal {id} created using a deterministic hash of the input
     * values.
     * @param operation The {Operations} value of the proposal operation
     * @param addresses The ordered list of addresses acted upon in the
     * proposal
     * @param data An integer value representing the deterministic hash of
     * ordered proposal data
     * @return id An integer value representing the {id} value of a unique
     * {Proposal} record
     */
    function _getProposalId(
        Operations operation,
        address[] memory addresses,
        uint256 data
    )
        internal
        pure
        returns (uint256 id)
    {
        return uint256(
            keccak256(abi.encodePacked(operation, addresses, data))
        );
    }

    /**
     * @dev This function composes a proposal for the `operation` using the
     * input arguments provided, creates a unique {Proposal} record
     * encapsulating that data, emits a {ProposalCreated} event. This operation
     * will revert if there is already an active {Proposal} record with an {id}
     * value that would be identical to the {id} value of the proposal to be
     * created.
     * @param creatorAddress The address of the Ethereum account used to create
     * the proposal
     * @param operation The {Operations} value of the proposal operation
     * @param addresses The ordered list of addresses acted upon in the
     * proposal
     * @param data An integer value representing the deterministic hash of
     * ordered proposal data
     * @return id An integer value representing the {id} value of the unique
     * {Proposal} record created by this operation
     */
    function _createProposal(
        address creatorAddress,
        Operations operation,
        address[] memory addresses,
        uint256 data
    )
        internal
        returns (uint256 id)
    {
        uint256 proposalId = _getProposalId(operation, addresses, data);

        // Cannot create redundant proposals
        require(!_proposalExists(proposalId));

        address[] memory approvers = new address[](1);
        approvers[0] = creatorAddress;

        _hasApproved[proposalId][creatorAddress] = true;

        // Create proposal object and add to proposal mapping table
        _proposalMap[proposalId] = Proposal({
            id : proposalId,
            index: ++_currentProposalIndex,
            operation: operation,
            addressList: addresses,
            data: data,
            approvers: approvers
        });

        // Add proposal {id} to proposal array
        _proposalList.push(proposalId);

        emit ProposalCreated(
            proposalId,
            _currentProposalIndex,
            creatorAddress
        );

        return proposalId;
    }    
    
    /**
     * @dev This function submits a proposal with the input arguments provided,
     * and emits either an {ApprovalAdded} or a {ProposalCreated} event
     * (depending on whether the resulting {Proposal} record already existed).
     * This operation will revert if the operator at `operatorAddress` has
     * already approved the proposal being submitted or if any input arguments
     * violate rules in the {_createProposal} function.
     * @param operatorAddress The Ethereum address of the operator submitting
     * the current proposal
     * @param operation The {Operations} value of the operation to be executed
     * by the current proposal
     * @param targetAddresses The ordered list of addresses acted upon in the
     * proposal
     * @param data An integer value representing the deterministic hash of
     * ordered proposal data
     * @return proposal The {Proposal} record generated or approved by the
     * current operator
     * @return hasMajority A Boolean value indicating whether the current
     * proposal has a majority of approvers
     */
    function _submitProposal(
        address operatorAddress,
        Operations operation,
        address[] memory targetAddresses,
        uint256 data
    )
        internal
        returns (Proposal memory proposal, bool hasMajority)
    {
        uint256 proposalId = _getProposalId(operation, targetAddresses, data);

        if (!_proposalExists(proposalId)) {
            // Create proposal and add operator address to the approvals list
            _createProposal(operatorAddress, operation, targetAddresses, data);
        } else { // Add operator address to approvals if it isn't on the list           
            Proposal storage storedProposal = _proposalMap[proposalId];
            
            // Current operator cannot approve the same proposal twice
            require(!_hasApproved[proposalId][operatorAddress]);
        
            // Approve proposal for current operator
            _hasApproved[proposalId][operatorAddress] = true;

            // Add operator to list of approvers
            storedProposal.approvers.push(operatorAddress);

            emit ApprovalAdded(proposalId, operatorAddress);
        }

        uint256 requiredMajority =
            (_authorizedOperatorList
                [_getRequiredOperatorClass(operation)].length / 2) + 1;
        uint256 currentApprovers = _proposalMap[proposalId].approvers.length;
        Proposal memory currentProposal = _proposalMap[proposalId];

        return (currentProposal, (currentApprovers >= requiredMajority));
    }

    /**
     * @dev This function removes the {Proposal} record with an {id} value of
     * `proposalId` and emits either a {ProposalExecuted} or {ProposalRemoved}
     * event, depending on the value of {executed}. This operation will revert
     * if there is no active proposal with an {id} value of {proposalId}.
     * @param proposalId The {id} value of the {Proposal} record to be removed
     * @param executed A Boolean value indicating whether the proposal
     * operation was executed
     * @return success A Boolean value indicating whether the proposal was
     * successfully removed from the proposal list and mapping
     */
    function _removeProposal(uint256 proposalId, bool executed)
        internal
        returns (bool success)
    {
        // Proposal must exist with the {id} value specified
        require(_proposalExists(proposalId));

        for (uint256 i = 0; i < _proposalList.length; i++) {
            if (_proposalList[i] == proposalId) {
                // Save location of last proposal in proposal list
                uint256 lastProposalIndex = _proposalList.length - 1;

                // Reset approver mappings for the proposal
                for (
                    uint256 j = 0;
                    j < _proposalMap[proposalId].approvers.length;
                    j++
                ) {                  
                    _hasApproved
                        [proposalId]
                        [_proposalMap[proposalId].approvers[j]] = false;
                }

                // Save proposal index before removal
                uint256 proposalIndex = _proposalMap[proposalId].index;
                
                // Remove proposal from the proposal mapping
                delete _proposalMap[proposalId];

                // Overwrite the proposal with the last proposal in the
                // proposal list
                if ((_proposalList.length > 1) && (i != lastProposalIndex)) {
                    _proposalList[i] = _proposalList[lastProposalIndex];
                }
                
                // Remove the redundant last proposal from the proposal list
                _proposalList.pop();

                if (executed) {
                    emit ProposalExecuted(proposalId, proposalIndex);
                } else {
                    emit ProposalRemoved(proposalId, proposalIndex);
                }

                return true;
            }
        }

        return false;
    }

    /**
     * @dev This function purges all active {Proposal} records and emits a
     * {ProposalsPurged} event.
     * @return success A Boolean value indicating that all proposals have been
     * purged successfully from {_proposalList} and {_proposalMap}
     */ 
    function _purgeProposals() internal returns (bool success) {
        for (uint256 i = 0; i < _proposalList.length; i++) {
            uint256 proposalId = _proposalList[i];

            for (
                uint256 j = 0;
                j < _proposalMap[proposalId].approvers.length;
                j++
            ) {
                _hasApproved
                    [proposalId]
                    [_proposalMap[proposalId].approvers[j]] = false;
            }

            delete _proposalMap[proposalId];                
        }

        delete _proposalList;

        emit ProposalsPurged();

        return true;
    }

    /**
     * @dev This function authorizes the operator at address `operatorAddress`
     * to conduct `operatorClass` operations and emits an {OperatorAdded}
     * event. This operation will revert if `operatorAddress` is already listed
     * as an authorized `operatorClass` operator.
     * @param operatorClass The operator class authorization to be assigned to
     * the operator at {operatorAddress}
     * @param operatorAddress The address of the Ethereum account of the
     * operator to be authorized to conduct operations of class {operatorClass}
     * @return success A Boolean value indicating that the operator at
     * {operatorAddress} was successfully authorized to conduct {operatorClass}
     * operations
     */   
    function _addOperator(
        OperatorClasses operatorClass,
        address operatorAddress
    )
        internal
        returns (bool success)
    {
        address[] storage currentOperatorAddresses =
            _authorizedOperatorList[operatorClass];
        
        // Operator address cannot already be authorized for {operatorClass}
        require(!_authorizedOperatorMap[operatorClass][operatorAddress]);

        _authorizedOperatorMap[operatorClass][operatorAddress] = true;
        
        currentOperatorAddresses.push(operatorAddress);

        emit OperatorAdded(uint256(operatorClass), operatorAddress);

        return true;
    }

    /**
     * @dev This function removes authorization for the operator at address
     * `operatorAddress` to conduct `operatorClass` operations and emits a
     * variable number of {ProposalRemoved} and {ApprovalRevoked} events
     * (depending on the number of active proposals approved by the operator at
     * `operatorAddress`) and an {OperatorRemoved} event. This operation will
     * revert if the operator at `operatorAddress` is not currently authorized
     * to conduct operations of class `operatorClass`.
     * @param operatorClass The operator class authorization to be removed from
     * the operator at {operatorAddress}
     * @param operatorAddress The address of the Ethereum account to remove
     * authorization to conduct operations of class {operatorClass}
     * @return success A Boolean value indicating that {operatorClass}
     * authorization was successfully removed from the operator at
     * {operatorAddress}
     */
    function _removeOperator(
        OperatorClasses operatorClass,
        address operatorAddress
    )
        internal
        returns (bool success)
    {     
        // Operator must be on the authorization list for the class specified
        require(_authorizedOperatorMap[operatorClass][operatorAddress]);

        address[] storage operatorAddresses =
            _authorizedOperatorList[operatorClass];
        
        for (uint256 i = 0; i < operatorAddresses.length; i++) {
            if (operatorAddresses[i] == operatorAddress) {
                _authorizedOperatorMap[operatorClass][operatorAddresses[i]] =
                    false;
                
                uint256 lastOperatorIndex = operatorAddresses.length - 1;

                if (
                    (operatorAddresses.length > 1) &&
                    (i != lastOperatorIndex)
                ) {
                    operatorAddresses[i] =
                        operatorAddresses[lastOperatorIndex];
                }
                             
                operatorAddresses.pop();

                for (uint256 j = 1; j <= _proposalList.length; j++) {                
                    uint256 proposalId = _proposalList[j - 1];

                    if (_hasApproved[proposalId][operatorAddress]) {                        
                        if (_proposalMap[proposalId].approvers.length == 1) {
                            // This proposal has no other approvers, so remove
                            // it and continue searching
                            _removeProposal(proposalId, false);

                            // Decrement j to account for swap during removal
                            // if any proposals remain
                            if (_proposalList.length > 0) {
                                j--;
                            }
                        } else {
                            // Other operators have approved this proposal, so
                            // only remove the current operator from approvers
                            _revokeApproval(proposalId, operatorAddress);
                        }                  
                    }                
                }

                emit OperatorRemoved(uint256(operatorClass), operatorAddress);

                return true;
            }
        }

        return false;
    }

    /**
     * @dev This function purges authorization for all currently authorized
     * operators to conduct `operatorClass` operations and emits a variable
     * number of {ProposalRemoved} events (depending on the number of active
     * proposals corresponding to `operatorClass`) and an {OperatorsPurged}
     * event.
     * @param operatorClass The operator class to be purged
     * @return success A Boolean value indicating that {operatorClass}
     * authorization has been removed from all operators
     */   
    function _purgeOperators(OperatorClasses operatorClass)
        internal
        returns (bool success)
    {
        for (
            uint256 i = 0;
            i < _authorizedOperatorList[operatorClass].length;
            i++
        ) {
            _authorizedOperatorMap
                [operatorClass]
                [_authorizedOperatorList[operatorClass][i]] = false;
        }

        delete _authorizedOperatorList[operatorClass];

        for (uint256 j = 1; j <= _proposalList.length; j++) {
            uint256 proposalId = _proposalList[j - 1];
            if (
                _getRequiredOperatorClass(
                    _proposalMap[proposalId].operation
                ) == operatorClass
            ) {
                // Remove proposal and keep searching
                _removeProposal(proposalId, false);

                // Decrement j to account for swap during removal
                // if any proposals remain
                if (_proposalList.length > 0) {
                    j--;
                }
            }
        }

        emit OperatorsPurged(uint256(operatorClass));

        return true;
    }

    /**
     * @dev This function returns the required {OperatorClasses} authorization
     * that an operator must have to conduct `operation`. This operation will
     * revert if `operation` does not correspond to a valid {Operations} value.
     * @param operation The {Operations} value corresponding to the operation 
     * that will be checked for operator class requirement
     * @return operatorClass The required {OperatorClasses} authorization that
     * an operator must have to conduct the provided {operation}
     */
    function _getRequiredOperatorClass(Operations operation)
        internal
        pure
        returns (OperatorClasses operatorClass)
    {
        if (
            (operation == Operations.Pause) ||
            (operation == Operations.Unpause) ||
            (operation == Operations.AddManager) ||
            (operation == Operations.RemoveManager) ||
            (operation == Operations.RemoveProposal) ||
            (operation == Operations.PurgeProposals) ||
            (operation == Operations.AddOperator) ||
            (operation == Operations.RemoveOperator) ||
            (operation == Operations.PurgeOperators) ||
            (operation == Operations.UpdateCollyptoAddress)
        ) {
            return OperatorClasses.Prime;
        } else if (operation == Operations.ForceTransfer) {
            return OperatorClasses.Dispatch;
        } else if (operation == Operations.SetUserStatus) {
            return OperatorClasses.Arbiter;
        } else if (operation == Operations.Freeze) {
            return OperatorClasses.Freeze;
        } else if (operation == Operations.Unfreeze) {
            return OperatorClasses.Unfreeze;
        } else if (operation == Operations.Lock) {
            return OperatorClasses.Lock;
        } else if (operation == Operations.Unlock) {
            return OperatorClasses.Unlock;
        } else if (operation == Operations.Mint) {
            return OperatorClasses.Mint;
        } else if (operation == Operations.Burn) {
            return OperatorClasses.Burn;
        }

        // Specified operation is invalid
        revert();
    }

    /**
     * @dev This function determines whether `operatorClass` is a valid value
     * of the {OperatorClasses} enumeration and returns a Boolean value
     * indicating its validity.
     * @param operatorClass The operator class to be validated
     * @return valid A Boolean value indicating whether the {operatorClass} is
     * a valid operator class and member of the {OperatorClasses} enumeration
     */
    function _isValidOperatorClass(OperatorClasses operatorClass)
        internal
        pure
        returns (bool valid)
    {
        uint256 operatorClassIndex = uint256(operatorClass);
        
        if ((operatorClassIndex < 0) || (operatorClassIndex > 8)) {
            return false;
        }

        return true;
    }
}