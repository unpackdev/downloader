/*
__/\\\________/\\\_____/\\\\\\\\\\\____/\\\\\\\\\\\\\\\________/\\\\\\\\\_        
 _\///\\\____/\\\/____/\\\/////////\\\_\/\\\///////////______/\\\////////__       
  ___\///\\\/\\\/_____\//\\\______\///__\/\\\_______________/\\\/___________      
   _____\///\\\/________\////\\\_________\/\\\\\\\\\\\______/\\\_____________     
    _______\/\\\____________\////\\\______\/\\\///////______\/\\\_____________    
     _______\/\\\_______________\////\\\___\/\\\_____________\//\\\____________   
      _______\/\\\________/\\\______\//\\\__\/\\\______________\///\\\__________  
       _______\/\\\_______\///\\\\\\\\\\\/___\/\\\\\\\\\\\\\\\____\////\\\\\\\\\_ 
        _______\///__________\///////////_____\///////////////________\/////////__

Visit and follow!

* Website:  https://www.ysec.finance
* Twitter:  https://twitter.com/YearnSecure
* Telegram: https://t.me/YearnSecure
* Medium:   https://yearnsecure.medium.com/

*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./TokenAllocation.sol";

struct PresaleSettings{
    string Name;
    uint256 StartDate;
    uint256 EndDate;
    uint256 Softcap;
    uint256 Hardcap;
    uint256 TokenLiqAmount;
    uint256 LiqPercentage;
    uint256 TokenPresaleAllocation;
    bool PermalockLiq;
    TokenAllocation[] TokenAllocations;
    TokenAllocation LiquidityTokenAllocation;
    address Token;
    string Website;
    string Telegram;
    string Twitter;
    string Github;
    string Medium;
}