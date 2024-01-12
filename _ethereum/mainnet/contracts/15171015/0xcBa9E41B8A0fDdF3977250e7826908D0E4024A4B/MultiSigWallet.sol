// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import "./IERC20.sol";
import "./SafeERC20.sol";

/// Multisig controlled by 2 groups: admins and owners. 
/// Admins can add and remove admins and owners and set the confirmations required from each.
/// Some number of confirmations are required from both admins and owners for transactions
/// to be executed.
contract MultiSigWallet {
    using SafeERC20 for IERC20;
    
    event Deposit(address indexed sender, uint256 amount, uint256 balance);
    event SubmitTransaction(
        address indexed owner,
        uint256 indexed txIndex,
        address indexed to,
        uint256 value,
        bytes data
    );
    event ConfirmTransaction(
        address indexed admin, 
        uint256 indexed txIndex,
        uint256 adminConfirmations,
        uint256 ownerConfirmations
    );
    event RevokeConfirmation(
        address indexed owner, 
        uint256 indexed txIndex,
        uint256 adminConfirmations,
        uint256 ownerConfirmations
    );
    event ExecuteTransaction(uint256 indexed txIndex);

    event AddAdmin(address indexed admin, address[] indexed admins);
    event AddOwner(address indexed owner, address[] indexed owners);
    
    event RemoveAdmin(address indexed admin, address[] indexed admins);
    event RemoveOwner(address indexed owner, address[] indexed owners);

    event SetAdminConfirmationsRequired(uint256 indexed adminConfirmationsRequired);
    event SetOwnerConfirmationsRequired(uint256 indexed ownerConfirmationsRequired);

    event Transfer(address indexed token, address indexed to, uint256 indexed amount);

    error AlreadyAnOwner(address owner);
    error AlreadyAnAdmin(address admin);

    error NotAnAdmin(address caller);
    error NotAnOwner(address caller);
    error NotAnAdminOrOwner(address caller);

    error OwnersAreRequired();
    error ConfirmationsRequiredCantBeZero();
    error MsgSenderIsNotThis(address msgSender);
    error ZeroAddress();

    error OwnerCantBeAdmin(address owner);
    error AdminCantBeOwner(address admin);

    error TxDoesNotExist(uint256 txIndex);
    error TxAlreadyExecuted(uint256 txIndex);
    error TxAlreadyConfirmed(uint256 txIndex);
    error TxFailed(uint256 txIndex);
    error TxNotConfirmed(uint256 txIndex);

    error InsufficientAdminConfirmations(uint256 numConfirmations, uint256 numRequired);
    error InsufficientOwnerConfirmations(uint256 numConfirmations, uint256 numRequired);
    error ConfirmationsRequiredAboveMax(uint256 confirmationsRequired, uint256 max);
    error ArrayLengthBelowMinLength(uint256 length, uint256 minLength);

    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 adminConfirmations;
        uint256 ownerConfirmations;
    }

    Transaction[] public transactions;

    address[] public admins;
    mapping(address => bool) public isAdmin;
    uint256 public adminConfirmationsRequired;

    address[] public owners;
    mapping(address => bool) public isOwner;
    uint256 public ownerConfirmationsRequired;

    // mapping from tx index => admin/owner => true if admin/owner has confirmed and false otherwise
    mapping(uint256 => mapping(address => bool)) public isConfirmed;

    modifier onlyAdminOrOwner() {
        if (!isOwner[msg.sender] && !isAdmin[msg.sender]) revert NotAnAdminOrOwner(msg.sender);
        _;
    }

    modifier txExists(uint256 _txIndex) {
        if (_txIndex >= transactions.length) revert TxDoesNotExist(_txIndex);
        _;
    }

    modifier notExecuted(uint256 _txIndex) {
        if (transactions[_txIndex].executed) revert TxAlreadyExecuted(_txIndex);
        _;
    }

    modifier notConfirmed(uint256 _txIndex) {
        if (isConfirmed[_txIndex][msg.sender]) revert TxAlreadyConfirmed(_txIndex);
        _;
    }

    modifier onlyConfirmed(uint256 _txIndex) {
        if (!isConfirmed[_txIndex][msg.sender]) revert TxNotConfirmed(_txIndex);
        _;
    }

    modifier onlyThis() {
        if (msg.sender != address(this)) revert MsgSenderIsNotThis(msg.sender);
        _;
    }

    /// WARNING: If _admins is empty the setters in this contract will not be callable
    constructor(
        address[] memory _admins,
        address[] memory _owners,
        uint256 _adminConfirmationsRequired,
        uint256 _ownerConfirmationsRequired
    ) {
        if (_owners.length == 0) revert OwnersAreRequired();
        if (_adminConfirmationsRequired > _admins.length) {
            revert ConfirmationsRequiredAboveMax(_adminConfirmationsRequired, _admins.length);
        }
        if (_ownerConfirmationsRequired == 0) 
            revert ConfirmationsRequiredCantBeZero();
        if (_ownerConfirmationsRequired > _owners.length) {
            revert ConfirmationsRequiredAboveMax(_ownerConfirmationsRequired, _owners.length);
        }

        uint256 adminsLength = _admins.length;
        for (uint256 i = 0; i < adminsLength; i++) {
            address admin = _admins[i];

            if (admin == address(0)) revert ZeroAddress();
            if (isAdmin[admin]) revert AlreadyAnAdmin(admin);

            isAdmin[admin] = true;
            admins.push(admin);
        }

        uint256 ownersLength = _owners.length;
        for (uint256 i = 0; i < ownersLength; i++) {
            address owner = _owners[i];

            if (owner == address(0)) revert ZeroAddress();
            if (isAdmin[owner]) revert OwnerCantBeAdmin(owner);
            if (isOwner[owner]) revert AlreadyAnOwner(owner);

            isOwner[owner] = true;
            owners.push(owner);
        }

        adminConfirmationsRequired = _adminConfirmationsRequired;
        ownerConfirmationsRequired = _ownerConfirmationsRequired;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    /// Submit a transaction to transfer _amount of _token to _to
    function submitTransfer(address _token, address _to, uint256 _amount) external {
        bytes memory data = abi.encodeWithSignature(
            "_transfer(address,address,uint256)", 
            _token,
            _to,
            _amount
        );
        submitTransaction(address(this), 0, data);
    }

    /// Submit a transaction to add a new _admin
    function submitAddAdmin(address _admin) external {
        bytes memory data = abi.encodeWithSignature("_addAdmin(address)", _admin);
        submitTransaction(address(this), 0, data);
    }

    /// Submit a transaction to add a new _owner
    function submitAddOwner(address _owner) external {
        bytes memory data = abi.encodeWithSignature("_addOwner(address)", _owner);
        submitTransaction(address(this), 0, data);
    }

    /// Submit a transaction to remove _admin
    function submitRemoveAdmin(address _admin) external {
        bytes memory data = abi.encodeWithSignature("_removeAdmin(address)", _admin);
        submitTransaction(address(this), 0, data);
    }

    /// Submit a transaction to remove _owner
    function submitRemoveOwner(address _owner) external {
        bytes memory data = abi.encodeWithSignature("_removeOwner(address)", _owner);
        submitTransaction(address(this), 0, data);
    }

    /// Submit a transaction to set the number of admin confirmations required to execute 
    /// transactions
    function submitSetAdminConfirmationsRequired(uint256 _adminConfirmationsRequired) external {
        bytes memory data = abi.encodeWithSignature(
            "_setAdminConfirmationsRequired(uint256)", 
            _adminConfirmationsRequired
        );
        submitTransaction(address(this), 0, data);
    }

    /// Submit a transaction to set the number of owner confirmations required to execute
    /// transactions
    function submitSetOwnerConfirmationsRequired(uint256 _ownerConfirmationsRequired) external {
        bytes memory data = abi.encodeWithSignature(
            "_setOwnerConfirmationsRequired(uint256)", 
            _ownerConfirmationsRequired
        );
        submitTransaction(address(this), 0, data);
    }

    /// Return the array of admins
    function getAdmins() external view returns (address[] memory) {
        return admins;
    }

    /// Return the array of owners
    function getOwners() external view returns (address[] memory) {
        return owners;
    }

    /// Return the number of transactions that have been submitted
    function getTransactionCount() external view returns (uint) {
        return transactions.length;
    }

    /// Return the transaction with _txIndex
    function getTransaction(uint256 _txIndex)
        external  
        view
        returns (
            address to,
            uint256 value,
            bytes memory data,
            bool executed,
            uint256 ownerConfirmations,
            uint256 adminConfirmations
        )
    {
        Transaction memory transaction = transactions[_txIndex];

        return (
            transaction.to,
            transaction.value,
            transaction.data,
            transaction.executed,
            transaction.ownerConfirmations,
            transaction.adminConfirmations
        );
    }

    /// Return this contract's _token balance
    function getBalance(address _token) external view returns (uint256) {
        if (_token == address(0)) revert ZeroAddress();
        return IERC20(_token).balanceOf(address(this));
    }

    /// Submit a new transaction for admin and owner confirmation
    function submitTransaction(
        address _to,
        uint256 _value,
        bytes memory _data
    ) 
        public 
        onlyAdminOrOwner 
    {
        uint256 txIndex = transactions.length;

        transactions.push(
            Transaction({
                to: _to,
                value: _value,
                data: _data,
                executed: false,
                adminConfirmations: 0,
                ownerConfirmations: 0
            })
        );

        emit SubmitTransaction(msg.sender, txIndex, _to, _value, _data);
    }

    /// Confirm that transaction with _txIndex can be executed
    function confirmTransaction(uint256 _txIndex)
        public
        onlyAdminOrOwner
        txExists(_txIndex)
        notConfirmed(_txIndex)
        notExecuted(_txIndex)
    {
        isConfirmed[_txIndex][msg.sender] = true;

        Transaction storage transaction = transactions[_txIndex];
        if (isAdmin[msg.sender]) {
            transaction.adminConfirmations += 1;
        } else {
            transaction.ownerConfirmations += 1;
        }

        emit ConfirmTransaction(
            msg.sender, 
            _txIndex, 
            transaction.adminConfirmations, 
            transaction.ownerConfirmations
        );
    }

    /// Revoke confirmation for transaction with _txIndex
    function revokeConfirmation(uint256 _txIndex)
        public
        onlyAdminOrOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
        onlyConfirmed(_txIndex)
    {
        isConfirmed[_txIndex][msg.sender] = false;

        Transaction storage transaction = transactions[_txIndex];
        if (isAdmin[msg.sender]) {
            transaction.adminConfirmations -= 1;
        } else {
            transaction.ownerConfirmations -= 1;
        }

        emit RevokeConfirmation(
            msg.sender, 
            _txIndex,
            transaction.adminConfirmations,
            transaction.ownerConfirmations
        );
    }

    /// Execute the transaction with _txIndex
    function executeTransaction(uint256 _txIndex)
        public
        virtual
        onlyAdminOrOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];

        uint256 adminConfirmations = transaction.adminConfirmations;
        if (adminConfirmations < adminConfirmationsRequired) {
            revert InsufficientAdminConfirmations(
                adminConfirmations, 
                adminConfirmationsRequired
            );
        }

        uint256 ownerConfirmations = transaction.ownerConfirmations;
        if (ownerConfirmations < ownerConfirmationsRequired) {
            revert InsufficientOwnerConfirmations(
                ownerConfirmations, 
                ownerConfirmationsRequired
            );
        }

        transaction.executed = true;

        (bool success, ) = transaction.to.call{value: transaction.value}(
            transaction.data
        );
        if (!success) revert TxFailed(_txIndex);

        emit ExecuteTransaction(_txIndex);
    }

    /// Not externally callable
    /// Transfer _amount of _token to _to
    function _transfer(address _token, address _to, uint256 _amount) public onlyThis {
        IERC20(_token).safeTransfer(_to, _amount);
        emit Transfer(_token, _to, _amount);
    }

    /// Not externally callable
    /// Add _admin as an admin
    function _addAdmin(address _admin) public onlyThis {
        if (isAdmin[_admin]) revert AlreadyAnAdmin(_admin);
        if (isOwner[_admin]) revert AdminCantBeOwner(_admin);
        isAdmin[_admin] = true;
        admins.push(_admin);
        emit AddAdmin(_admin, admins);
    }

    /// Not externally callable
    /// Add _owner as an owner
    function _addOwner(address _owner) public onlyThis {
        if (isOwner[_owner]) revert AlreadyAnOwner(_owner);
        if (isAdmin[_owner]) revert OwnerCantBeAdmin(_owner);
        isOwner[_owner] = true;
        owners.push(_owner);
        emit AddOwner(_owner, owners);
    }

    /// Not externally callable
    /// Remove _admin from being an admin
    function _removeAdmin(address _admin) public onlyThis {
        if (!isAdmin[_admin]) revert NotAnAdmin(_admin);
        uint256 adminsLength = admins.length;
        if (adminsLength - 1 < adminConfirmationsRequired) {
            revert ArrayLengthBelowMinLength(
                adminsLength - 1, 
                adminConfirmationsRequired
            );
        }
        for (uint256 i = 0; i < adminsLength; i++) {
            if (admins[i] == _admin) {
                isAdmin[_admin] = false;

                admins[i] = admins[adminsLength - 1];
                admins.pop();

                emit RemoveAdmin(_admin, admins);
                return;
            }
        }
    }

    /// Not externally callable
    /// Remove _owner from being an owner
    function _removeOwner(address _owner) public onlyThis {
        if (!isOwner[_owner]) revert NotAnOwner(_owner);
        uint256 ownersLength = owners.length;
        if (ownersLength - 1 < ownerConfirmationsRequired) {
            revert ArrayLengthBelowMinLength(
                ownersLength - 1, 
                ownerConfirmationsRequired
            );
        }
        for (uint256 i = 0; i < ownersLength; i++) {
            if (owners[i] == _owner) {
                isOwner[_owner] = false;

                owners[i] = owners[ownersLength - 1];
                owners.pop();

                emit RemoveOwner(_owner, owners);
                return;
            }
        }
    }

    /// Not externally callable
    /// Set the _ownerConfirmationsRequired for transactions be be executed
    function _setAdminConfirmationsRequired(uint256 _adminConfirmationsRequired) public onlyThis {
        if (_adminConfirmationsRequired > admins.length) {
            revert ConfirmationsRequiredAboveMax(_adminConfirmationsRequired, admins.length);
        }
 
        adminConfirmationsRequired = _adminConfirmationsRequired;
        emit SetAdminConfirmationsRequired(_adminConfirmationsRequired);
    }

    /// Not externally callable
    /// Set the _ownerConfirmationsRequired for transactions be be executed
    function _setOwnerConfirmationsRequired(uint256 _ownerConfirmationsRequired) public onlyThis {
        if (_ownerConfirmationsRequired == 0) revert ConfirmationsRequiredCantBeZero();
        if (_ownerConfirmationsRequired > owners.length) {
            revert ConfirmationsRequiredAboveMax(_ownerConfirmationsRequired, owners.length);
        }

        ownerConfirmationsRequired = _ownerConfirmationsRequired;
        emit SetOwnerConfirmationsRequired(_ownerConfirmationsRequired);
    }
}
