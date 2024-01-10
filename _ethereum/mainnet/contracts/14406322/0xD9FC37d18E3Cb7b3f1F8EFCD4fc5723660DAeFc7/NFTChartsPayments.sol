// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.0;

import "./Ownable.sol";

contract NFTChartsPayments is Ownable {
    // The expected amount per payment.
    uint256 public amount;

    // The destination address where the eth will be sent to.
    address payable public destAddr;

    // Stores the last time of a successful payment for a collection.
    mapping (address => uint256) public paymentTimes;

    constructor(uint256 _amount, address payable _destAddr) {
        setAmount(_amount);
        setDestAddr(_destAddr);
    }

    // Set the amount expected per payment.
    function setAmount(uint256 _amount) public onlyOwner {
        amount = _amount;
    }

    // Set the destination address where the eth will be sent to.
    function setDestAddr(address payable _destAddr) public onlyOwner {
        destAddr = _destAddr;
    }
  
    // Make a payment, specifying the address of the contract of the collection
    // for which the payment is for.
    function pay(address collectionAddr) public payable {
        require(msg.value >= amount, "WRONG_AMOUNT");

        // Send to destination address
        destAddr.transfer(msg.value);

        // Register the payment from the collection address
        paymentTimes[collectionAddr] = block.timestamp;
    }

    // Checks if there was a payment for a specific collection in the last
    // specified interval of time.
    function hasPaid(address collectionAddr, uint256 timeInterval)
        public
        view
        returns (bool)
    {
        return block.timestamp - paymentTimes[collectionAddr] < timeInterval;
    }

    // Fallback receive function that sends any sent eth to the destination 
    // address, in case someone sends eth directly to this contract.
    receive() external payable {
        if (msg.value > 0) {
            destAddr.transfer(msg.value);
        }
    }

}
