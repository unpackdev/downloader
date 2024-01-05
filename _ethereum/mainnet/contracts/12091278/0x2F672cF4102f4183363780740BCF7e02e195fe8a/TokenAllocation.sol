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

struct TokenAllocation
{
    string Name;
    uint256 Amount;
    uint256 RemainingAmount;
    uint256 ReleaseDate;
    bool IsInterval;
    uint256 PercentageOfRelease;
    uint256 IntervalOfRelease;
    bool Exists;
    address Token;
}