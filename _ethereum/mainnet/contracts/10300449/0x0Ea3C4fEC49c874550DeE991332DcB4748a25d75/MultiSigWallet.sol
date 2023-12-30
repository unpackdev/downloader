pragma solidity ^0.6.0;

import "./ReentrancyGuard.sol";
import "./Wallet.sol";
import "./Helpers.sol";

contract SetOperator is Wallet, ReentrancyGuard {
    address signerOne;
    address signerTwo;

    address operator;

    event NewOperatorVote ();
    event AuthorizedOperator (address operator);
    event RevokedOperator (address operator);

    address[] public operators;

    bool public operatorVoteOne;
    bool public operatorVoteTwo;
    address public operatorVoteAddress;

    bool firstOperator = false;

   constructor (address _signerOne, address _signerTwo, address _tokenContract) public {
        signerOne = _signerOne;
        signerTwo = _signerTwo;
        tokenContract = IERC777(_tokenContract);
    }

    function getOperators () external view returns (address[] memory) {
        return operators;
    } //TODO: Check if works

    function setDefaultOperators(address[] memory _defaultOperators) external onlyOnce("assignFirstOperator") onlyDeployer {
        require(firstOperator == false, "Can only be ran once!");

        for (uint i = 0; i < _defaultOperators.length; i++) {
            _authorizeOperator(_defaultOperators[i]);
            emit AuthorizedOperator(_defaultOperators[i]);
        }

        firstOperator = true;
    }

    function revokeOperator (address _operator) isSigner external returns (address[] memory){
        uint i = 0;
        for (;i < operators.length; i++) {
            if (_operator == operators[i]) {
                break;
            }
            if (i == operators.length - 1) {
                revert("Address is not an operator");
            }
        }
        tokenContract.revokeOperator(_operator);
        _removeOperator(i);
        emit RevokedOperator(_operator);

        return operators;
    }

    function _removeOperator (uint index) private {
        if (index >= operators.length) {
             require(false, "index out of bounds");
        }

        for (uint i = index; i < operators.length-1; i++){
            operators[i] = operators[i+1];
        }
        operators.pop();
    }

    //TODO: revoke operator
    function _authorizeOperator (address _operator) private {
        tokenContract.authorizeOperator(_operator);
        operators.push(_operator);

        emit AuthorizedOperator(_operator);
    }

    function createOperatorVote (address _operator) external isSigner {
        operatorVoteAddress = _operator;
        operatorVoteOne = msg.sender == signerOne;
        operatorVoteTwo = msg.sender == signerTwo;

        emit NewOperatorVote();
    }

    function approveOperatorVote () external nonReentrant isSigner {
        if (msg.sender == signerOne) {
            operatorVoteOne = true;
        }
        if (msg.sender == signerTwo) {
            operatorVoteTwo = true;
        }

        if (operatorVoteOne == operatorVoteTwo) {
            _authorizeOperator(operatorVoteAddress);
        }
    }

    modifier isSigner () {
        require(msg.sender == signerOne || msg.sender == signerTwo, "Not allowed");
        _;
    }
} 

contract MultiSigWallet is SetOperator {
    uint public currentPaymentId = 0;

    event UpdatedPayment (uint paymentId);

    enum TxType { Eth, Imty }
    enum TxStatus { Pending, Completed }

    struct Payment {
        TxType txType;
        TxStatus txStatus;
        address payable to;
        uint amount;
        bool approvalOne;
        bool approvalTwo;
        uint creationTime;
        uint completionTime;
    }

    mapping (uint => Payment) payments;

    constructor (address _signerOne, address _signerTwo, address _tokenContract)
                ReentrancyGuard()
                SetOperator(_signerOne, _signerTwo, _tokenContract)
                public {}

    function createPayment (address _to, uint amount, TxType txType) external nonReentrant isSigner returns (uint) {
        address payable to = payable(_to);
        uint id = _createPayment(to, amount, txType);
        
        return id;
    }

    function _createPayment (address payable to, uint amount, TxType txType) private returns (uint) {
        require(amount > 0, "amount is below zero");

        currentPaymentId++;

        payments[currentPaymentId] = Payment({
            to: to,
            amount: amount,
            txType: txType,
            txStatus: TxStatus.Pending,
            creationTime: block.timestamp,
            completionTime: 0,
            approvalOne: msg.sender == signerOne,
            approvalTwo: msg.sender == signerTwo
        });

        emit UpdatedPayment(currentPaymentId);

        return currentPaymentId;
    }

    function approvePayment (uint id) external nonReentrant isSigner {
        Payment storage payment = payments[id];

        if (msg.sender == signerOne) {
            payment.approvalOne = true;
        }
        if (msg.sender == signerTwo) {
            payment.approvalTwo = true;
        }

        emit UpdatedPayment(id);
    }

    function sendPayment (uint id) external nonReentrant isSigner {
        Payment storage payment = payments[id];
        require(payment.txStatus == TxStatus.Pending, "Payment already completed");
        require(payment.approvalOne == true && payment.approvalTwo == true, "Payment has not been approved");

        if (payment.txType == TxType.Eth) {
            _ethTransfer(payment.to, payment.amount);
        }
        if (payment.txType == TxType.Imty) {
            _imtyTransfer(payment.to, payment.amount);
        }

        payment.txStatus = TxStatus.Completed;
        payment.completionTime = block.timestamp;

        emit UpdatedPayment(id);
    }

    function getPayment (uint id) external view returns (
            TxType txType,
            TxStatus txStatus,
            address to,
            uint amount,
            bool approvalOne,
            bool approvalTwo,
            uint creationTime,
            uint completionTime
    ){
        Payment memory payment = payments[id];

        txStatus = payment.txStatus;
        to = payment.to;
        amount = payment.amount;
        approvalOne = payment.approvalOne;
        approvalTwo = payment.approvalTwo;
        creationTime = payment.creationTime;
        completionTime = payment.completionTime;
    }

}