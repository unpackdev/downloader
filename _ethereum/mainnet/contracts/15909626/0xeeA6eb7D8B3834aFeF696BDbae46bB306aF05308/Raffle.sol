// SPDX-License-Identifier: MIT
// Creators: @CryptoBarbar

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC721.sol";

import "./console.sol";

contract Raffle is Ownable {
    uint256 public subscriptionFee = 1 * 10**16;

    mapping(address => bool) public subscribedToRaffle;

    uint256 public raffleSupply = 2;
    uint256 public totalSubscribed;
    uint256 public totalRaffleMinted;
    
    bool public isSubscriptionOpen = false;
    bool public refundAvailable = false; // optional, if we want to block refund until a certain data
    bool public isRaffleActive = false;

    event SubscriptionOpen(bool status);
    event RefundAvailable(bool status);
    event RaffleOpen(bool status);

    modifier raffleCheck() {
        require(isRaffleActive, "Raffle is not active");
        require(subscribedToRaffle[msg.sender], "Caller not subscribed to raffle");
        _;
        totalRaffleMinted++;
    }

    /**
     * @dev user subscribe to raffle
     *
     */

    function subscribeToRaffle() public payable {
        require(isSubscriptionOpen == true, "Raffle subscription not open");
        require(msg.value == subscriptionFee, "Eth value should amount to subscription fee");
        require(subscribedToRaffle[msg.sender] == false, "Caller already subscribed to raffle"); 
        //avoid double spending

        subscribedToRaffle[msg.sender] = true;
        totalSubscribed++;
    }

    function claimRefund() public payable {
        require(refundAvailable == true, "Refund not available for now");
        require(subscribedToRaffle[msg.sender] == true, "Not subscribed");

        (bool success, ) = msg.sender.call{value: subscriptionFee}("");
        require(success, "Address: unable to send value, recipient may have reverted");
        subscribedToRaffle[msg.sender] = false;
        totalSubscribed--;
    }

    function setRaffleSupply(uint256 raffleSupply_) external onlyOwner {
        raffleSupply = raffleSupply_;
    }

    function setSubscription_fee(uint256 _subscriptionFee) external onlyOwner {
        subscriptionFee = _subscriptionFee;
    }

    function toggleSubscription() public onlyOwner {
        isSubscriptionOpen = !isSubscriptionOpen;
        emit SubscriptionOpen(isSubscriptionOpen);
    }

    function toggleRefundAvailable() public onlyOwner {
        refundAvailable = !refundAvailable;
        emit RefundAvailable(refundAvailable);
    }

    function toggleRaffle() external onlyOwner {
        isRaffleActive = !isRaffleActive;
        emit RaffleOpen(isRaffleActive);
    }
}
