// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./Ownable.sol";

contract Subscription is Ownable {
    address public subscriptionWallet =
        0x241397fa0B3023a9CF37C13A7083013e0511853A;
    address public revenueWallet = 0xff5EDB0A0682D4B3d27495E2B00A324d8f5c16b9;
    uint256 feeSub = 7500;

    event SubscriptionTransferred(address indexed to, uint256 amount);

    constructor() {}

    function setSubscriptionWallet(
        address _subscriptionWallet
    ) external onlyOwner {
        require(_subscriptionWallet != address(0), "Invalid address");
        subscriptionWallet = _subscriptionWallet;
    }

    function setRevenueWallet(address _revenueWallet) external onlyOwner {
        require(_revenueWallet != address(0), "Invalid address");
        revenueWallet = _revenueWallet;
    }

    function setFeeSub(uint256 _feeSub) external onlyOwner {
        require(_feeSub <= 10000, "Invalid fee tax");
        feeSub = _feeSub;
    }

    function deposit(address _refAddress, uint _feeTax) external payable {
        require(_refAddress != address(0), "Invalid ref address");
        require(feeSub + _feeTax <= 10000, "Invalid fee tax");
        uint256 subAmount = (msg.value * feeSub) / 10000;
        uint256 refAmount = (msg.value * _feeTax) / 10000;

        (bool success1, ) = subscriptionWallet.call{value: subAmount}("");
        require(success1, "Failed to send subscriptionWallet");

        (bool success2, ) = _refAddress.call{value: refAmount}("");
        require(success2, "Failed to send refAddress");

        if (msg.value > refAmount + subAmount) {
            (bool success3, ) = revenueWallet.call{
                value: msg.value - refAmount - subAmount
            }("");
            require(success3, "Failed to send revenueWallet");
        }
        emit SubscriptionTransferred(_refAddress, refAmount);
    }
}
