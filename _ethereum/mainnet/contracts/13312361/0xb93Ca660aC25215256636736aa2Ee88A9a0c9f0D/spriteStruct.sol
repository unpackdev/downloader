// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct spriteAttribute{
	uint8 speed;	 				
	uint8 capacity;  				
	uint8 space;	 				//Affect the size of the production canvas  10~60
	uint8 color_1;
	uint8 color_2;
	uint8 color_3;
	uint8 color_4;
}

struct spriteBody{
	uint8 trunkIndex;  				
	uint8 mouthIndex; 				
	uint8 headIndex;  				
	uint8 eyeIndex;   				
	uint8 tailIndex;  				
	uint8 colorContainerIndex;		
	uint8 skinColorIndex; 			
}

struct spriteItem {
	uint32	status;  				//Sprite state 0: not created, 1:idle,2:Fixed bid transaction,3:Dutch auction 4:production
	uint64 	statusExpTime; 			
	address owner;					
	uint256 addBlockNum;			
	
	spriteAttribute attribute; 		
	spriteBody  body;				
}

