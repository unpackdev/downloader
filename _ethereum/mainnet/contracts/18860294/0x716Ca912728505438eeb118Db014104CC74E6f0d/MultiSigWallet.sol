// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "./IERC20.sol";
import "./SafeERC20.sol";

contract MultiSigWallet {

    using SafeERC20 for IERC20;

    event QueueTransaction(
        uint256 indexed idx,
        address indexed to,
        uint256 value,
        bytes   data,
        uint256 exeAfter,
        uint256 exeBefore
    );

    event ConfirmTransaction(uint256 indexed idx, address indexed admin);

    event RevokeConfirmation(uint256 indexed idx, address indexed admin);

    event ExecuteTransaction(uint256 indexed idx, address indexed admin);

    struct Transaction {
        uint256 idx;
        address to;
        uint256 value;
        bytes   data;
        uint256 exeAfter;
        uint256 exeBefore;
        bool    executed;
        uint256 numConfirmations;
    }

    modifier onlyAdmin() {
        require(isAdmin[msg.sender], 'Only Admin');
        _;
    }

    modifier txExists(uint256 idx) {
        require(idx < transactions.length, 'Tx not exist');
        _;
    }

    modifier notExecuted(uint256 idx) {
        require(!transactions[idx].executed, 'Tx already executed');
        _;
    }

    modifier notConfirmed(uint256 idx) {
        require(!isConfirmed[idx][msg.sender], 'Tx already confirmed');
        _;
    }

    uint256 public constant STALE_PERIOD = 14 days;

    address[] public admins;

    mapping (address => bool) public isAdmin;

    uint256 public numConfirmationsRequired;

    Transaction[] public transactions;

    mapping (uint256 => mapping (address => bool)) public isConfirmed;

    constructor (address[] memory admins_, uint256 numConfirmationsRequired_) {
        require(numConfirmationsRequired_ <= admins_.length, 'Invalid numConfirmationsRequired');
        for (uint256 i = 0; i < admins_.length; i++) {
            address admin = admins_[i];
            require(admin != address(0), 'Invalid admin');
            isAdmin[admin] = true;
            admins.push(admin);
        }
        numConfirmationsRequired = numConfirmationsRequired_;
    }

    //================================================================================
    // Getters
    //================================================================================

    function getAllAdmins() external view returns (address[] memory) {
        return admins;
    }

    function getLastNTransactions(uint256 n) external view returns (Transaction[] memory) {
        uint256 length = transactions.length;
        if (n > length) n = length;

        Transaction[] memory res = new Transaction[](n);
        for (uint256 i = 0; i < n; i++) {
            res[i] = transactions[length - n + i];
        }

        return res;
    }

    //================================================================================
    // Setters
    //================================================================================

    function addAdmin(address admin) external {
        require(msg.sender == address(this), 'Only MultiSigWallet');
        require(admin != address(0), 'Invalid admin');
        require(!isAdmin[admin], 'Admin not unique');
        isAdmin[admin] = true;
        admins.push(admin);
    }

    function delAdmin(address admin) external {
        require(msg.sender == address(this), 'Only MultiSigWallet');
        require(isAdmin[admin], 'Admin not exists');
        isAdmin[admin] = false;
        uint256 length = admins.length;
        for (uint256 i = 0; i < length - 1; i++) {
            if (admins[i] == admin) {
                admins[i] = admins[length - 1];
                break;
            }
        }
        admins.pop();
    }

    function setNumConfirmationRequired(uint256 newNumConfirmationsRequired) external {
        require(msg.sender == address(this), 'Only MultiSigWallet');
        numConfirmationsRequired = newNumConfirmationsRequired;
    }

    //================================================================================
    // Actions
    //================================================================================

    function queueTransaction(
        address to,
        uint256 value,
        bytes memory data,
        uint256 delay
    ) external {
        uint256 idx = transactions.length;
        uint256 exeAfter = block.timestamp + delay;
        uint256 exeBefore = block.timestamp + STALE_PERIOD;
        transactions.push(
            Transaction({
                idx: idx,
                to: to,
                value: value,
                data: data,
                exeAfter: exeAfter,
                exeBefore: exeBefore,
                executed: false,
                numConfirmations: 0
            })
        );
        emit QueueTransaction(idx, to, value, data, exeAfter, exeBefore);
    }

    function confirmTransaction(uint256 idx)
    public onlyAdmin txExists(idx) notExecuted(idx) notConfirmed(idx)
    {
        Transaction storage transaction = transactions[idx];
        transaction.numConfirmations += 1;
        isConfirmed[idx][msg.sender] = true;
        emit ConfirmTransaction(idx, msg.sender);
    }

    function revokeConfirmation(uint256 idx)
    external onlyAdmin txExists(idx) notExecuted(idx)
    {
        Transaction storage transaction = transactions[idx];
        require(isConfirmed[idx][msg.sender], 'Not confirmed');
        transaction.numConfirmations -= 1;
        isConfirmed[idx][msg.sender] = false;
        emit RevokeConfirmation(idx, msg.sender);
    }

    function executeTransaction(uint256 idx)
    external onlyAdmin txExists(idx) notExecuted(idx)
    {
        if (!isConfirmed[idx][msg.sender]) {
            confirmTransaction(idx);
        }

        Transaction storage transaction = transactions[idx];

        require(
            transaction.numConfirmations >= numConfirmationsRequired,
            'Cannot execute, confirmations not reached'
        );
        require(
            block.timestamp >= transaction.exeAfter && block.timestamp < transaction.exeBefore,
            'Connot execute, execution time window not met'
        );

        transaction.executed = true;

        (bool success, ) = transaction.to.call{value: transaction.value}(transaction.data);
        require(success, 'Execute failed');

        emit ExecuteTransaction(idx, msg.sender);
    }

    //================================================================================
    // Helpers
    //================================================================================

    receive() external payable {}

    // withdraw function for any stucked token or ETH in this contract
    // only 1 admin privilege required for this function
    function withdraw(address token, address to) external onlyAdmin {
        if (token == address(0)) {
            uint256 balance = address(this).balance;
            if (balance > 0) {
                (bool success, ) = payable(to).call{value: balance}('');
                require(success);
            }
        } else {
            uint256 balance = IERC20(token).balanceOf(address(this));
            if (balance > 0) {
                IERC20(token).safeTransfer(to, balance);
            }
        }
    }

}

