// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SafeERC20.sol";
import "./Ownable.sol";


contract SubscriptionManager is Ownable {
    using SafeERC20 for IERC20;

    uint256 public subscriptionFee = 100;  // 1%
    uint256 public FEE_DENOMINATOR = 10000;  // 100%

    mapping (address => mapping (IERC20 => uint256)) public merchantTokenBalances;

    constructor() {}
    receive () external payable {}

    // --------------- FEE CHANGERS
    function changeSubscriptionFee(uint256 newFee) external onlyOwner {
        require(newFee <= 1000, "Max fee: 10%");
        subscriptionFee = newFee;
    }

    // --------------- SUBSCRIPTIONS
    function collectSubscription(
        IERC20 token, 
        address subscriber, 
        uint256 offerPriceAmount,
        uint256 tokenGasFee,
        address merchant
    ) external onlyOwner {
        uint256 netIncome = offerPriceAmount - offerPriceAmount * subscriptionFee / FEE_DENOMINATOR;

        merchantTokenBalances[merchant][token] += netIncome;
        token.safeTransferFrom(subscriber, address(this), offerPriceAmount + tokenGasFee);
    }

    function refund(
        IERC20 token, 
        address subscriber, 
        uint256 refundAmount
    ) external {
        require(merchantTokenBalances[msg.sender][token] >= refundAmount, "Can't refund more than have");

        merchantTokenBalances[msg.sender][token] -= refundAmount;
        token.safeTransferFrom(address(this), subscriber, refundAmount);
    }

    function oneTimeEthPayment(
        address merchant
    ) external payable {
        uint256 netIncome = msg.value - msg.value * subscriptionFee / FEE_DENOMINATOR;
        merchantTokenBalances[merchant][IERC20(address(0x0))] += netIncome;
    }

    // --------------- WITHDRAW FROM CONTRACT
    function withdrawMerchantEth() external {
        uint256 balance = merchantTokenBalances[msg.sender][IERC20(address(0x0))];
        require(balance > 0, "Zero balance");

        uint256 available = address(this).balance;
        require(available >= balance, "You can't withdraw right now.");

        merchantTokenBalances[msg.sender][IERC20(address(0x0))] = 0;
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "Failed to send Ether");
    }

    function withdrawMerchant(IERC20 token) external {
        uint256 balance = merchantTokenBalances[msg.sender][token];
        require(balance > 0, "Zero balance");

        uint256 available = token.balanceOf(address(this));
        require(available >= balance, "You can't withdraw right now.");

        merchantTokenBalances[msg.sender][token] = 0;
        token.safeTransfer(msg.sender, balance);
    }

    function withdrawTo(IERC20 token, address recipient, uint256 amountWei) external onlyOwner {
        require(token.balanceOf(address(this)) >= amountWei, "Not enough tokens");
        token.safeTransfer(recipient, amountWei);
    }

    function withdraw() external onlyOwner {
        uint256 _balance = address(this).balance;
        require(payable(msg.sender).send(_balance));
    }

    function addMerchantBalance(IERC20 token, address merchant, uint256 amountWei) external onlyOwner {
        merchantTokenBalances[merchant][token] += amountWei;
    }

    function decreaseMerchantBalance(IERC20 token, address merchant, uint256 amountWei) external onlyOwner {
        require(merchantTokenBalances[msg.sender][token] >= amountWei, "Can't decrease more than have"); 
        merchantTokenBalances[merchant][token] -= amountWei;
    } 

}

