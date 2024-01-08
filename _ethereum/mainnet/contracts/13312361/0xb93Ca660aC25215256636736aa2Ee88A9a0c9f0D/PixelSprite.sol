// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import "./creatSprite.sol";


contract pixelSprite is creatSprite {
	string constant BALANCE_IS_ZERO = "005001";
	string constant SPRITE_STATUS_IS_NOT_FREE = "005002";
	string constant END_PRICE_SMALL_THAN_START_PRICE = "005003";
	string constant YOU_ARE_NOT_OWNER = "005004";
	string constant END_DAY_MUST_SMALL_THAN_30DAYS = "005005";
	string constant END_PRICE_MUST_BIG_THAN_ZERO = "005006";
	string constant YOU_CANT_BUY_YOUR_SELF = "005007";
	string constant IT_IS_NOT_FOR_SALE = "005008";
	string constant IT_HAS_EXPIRA = "005009";
	string constant UNKOWN_ERROR = "005010";
	string constant PRICE_ERROR = "005011";
	string constant INSUFFICIENT_BALANCE = "005012";
	string constant AUCTION_TYPE_IS_ERROR = "005013";
	string constant END_DAY_MUST_BIG_THAN_1DAYS = "005014";

	
	mapping(address=>uint256) public UserETHBalance;	
	
	struct offer{
		bool 	isForSale;			//Sale status
		uint8 	auctionType;		//Auction type 0 is fixed bid 1 is decreasing in time
		uint32 	startTime;		
		uint32 	expirationTime;	
		address seller;			
		
		uint256 price;				//Selling price, initial price
		uint256 endPrice;			
	}

	mapping(uint256=>offer) public OfferList; 
	
	
	
	function userWithdrawETH()public {
		require(UserETHBalance[msg.sender]>0,BALANCE_IS_ZERO); 

		uint256 sendValue = UserETHBalance[msg.sender]; 
		
		UserETHBalance[msg.sender] = 0; 

		payable(msg.sender).transfer(sendValue); 	
	}
	

	
	function sellWithFixPrice(uint256 _price,uint256 _spriteID) public {
		require(getSpriteStatus(_spriteID)==1, SPRITE_STATUS_IS_NOT_FREE); 
		require(msg.sender ==  SpriteList[_spriteID].owner ,YOU_ARE_NOT_OWNER); 

		changeSpriteStatus(_spriteID,2,0); 
		OfferList[_spriteID] = offer(true,0,uint32(block.timestamp),0,msg.sender,_price,0);
		
		emit AddOffer(_spriteID,0,block.timestamp,0,_price,0);
	}

	function sellWithEndPrice(uint256 _price,uint256 _endPrice,uint256 _spriteID,uint256 _endDay) public {
		require(_endPrice<_price,END_PRICE_SMALL_THAN_START_PRICE);
		require(getSpriteStatus(_spriteID)==1, SPRITE_STATUS_IS_NOT_FREE); 
		require(msg.sender ==  SpriteList[_spriteID].owner ,YOU_ARE_NOT_OWNER);

		require(_endDay<=30,END_DAY_MUST_SMALL_THAN_30DAYS); 
		require(_endDay>0,END_DAY_MUST_BIG_THAN_1DAYS); 
		require(_endPrice>0,END_PRICE_MUST_BIG_THAN_ZERO); 

		uint256 endTime = block.timestamp+_endDay*86400;
		
		changeSpriteStatus(_spriteID,3,endTime); 
		
		OfferList[_spriteID] = offer(true,1,uint32(block.timestamp),uint32(endTime),msg.sender,_price,_endPrice);
	
		emit AddOffer(_spriteID,1,block.timestamp,endTime,_price,_endPrice);
	}

	

	function buySprite(uint256 _spriteID,uint256 _price) payable  public{
		address seller = OfferList[_spriteID].seller;

		require(msg.sender !=  seller ,YOU_CANT_BUY_YOUR_SELF);
		require(OfferList[_spriteID].isForSale,IT_IS_NOT_FOR_SALE);
		
	
		if(OfferList[_spriteID].auctionType == 0 ){ //Fixed bid
			_buyWithFixPrice(_price,_spriteID,seller);
		}else{//Dutch auction
			_buyWithEndPrice(_price,_spriteID,seller);
		}
	
		emit BuySprite(_spriteID,_price,msg.sender,seller);

		emit Transfer(seller,msg.sender,_spriteID);
	}
	

	
	function _buyWithFixPrice(uint256 _price,uint256 _spriteID,address seller) internal {
		require(seller == SpriteList[_spriteID].owner,UNKOWN_ERROR);
		
		require(_price == OfferList[_spriteID].price,PRICE_ERROR); 
		
		UserETHBalance[msg.sender] += msg.value; 

		require(UserETHBalance[msg.sender] >= _price,INSUFFICIENT_BALANCE);
		
		UserETHBalance[seller] += _getValueBySubTransFee(_price);

		UserETHBalance[msg.sender] -= _price;	

        changeSpriteStatus(_spriteID,1,0); 
		changeOwner(_spriteID,msg.sender);  

		
		delete(OfferList[_spriteID]);
	}

	
	function _buyWithEndPrice(uint256 _price,uint256 _spriteID,address seller) internal  {
		require(seller == SpriteList[_spriteID].owner,UNKOWN_ERROR);

		require(OfferList[_spriteID].expirationTime > block.timestamp,IT_HAS_EXPIRA);

		require(_price >= getAuctionPrice(_spriteID),PRICE_ERROR);

		UserETHBalance[msg.sender] += msg.value;

		require(UserETHBalance[msg.sender] >= _price,INSUFFICIENT_BALANCE);
		
		UserETHBalance[seller] += _getValueBySubTransFee(_price);
		UserETHBalance[msg.sender] -= _price;
        
		changeSpriteStatus(_spriteID,1,0);
		changeOwner(_spriteID,msg.sender);

		delete(OfferList[_spriteID]); 
	}

	function cancelOffer(uint256 _spriteID) external {
		address seller = OfferList[_spriteID].seller;

		require(msg.sender ==  seller ,YOU_ARE_NOT_OWNER);
		require(OfferList[_spriteID].isForSale,IT_IS_NOT_FOR_SALE);
		
		if(OfferList[_spriteID].auctionType == 1){ //Can only be cancelled before expiration
			require(OfferList[_spriteID].expirationTime > block.timestamp,IT_HAS_EXPIRA);
		}

		changeSpriteStatus(_spriteID,1,0);
		
		delete(OfferList[_spriteID]);

		emit CancelOffer(_spriteID);
	}

	function _getValueBySubTransFee(uint256 _price) internal returns(uint256)  {
		uint256 fee = _price*5/100;
		OwnerEthBalance += fee;
		return _price-fee;
	}

	function getAuctionPrice(uint256 _spriteID) public view returns(uint256){
		require(OfferList[_spriteID].expirationTime >= block.timestamp,IT_HAS_EXPIRA); 

		require(OfferList[_spriteID].isForSale,IT_IS_NOT_FOR_SALE);
		require(OfferList[_spriteID].auctionType == 1,AUCTION_TYPE_IS_ERROR);

		uint256 duration = OfferList[_spriteID].expirationTime - OfferList[_spriteID].startTime;

		uint256 hasPassed = block.timestamp-OfferList[_spriteID].startTime;

		uint256 totalChange =  OfferList[_spriteID].price - OfferList[_spriteID].endPrice;

      	uint256 currentChange = totalChange * hasPassed / duration;

      	uint256 currentPrice = OfferList[_spriteID].price - currentChange;
		return currentPrice;
	}
}