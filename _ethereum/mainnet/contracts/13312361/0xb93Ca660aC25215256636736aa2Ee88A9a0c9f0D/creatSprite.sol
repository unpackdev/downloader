// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./NFToken.sol";

contract creatSprite is NFToken {
	string constant SEND_VALUE_IS_NOT_EQ_ISSUEPRICE = "004001";
	string constant MINT_COUNT_IS_BIG_THAN_MAXSUPPLY = "004002";
	string constant CANT_CALL_FROM_CONTRACT = "004003";
	string constant TO_UINT32_OUT_Of_BOUNDS = "004004";
	string constant NOT_START_MINT = "004005";


	uint256 public constant MaxSupply = 10000;  
	uint256 internal constant IssuePrice = 0.01 ether; 

	
	function mint() external payable {
		require(msg.value == IssuePrice, SEND_VALUE_IS_NOT_EQ_ISSUEPRICE);
		require(SpriteCount < MaxSupply, MINT_COUNT_IS_BIG_THAN_MAXSUPPLY);
		require(msg.sender == tx.origin,CANT_CALL_FROM_CONTRACT);
		require(block.timestamp >= 1633910400,NOT_START_MINT);
		SpriteCount += 1;  //ID 1--10000

		uint256 spriteID = SpriteCount;
		bytes32 randSeed  = keccak256(abi.encodePacked(block.coinbase,block.difficulty,block.timestamp,spriteID,gasleft()));
		
		spriteItem memory sp = _creatSpriteItem(randSeed);
		sp.addBlockNum = block.number;
		sp.owner = msg.sender;
		sp.status = 1;
		
		SpriteList[spriteID] = sp;

		addHolderTokens(msg.sender,spriteID);

		OwnerEthBalance += msg.value;

		emit BuySprite(spriteID,IssuePrice,msg.sender,address(0x0));
		emit Transfer(address(0x0),msg.sender,spriteID);
	}

	function _creatSpriteItem(bytes32 randSeed) pure private returns(spriteItem memory sp){
		uint256[7] memory  partCountList = [uint256(7),28,32,32,16,11,20];
											
		sp.attribute.color_1 = uint8(_getRandUint(randSeed,0)%216);
		sp.attribute.color_2 = uint8(_getRandUint(randSeed,2)%216);
		sp.attribute.color_3 = uint8(_getRandUint(randSeed,4)%216);
		sp.attribute.color_4 = uint8(_getRandUint(randSeed,6)%216);
		

		uint256 randTruck = _getRandUint(randSeed,8)%1000;
		if(randTruck>=partCountList[0]-1){
			randTruck = 0;
		}else{
			randTruck += 1;
		}

		sp.body.trunkIndex = uint8(randTruck);


		sp.body.mouthIndex = uint8(_getRandUint(randSeed,10)%partCountList[1]);
		sp.body.headIndex = uint8(_getRandUint(randSeed,12)%partCountList[2]);
		sp.body.eyeIndex = uint8(_getRandUint(randSeed,14)%partCountList[3]);
		sp.body.tailIndex = uint8(_getRandUint(randSeed,16)%partCountList[4]);
		sp.body.colorContainerIndex = uint8(_getRandUint(randSeed,18)%partCountList[5]);

		sp.body.skinColorIndex = uint8(_getRandUint(randSeed,20)%partCountList[6]);

		sp.attribute.space = uint8(_getRandUint(randSeed,22)%51+10);//10~60
		
		sp.attribute.speed = _getRand0to9(randSeed[26])*10+1+_getRand0to9(randSeed[27]); //1-100
		sp.attribute.capacity = _getRand0to9(randSeed[28])*10+1+_getRand0to9(randSeed[29]); //1-100
	}


	function _getRandUint(bytes32 randSeed,uint startAt) pure private returns(uint256 num){
		bytes memory _bytes = abi.encodePacked(randSeed);

		require(_bytes.length >= startAt + 4, TO_UINT32_OUT_Of_BOUNDS);

		assembly {
			num := mload(add(add(_bytes, 0x4), startAt))
		}
		
		return num;
	}
	

	
	function _getRand0to9(bytes1 inputByte) pure private  returns(uint8) {
		uint num = uint8(inputByte)%30;
		uint reNum = 0;

		if(num<15){
			if(num==0){
				reNum = 0;
			}else if (num==1 || num==2){
				reNum = 1;
			}else if (num>=3 && num <=5){
				reNum = 2;
			}else if (num>=6 && num <=9){
				reNum = 3;
			}else{ // 10-15
				reNum = 4;
			}
		}else { // >=15 && < 30 
			if(num==29){
				reNum = 9;
			}else if (num == 27 || num ==28){
				reNum = 8;
			}else if (num>=24 && num <=26){
				reNum = 7;
			}else if (num>=20 && num <=23){
				reNum = 6;
			}else{ // 15-19
				reNum = 5;
			}
		}
		return uint8(reNum);
	}

}