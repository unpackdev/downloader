// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./Address.sol";
import "./BaseAuctionReceiver.sol";
import "./DragonToken.sol";

contract DragonMarket is BaseAuctionReceiver {
    
    using SafeMath for uint;
    using Address for address payable;

    uint constant WEI_MIN_PRICE = 1e15; //0,001 eth 
    uint constant HOURS_MAX_PERIOD = 24 * 100; //100 days

    event TokenBought(
        uint tokenId, 
        uint weiAmount, 
        address indexed newOwner,
        uint weiHolderAmount, 
        uint weiFeesAmount, 
        address indexed oldOwner);

    constructor(address accessControl, address dragonToken, uint fees100) 
    BaseAuctionReceiver(accessControl, dragonToken, fees100) {
    }

    function weiMinPrice() internal override virtual pure returns (uint) {
        return WEI_MIN_PRICE;
    }

    function maxTotalPeriod() internal override virtual pure returns (uint) {
        return HOURS_MAX_PERIOD;
    }

    function buy(uint tokenId) external payable whenLocked(tokenId) {
        require(msg.value >= priceOf(tokenId), 
            "DragonMarket: incorrect amount sent to the contract");
        require(holderOf(tokenId) != _msgSender(), 
            "DragonMarket: a token holder cannot buy own token. Use the method withdraw instead.");

        address holder = holderOf(tokenId);

        _unlock(tokenId);
        delete _priceSettings[tokenId];

        DragonToken(tokenContract())
            .safeTransferFrom(address(this), msg.sender, tokenId);

        uint weiFeesAmount = calcFees(msg.value, feesPercent());
        uint weiHolderAmount = msg.value.sub(weiFeesAmount);
        
        payable(holder).sendValue(weiHolderAmount);

        emit TokenBought(
            tokenId, msg.value, msg.sender, 
            weiHolderAmount, weiFeesAmount, holder);
    }
}