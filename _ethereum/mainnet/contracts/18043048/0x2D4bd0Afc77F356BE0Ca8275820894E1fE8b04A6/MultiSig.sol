// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AccessControl.sol";

/**
 * @title MultiSigWallet
 * @dev A multisignature wallet contract that requires multiple owners' approvals for transactions.
 */
contract MultiSigWallet is AccessControl {
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");

    event SubmitTransaction(address indexed owner, uint256 indexed txIndex, address indexed to, bytes data);
    event ConfirmTransaction(address indexed owner, uint256 indexed txIndex);
    event RevokeConfirmation(address indexed owner, uint256 indexed txIndex);
    event SubmitToTimelock(address indexed owner, uint256 indexed txIndex);

    struct Transaction {
        address to; // Recipient address of the transaction
        bytes data; // Data payload of the transaction
        bool submitted; // Indicates if the transaction has been submitted to Timelock
        uint256 numConfirmations; // Number of confirmations received for the transaction
    }

    // Mapping to track confirmations for transactions
    mapping(uint256 => mapping(address => bool)) public isConfirmed;
    // Array to store transaction data
    Transaction[] public transactions;
    // Number of confirmations required for transaction execution
    uint256 public numConfirmationsRequired;

    // Modifier to restrict access to only contract owners
    modifier onlyOwner() {
        require(hasRole(OWNER_ROLE, msg.sender), "Only owners can call this function");
        _;
    }

    // Modifier to check if a transaction exists
    modifier txExists(uint256 _txIndex) {
        require(_txIndex < transactions.length, "Transaction does not exist");
        _;
    }

    // Modifier to check if a transaction has not been submitted to Timelock
    modifier notSubmitted(uint256 _txIndex) {
        require(!transactions[_txIndex].submitted, "Transaction already submitted");
        _;
    }

    // Modifier to check if a transaction has not been confirmed
    modifier notConfirmed(uint256 _txIndex) {
        require(!isConfirmed[_txIndex][msg.sender], "Transaction already confirmed");
        _;
    }

    // Modifier to check if the sender is the current admin
    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Only admin can call this function");
        _;
    }

    /**
     * @dev Constructor to initialize the contract with owners and required confirmations.
     * @param _owners Array of owner addresses.
     * @param _numConfirmationsRequired Number of confirmations required for transaction execution.
     */
    constructor(address[] memory _owners, uint256 _numConfirmationsRequired) {
        require(_owners.length > 0, "At least one owner is required");
        require(
            _numConfirmationsRequired > 0 && _numConfirmationsRequired <= _owners.length,
            "Invalid number of required confirmations"
        );

        // Set up access control roles
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(OWNER_ROLE, DEFAULT_ADMIN_ROLE);

        // Check for unique owners' addresses and grant owner role
        for (uint256 i = 0; i < _owners.length; i++) {
            require(_owners[i] != address(0), "Invalid owner address");
            require(!hasRole(OWNER_ROLE, _owners[i]), "Owner address not unique");
            grantRole(OWNER_ROLE, _owners[i]);
        }

        // Set the required number of confirmations
        numConfirmationsRequired = _numConfirmationsRequired;
    }

    /**
     * @dev Submits a transaction for approval.
     * @param _to Recipient address of the transaction.
     */
    function submitTransaction(address _to) public onlyOwner {
        uint256 txIndex = transactions.length;
        bytes memory withdrawData = abi.encodeWithSignature("withdraw()");

        // Add transaction to the transactions array
        transactions.push(Transaction({to: _to, data: withdrawData, submitted: false, numConfirmations: 0}));

        emit SubmitTransaction(msg.sender, txIndex, _to, withdrawData);
    }

    /**
     * @dev Confirms a transaction.
     * @param _txIndex Index of the transaction to confirm.
     */
    function confirmTransaction(
        uint256 _txIndex
    ) public onlyOwner txExists(_txIndex) notSubmitted(_txIndex) notConfirmed(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];
        transaction.numConfirmations += 1;
        isConfirmed[_txIndex][msg.sender] = true;

        emit ConfirmTransaction(msg.sender, _txIndex);
    }

    /**
     * @dev Submits a confirmed transaction to TimeLock queue.
     * @param _txIndex Index of the transaction to execute.
     * @param _timeLockAddress Address of the TimeLock contract.
     */
    function submitToTimelock(
        uint256 _txIndex,
        address _timeLockAddress
    ) public onlyOwner txExists(_txIndex) notSubmitted(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];

        require(transaction.numConfirmations >= numConfirmationsRequired, "Minimum confirmations required");

        transaction.submitted = true;

        // Call the submitTransaction function of the TimeLock contract using .call()
        (bool success, ) = _timeLockAddress.call{value: 0, gas: 100000}(
            abi.encodeWithSignature("submitTransaction(address,bytes)", transaction.to, transaction.data)
        );
        require(success, "Call to TimeLock submitTransaction failed");

        emit SubmitToTimelock(msg.sender, _txIndex);
    }

    /**
     * @dev Revokes a previously confirmed transaction.
     * @param _txIndex Index of the transaction to revoke confirmation from.
     */
    function revokeConfirmation(uint256 _txIndex) public onlyOwner txExists(_txIndex) notSubmitted(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];

        require(isConfirmed[_txIndex][msg.sender], "Transaction not confirmed");

        transaction.numConfirmations -= 1;
        isConfirmed[_txIndex][msg.sender] = false;

        emit RevokeConfirmation(msg.sender, _txIndex);
    }

    /**
     * @dev Returns the total number of transactions.
     * @return Total number of transactions.
     */
    function getTransactionCount() public view returns (uint256) {
        return transactions.length;
    }

    /**
     * @dev Retrieves details of a specific transaction.
     * @param _txIndex Index of the transaction to retrieve details for.
     * @return to Recipient address of the transaction.
     * @return data Data payload of the transaction.
     * @return submitted True if the transaction has been submitted to the TimeLock, false otherwise.
     * @return numConfirmations Number of confirmations received for the transaction.
     */
    function getTransaction(
        uint256 _txIndex
    ) public view txExists(_txIndex) returns (address to, bytes memory data, bool submitted, uint256 numConfirmations) {
        Transaction storage transaction = transactions[_txIndex];

        return (transaction.to, transaction.data, transaction.submitted, transaction.numConfirmations);
    }

    // Function to transfer DEFAULT_ADMIN_ROLE
    function transferAdminRole() public onlyAdmin {
        require(!hasRole(DEFAULT_ADMIN_ROLE, address(this)), "Admin role already set");

        // Grant DEFAULT_ADMIN_ROLE to the new admin(current contract address)
        grantRole(DEFAULT_ADMIN_ROLE, address(this));

        // Revoke DEFAULT_ADMIN_ROLE from the current admin (msg.sender)
        revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
}
