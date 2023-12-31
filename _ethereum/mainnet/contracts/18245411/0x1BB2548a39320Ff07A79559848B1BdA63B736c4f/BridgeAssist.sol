// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

import "./ReentrancyGuardUpgradeable.sol";
import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

import "./IMultiSigWallet.sol";

contract BridgeAssist is 
    Initializable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable
{
    using SafeERC20 for IERC20;

    modifier notNull(address _address) {
        require(_address != address(0));
        _;
    }

    modifier transactionExists(uint transactionId) {
        require(transactions[transactionId].destination != address(0));
        _;
    }

    modifier notExecuted(uint transactionId) {
        require(!transactions[transactionId].executed);
        _;
    }
    
    modifier confirmed(uint transactionId, address user) {
        require(confirmations[transactionId][user]);
        _;
    }

    modifier notConfirmed(uint transactionId, address user) {
        require(!confirmations[transactionId][user]);
        _;
    }

    event AddToken(address indexed owner, address indexed token);
    event SetRelayer(address indexed owner, address relayer);
    event SetMultisig(address indexed owner, address multisig);
    event Collect(address indexed sender, uint256 amount);
    event Dispense(address indexed sender, uint256 amount);
    event Submission(uint indexed transactionId);
    event Execution(uint indexed transactionId);
    event Confirmation(address indexed sender, uint indexed transactionId);
    event MultisigSubmission(uint indexed transactionId);

    struct Transaction {
        address payable destination;
        uint tokenIndex;
        uint value;
        uint code;
        bool executed;
        uint txTimestamp;
    }
    
    uint public constant COLLECT_CODE = 1;
    uint public constant DISPENSE_CODE = 2;
    uint public transactionCount;

    uint public lastTokenIndex;

    address public dev;
    address public relayer;

    mapping(uint => Transaction) public transactions;
    mapping(uint => mapping(address => bool)) public confirmations;
    mapping(uint => address) public tokens;

    address public multisig;

    receive() external payable {}

    function initialize(
        address _relayer,
        address _multisig
    ) external initializer {
        __Context_init();
        __Ownable_init();
        __Pausable_init();
        relayer = _relayer;
        multisig = _multisig;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
    
    function addToken(address token) external onlyOwner notNull(token) {
        tokens[lastTokenIndex++] = token;
        emit AddToken(msg.sender, token);
    }

    function setRelayer(address _relayer) external onlyOwner notNull(_relayer) {
        relayer = _relayer;
        emit SetRelayer(msg.sender, _relayer);
    }

    function setMultisig(address _multisig) external onlyOwner notNull(_multisig) {
        multisig = _multisig;
        emit SetMultisig(msg.sender, _multisig);
    }

    function submitTransaction(address payable destination, uint tokenIndex, uint value, uint code) external nonReentrant whenNotPaused returns (uint transactionId) {
        require(msg.sender == relayer, "only hotwallet can call this function");
        require(tokenIndex < lastTokenIndex, "invalid token index");
        require(code == COLLECT_CODE || code == DISPENSE_CODE, "invalid code");

        uint txTimestamp = _getNow();
        transactionId = addTransaction(destination, tokenIndex, value, code, txTimestamp);
        confirmations[transactionId][relayer] = true;
        if(code == COLLECT_CODE) {
            confirmations[transactionId][destination] = true;
            confirmations[transactionId][multisig] = true;
            executeTransaction(transactionId);
        } else {
            bytes memory data = abi.encodeWithSignature("confirmTransaction(uint)", [transactionId]);
            uint multisigTxId = IMultiSigWallet(multisig).submitTransaction(payable(address(this)), address(0), 3, 0, 0, data, 0);
            emit MultisigSubmission(multisigTxId);
        }
    }

    function addTransaction(address payable destination, uint tokenIndex, uint value, uint code, uint txTimestamp) internal notNull(destination) returns (uint transactionId) {
        transactionId = transactionCount;
        transactions[transactionId] = Transaction({
            destination : destination,
            tokenIndex: tokenIndex,
            value : value,
            code: code,
            executed : false,
            txTimestamp : txTimestamp
        });
        transactionCount += 1;
        emit Submission(transactionId);
    }

    function isConfirmed(uint transactionId) public view returns (bool) {
        address user = transactions[transactionId].destination;
        mapping (address => bool) storage comfirm = confirmations[transactionId];
        if (comfirm[user] && comfirm[multisig])
            return true;
        else
            return false;
    }
    
    function confirmTransaction(uint transactionId) external nonReentrant whenNotPaused transactionExists(transactionId) notConfirmed(transactionId, msg.sender) {
        require(msg.sender == transactions[transactionId].destination || msg.sender == multisig, "Only destination or multisig can approve tx");
        uint tokenIndex = transactions[transactionId].tokenIndex;
        address token = tokens[tokenIndex];
        require(transactions[transactionId].value <= IERC20(token).balanceOf(address(this)), "Not enough token to withdraw");
        confirmations[transactionId][msg.sender] = true;
        emit Confirmation(msg.sender, transactionId);
        executeTransaction(transactionId);
    }


    function executeTransaction(uint transactionId) internal notExecuted(transactionId) {
        if (isConfirmed(transactionId)) {
            Transaction storage txn = transactions[transactionId];
            address token = tokens[txn.tokenIndex];
            txn.executed = true;
            if(txn.code == COLLECT_CODE) {
                IERC20(token).safeTransferFrom(txn.destination, address(this), txn.value);
                emit Collect(txn.destination, txn.value);
            } else {
                IERC20(token).safeTransfer(txn.destination, txn.value);
                emit Dispense(txn.destination, txn.value);
            }
        }
    }

    function _getNow() internal view returns (uint256) {
      return block.timestamp;
    }

}