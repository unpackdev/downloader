// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


import "./IERC20.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./AggregatorV3Interface.sol";

contract PayeeV1 is Ownable {

    using Address for address;

    string public payeeId;
    AggregatorV3Interface internal dataFeed;


    // SCT = 1e6 usct 
    uint256 public SC = 1000;

    uint256  public confirmedFund;

    struct Payment{
        address sender;
        string dataId;
        string cid;
        uint80 roundId;
        uint256 amountA;
        uint256 amountB;
        uint256 createdAt;
        uint256 expiredAt;
        uint status; // 1: pending, 2: paid
    }

    mapping(string => Payment) public getPayment;

    event PaymentCreated(string dataId,string cid,uint256 amount, uint256 expiredAt);

    event PaymentConfirmed(string dataId);

    event Withdraw(address token, uint256 amount);

    constructor(address feed) Ownable(tx.origin) {
        dataFeed = AggregatorV3Interface(feed);
    }

    /*
     * _cid: cid of the payment proposal 
     * _sao: amount aht the payee need to pay to network
     * _timeout: time to refund 
     *
     */
    function createPayment(string memory _cid, string memory _dataId, uint256 _sao, uint256 _timeout) external payable {

        Payment memory p = getPayment[_dataId];

        require(p.roundId == 0, "DATAID ALREADY EXISTS");

        uint256 amountA = msg.value;

        (int price, uint80 roundId) = _getPrice();

        uint256 amountB = _sao * uint256(1e15) / uint256(price);

        // verify payment amount with latest round price feed
        require(amountA >= amountB, "INVALID PAYMENT AMOUNT");

        Payment memory payment;
        payment.dataId=  _dataId;
        payment.cid = _cid;
        payment.sender = tx.origin;
        payment.amountA = amountA;
        payment.roundId = roundId;
        payment.amountB = amountB;
        payment.createdAt = block.timestamp;
        payment.expiredAt = block.timestamp + _timeout;
        payment.status = 1;

        getPayment[_dataId] = payment;

        emit PaymentCreated(_dataId, _cid, amountB, payment.expiredAt);
    }

    function confirmPayment(string memory _dataId) external onlyOwner {
        
        Payment memory payment = getPayment[_dataId];

        require(payment.status == 1, "PAYMENT NOT IN PENDING");

        payment.status = 2;

        getPayment[_dataId] = payment;

        confirmedFund += payment.amountA;

        emit PaymentConfirmed(payment.dataId);
    }

    function withdraw() external onlyOwner {
        require(confirmedFund> 0, "NO AVAILABLE CONFIRMED FUND");
        require(address(this).balance >= confirmedFund, "INSUFFICIENT ETH BALANCE");

        Address.sendValue(payable(msg.sender), confirmedFund);

        confirmedFund = 0;

        emit Withdraw(msg.sender,confirmedFund);
    }

    function refund( string memory _dataId) external {

        Payment memory payment = getPayment[_dataId];

        require(payment.roundId > 0, "INVALID PAYMENT");
        require(msg.sender == payment.sender, "NOT THE DATA OWNER");
        require(payment.status == 1, "PAYMENT NOT IN PENDING STATUS");
        require(address(this).balance >= payment.amountA, "INSUFFICIENT ETH BALANCE");
        require(block.timestamp > payment.expiredAt, "NOT EXPIRED");

        Address.sendValue(payable(msg.sender), payment.amountA);

        payment.status = 3;

        getPayment[_dataId] = payment;

        emit Withdraw(msg.sender,confirmedFund);
    }

    function _getPrice() internal view returns (int, uint80) {
        (uint80 roundID, int answer,,,) = dataFeed.latestRoundData();
        return (answer, roundID);
    }
}
