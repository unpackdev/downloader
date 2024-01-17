// SPDX-License-Identifier: MIT

//   _  __             _                    
//  | |/ /__ _ ___ ___(_) ___  _ __   __ _  
//  | ' // _` / __/ __| |/ _ \| '_ \ / _` | 
//  | . \ (_| \__ \__ \ | (_) | | | | (_| | 
//  |_|\_\__,_|___/___/_|\___/|_| |_|\__,_| 

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./kassiona_body.sol";
import "./kassiona_head.sol";
import "./kassiona_tickets.sol";

contract KassionaCave is Ownable {

    event Play(address indexed player, bool indexed isWin);
    
    uint256 public randomNonce = 0;
    
    mapping(address => bool) public whiteList;
    mapping(address => uint) private mintedPerAddress;

    KassionaBody bodyContract;
    KassionaHead headContract;
    KassionaChips ticketContract;

    constructor(KassionaHead headAddr_,KassionaBody bodyAddr_,KassionaChips ticketAddr_) {
        bodyContract = bodyAddr_;
        headContract = headAddr_;
        ticketContract = ticketAddr_;
    }

    function play(uint256 headTokenId) external {
        require(headContract.ownerOf(headTokenId)==msg.sender,"It is not your token");
        require(ticketContract.balanceOf(msg.sender,1) > 0,"Need ticket to play");
        require(block.timestamp > headContract.publicSaleTime() + 2 days, "Not start yet");

        ticketContract.burn(msg.sender,1,1);

        if(_random()%10<7) {
            emit  Play(_msgSender(), true);
            bodyContract.mint(_msgSender(), headContract.tokenRarity(headTokenId));
        }else {
            emit  Play(_msgSender(), false);
        }
    }

    function _random() private returns (uint256){
        return uint256(keccak256(abi.encodePacked(block.timestamp,block.difficulty,randomNonce++)));
    }
  
}