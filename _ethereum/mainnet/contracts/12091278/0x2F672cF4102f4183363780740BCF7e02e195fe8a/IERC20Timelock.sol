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

interface IERC20Timelock{
    function AllocationLength() external view returns (uint256);
    function AddAllocation(string memory name, uint256 amount, uint256 releaseDate, bool isInterval, uint256 percentageOfRelease, uint256 intervalOfRelease, address token) external;
    function WithdrawFromAllocation(string memory name) external;
}