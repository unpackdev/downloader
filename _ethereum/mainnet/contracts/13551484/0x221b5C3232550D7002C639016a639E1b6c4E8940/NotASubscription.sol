// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "./Ownable.sol";
import "./IERC20.sol";
import "./NotAStake.sol";

contract NotASubscription is Ownable {
    
    struct Sub {
        uint level;
        uint validUntil;
    }

    mapping (address => Sub) public subscriptions;
    mapping (uint => uint) public prices;
    mapping (address => mapping(uint => uint)) lastWithdraw;

    uint constant BRONZE = 1;
    uint constant SILVER = 2;
    uint constant GOLD = 3;
    uint constant DIAMOND = 4;

    IERC20 public COIN;
    NotAStake public STAKE;

    constructor(){
        prices[BRONZE] = 774 ether;
        prices[SILVER] = 3720 ether;
        prices[GOLD] = 7440 ether;
        prices[DIAMOND] = 11160 ether;
    }

    function setPrice(uint lvl, uint price) public onlyOwner{
        prices[lvl] = price;
    }

    function buySubscription(uint lvl, uint months_) public {
        uint price = prices[lvl] * months_;
        require(price > 0, "level not found or zero months");
        require(COIN.balanceOf(_msgSender()) >= price, "insufficient funds");
        COIN.buy(price);
        Sub memory sub = subscriptions[_msgSender()];
        uint dateV = (sub.validUntil > block.timestamp && lvl <= sub.level) ? sub.validUntil : block.timestamp;
        subscriptions[_msgSender()] = Sub(lvl, dateV + (30 days * months_));
    }
  
    function getProfits(address operator, uint tokenId) public view returns(uint) {
        (,uint IStakeTime, uint ILastWithdraw) = STAKE.owners(operator,tokenId);
        (bool active, uint tokensHour,) = STAKE.operators(operator);
        if(!active || IStakeTime == 0){
            return 0;
        }
        uint lWithdraw = IStakeTime > ILastWithdraw ? IStakeTime : ILastWithdraw;
        lWithdraw = lWithdraw > lastWithdraw[operator][tokenId] ? lWithdraw : lastWithdraw[operator][tokenId];
        uint stakeTime = (block.timestamp - lWithdraw) / 1 hours;
        return stakeTime * tokensHour;
    }

    function withdraw(address operator) public {
        uint[] memory tokenIds = STAKE.getAssetsByHolder(operator, _msgSender());
        uint tNull = 9999999999;
        require(tokenIds.length > 0, "NOT OWNER");
        for(uint i=0; i<tokenIds.length;i++){
            uint tokenId = tokenIds[i];
            if(tokenId != tNull){
                _withdraw(operator, tokenId);
            }
        }
    }

    function withdraw(address operator, uint[] calldata tokenIds) public {
        for(uint i=0; i<tokenIds.length;i++){
            uint tokenId = tokenIds[i];
            _withdraw(operator, tokenId);
        }
    }
    
    function _withdraw(address operator, uint tokenId) private {
        (address IOwner,,) = STAKE.owners(operator,tokenId);
         require(IOwner == _msgSender(), "NOT OWNER");
         (bool active,, address tokenAddress) = STAKE.operators(operator);
         uint profits = getProfits(operator, tokenId);
         if(profits == 0){
             return;
         }
         require(tokenAddress != address(0), "NO ERC20 SETUP");
         require(active, "PAUSED");
         IERC20 Coin = IERC20(tokenAddress);
         lastWithdraw[operator][tokenId] = block.timestamp;
         Coin.transferFrom(Coin.owner(), _msgSender(), profits);
    }

    function setStake(address newAddress) public onlyOwner {
        STAKE = NotAStake(newAddress);
    }
    
    function setCoin(address newAddress) public onlyOwner {
        COIN = IERC20(newAddress);
    }
}