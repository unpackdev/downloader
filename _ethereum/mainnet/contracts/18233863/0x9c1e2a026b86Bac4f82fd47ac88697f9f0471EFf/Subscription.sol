// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./Ownable.sol";

contract Subscription is Ownable {
    address public subscriptionWallet = 0x241397fa0B3023a9CF37C13A7083013e0511853A;

    event SubscriptionTransferred(address indexed to, uint256 amount);

    constructor() {}

    function setSubscriptionWallet(address _subscriptionWallet) external onlyOwner {
        require(_subscriptionWallet != address(0), "Invalid address");
        subscriptionWallet = _subscriptionWallet;
    }

    function deposit(address _refAddress, uint _feeTax) external payable {
        require(_refAddress != address(0), "Invalid ref address");
        require(_feeTax <= 10000, "Invalid fee tax");
        uint256 refAmount = (msg.value * _feeTax) / 10000;
        (bool success1,) = subscriptionWallet.call{value: msg.value - refAmount}("");
        require(success1, "Failed to send subscriptionWallet");

        (bool success2,) = _refAddress.call{value: refAmount}("");
        require(success2, "Failed to send _refAddress");

        emit SubscriptionTransferred(_refAddress, refAmount);
    }
}