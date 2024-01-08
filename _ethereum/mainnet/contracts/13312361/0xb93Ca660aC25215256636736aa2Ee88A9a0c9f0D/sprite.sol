// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import "./spriteStruct.sol";
import "./ownable.sol";
import "./spriteImage.sol";


contract sprite is spriteImage,Ownable {
	string constant CONTRACT_ADDR_MUST_AUTHORIZED = "002001";
	string constant NEW_STATUS_CANT_SMALL_THAN_ONE = "002002";
	string constant NFT_HAS_NOT_CREAT = "002003";

	uint256 public OwnerEthBalance;		

	uint256 internal SpriteCount = 0;		//Number of sprites, starting from 1
	
	mapping(uint256=>spriteItem) public SpriteList; 			
	mapping(address=>bool) public ChangeStatusContract; 		
	
	event AddOffer(uint256 _spriteID,uint256 _auctionType,uint256 _startTime,uint256 _expirationTime,uint256 _price,uint256 _endPrice); 
	event BuySprite(uint256 indexed _spriteID,uint256  _price,address  indexed _buyer,address indexed _seller); 
	event CancelOffer(uint256 _spriteID); 

	
	function ownerWithdraw() external onlyOwner {
		payable(getManageOwner()).transfer(OwnerEthBalance);
		OwnerEthBalance = 0;
	}

	function setChangeStatusContract(address _addr , bool _isAuthorized) onlyOwner external{
		ChangeStatusContract[_addr] = _isAuthorized;
	}
    	
	
	function changeSpriteStatusExt(uint256 _spriteID,uint256 _newStatus,uint256 _expTime) external {
		require(ChangeStatusContract[msg.sender], CONTRACT_ADDR_MUST_AUTHORIZED);
		changeSpriteStatus(_spriteID,_newStatus,_expTime);
	}
	

	
	
	function changeSpriteStatus(uint256 _spriteID,uint256 _newStatus,uint256 _expTime) internal {
		require(_newStatus>=1,NEW_STATUS_CANT_SMALL_THAN_ONE);
		SpriteList[_spriteID].status = uint32(_newStatus);   
		SpriteList[_spriteID].statusExpTime = uint64(_expTime); 
	}

	
	function getSpriteAttribute(uint256 _spriteID)  public view returns(spriteAttribute memory){
	    return SpriteList[_spriteID].attribute;
	}

	
	function getSpriteBody(uint256 _spriteID)  public view returns(spriteBody memory){
	    return SpriteList[_spriteID].body;
	}

	
	function getSpriteStatusAndOwner(uint256 _spriteID)  external view returns(address,uint256){
	    return (SpriteList[_spriteID].owner,getSpriteStatus(_spriteID));
	}

	
	function getSpriteStatus(uint256 _spriteID) public view returns(uint256 status){
	    uint256	expTime = SpriteList[_spriteID].statusExpTime; //uint64 to uint256
		status = SpriteList[_spriteID].status; //uint32 to  uint256

	    if(status>=2 && expTime != 0 && (block.timestamp > expTime)  ){
	    	status = 1; //1 Means free
	    }
	}


	
	function getSpriteImage(uint256 _spriteID) public view returns(bytes memory) {
		address tokenOwner = SpriteList[_spriteID].owner; 
		require(tokenOwner != address(0), NFT_HAS_NOT_CREAT); 

        spriteBody memory sb = SpriteList[_spriteID].body;
        uint8[4] memory colorList = [SpriteList[_spriteID].attribute.color_1,SpriteList[_spriteID].attribute.color_2,SpriteList[_spriteID].attribute.color_3,SpriteList[_spriteID].attribute.color_4]; 
		return getImageCompressData(colorList,sb);
    }


	

}
