// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

error InsufficientPayment();
error SubscriptionPeriod();

contract BotSubscription {
    string public name;
    address private owner;
    uint256 public price = 100000000000000000;
    uint256 public priceGraphic = 250000000000000000;

    uint256 constant OneMonth = 2592000;

    mapping(uint256 => uint256) public serverAccess;
    mapping(uint256 => bool) public serverGraphics;

    constructor(){
        name = "3gm Bot Access @3gmdev";
        owner = msg.sender;
    }

    function subscribe3gmBot(uint256 discordServerId, uint256 months) external payable {
        if (months == 0 || months > 12) revert SubscriptionPeriod();

        unchecked{
            if(msg.value != price * months) revert InsufficientPayment();
            
            // Log the subscription period
            if (block.timestamp < serverAccess[discordServerId]){
                // Add to existing subscription
                serverAccess[discordServerId] += OneMonth * months;
            }
            else {
                // Create subscription
                serverAccess[discordServerId] = block.timestamp + OneMonth * months;
            }
        }
    }

    function purchase3gmGraphic(uint256 discordServerId) external payable{
        if(msg.value != priceGraphic) revert InsufficientPayment();

        // Log the purchase
        serverGraphics[discordServerId] = true;
    }

    function admin_serverAccessEdit(uint256[] calldata serverIds, uint256[] calldata newSubscriptionTime) external {
        if (msg.sender != owner) revert();

        for(uint256 i; i < serverIds.length;){
            serverAccess[serverIds[i]] = newSubscriptionTime[i];
            unchecked{
                ++i;
            }
        }
    }

    function admin_serverGraphicEdit(uint256[] calldata serverIds, bool[] calldata stateChange) external {
        if (msg.sender != owner) revert();

        for(uint256 i; i < serverIds.length;){
            serverGraphics[serverIds[i]] = stateChange[i];
            unchecked{
                ++i;
            }
        }
    }

    function admin_setPrices(uint256 newPrice, uint256 newPriceGraphic) external {
        if (msg.sender != owner) revert();

        price = newPrice;
        priceGraphic = newPriceGraphic;
    }

    function admin_changeOwner(address newOwner) external {
        if (msg.sender != owner) revert();
        
        owner = newOwner;
    }

    function admin_withdraw(uint256 amount) external {
        if (msg.sender != owner) revert();

        if(amount == 0) msg.sender.call{value : address(this).balance}("");
        else msg.sender.call{value : amount}("");
    }
}