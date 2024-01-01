// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
    Chancoin Subscription Contract
    Your personal /biz/ analyst
    Organic engagement analyzer for cryptocurrencies on 4chan
    
    Website: https://chanalog.io
    Twitter: twitter.com/chanalog_
    Instagram: chanalog.io
    Tiktok: chanalog.io
**/

import "./Ownable.sol";
import "./SafeMath.sol";

contract SubscriptionDispatcher is Ownable {
    address payable public subWallet;
    address payable public burnWallet;

    event subWalletUpdated(
        address indexed newWallet,
        address indexed oldWallet
    );

    event burnWalletUpdated(
        address indexed newWallet,
        address indexed oldWallet
    );

    constructor(address payable _subWalletAddress, address payable _burnWalletAddress) {
        subWallet = _subWalletAddress;
        burnWallet = _burnWalletAddress;
    }

    receive() external payable {}

    function dispatchFunds() payable external onlyOwner {
        require(address(this).balance > 0, "No funds to dispatch");
        uint256 burnAmount = SafeMath.div(SafeMath.mul(address(this).balance, 40), 100);
        uint256 subAmount = SafeMath.sub(address(this).balance, burnAmount);
        bool success;
        (success, ) = address(subWallet).call{value: subAmount}("");
        (success, ) = address(burnWallet).call{value: burnAmount}("");
    }

    function updateSubWallet(address payable newWallet) external onlyOwner {
        emit subWalletUpdated(newWallet, subWallet);
        subWallet = newWallet;
    }

    function updateBurnWallet(address payable newWallet) external onlyOwner {
        emit burnWalletUpdated(newWallet, burnWallet);
        burnWallet = newWallet;
    }
}