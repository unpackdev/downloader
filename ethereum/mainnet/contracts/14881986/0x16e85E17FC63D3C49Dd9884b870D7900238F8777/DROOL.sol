// SPDX-License-Identifier: MIT

/* 
                                                  
@@@@@@@   @@@@@@@    @@@@@@    @@@@@@   @@@       
@@@@@@@@  @@@@@@@@  @@@@@@@@  @@@@@@@@  @@@       
@@!  @@@  @@!  @@@  @@!  @@@  @@!  @@@  @@!       
!@!  @!@  !@!  @!@  !@!  @!@  !@!  @!@  !@!       
@!@  !@!  @!@!!@!   @!@  !@!  @!@  !@!  @!!       
!@!  !!!  !!@!@!    !@!  !!!  !@!  !!!  !!!       
!!:  !!!  !!: :!!   !!:  !!!  !!:  !!!  !!:       
:!:  !:!  :!:  !:!  :!:  !:!  :!:  !:!   :!:      
 :::: ::  ::   :::  ::::: ::  ::::: ::   :: ::::  
:: :  :    :   : :   : :  :    : :  :   : :: : :  
                                                
*/

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC20Burnable.sol";
import "./Math.sol";

contract DROOL is ERC20Burnable, Ownable {
  constructor() ERC20("Drool", "DROOL") {
    _mint(msg.sender, 69420000 ether);
  }
}