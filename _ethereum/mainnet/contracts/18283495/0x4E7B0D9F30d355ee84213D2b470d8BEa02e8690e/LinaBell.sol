/*


LinaBell, inspired by the imaginative realms of Disney, is not just another character – she’s a beacon of curiosity, a
symbol of bold endeavors, and the very embodiment of magical journeys. This dainty pink fox, with her fluffy tail and sparkling eyes, 
invites one and all into a universe where each turn is a surprise and every path holds a new story. 
Join us, as we traverse this enchanting landscape, with LinaBell leading the way, heralding adventures and crafting legends that will be whispered for ages.


https://linabell.tech	
https://t.me/LinaBellOfficialPortal	
https://twitter.com/LinaBell_ERC20

*/



// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract LinaBell is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("LinaBell", unicode"玲娜贝儿") {
        _mint(msg.sender,  10000000000 * (10 ** decimals())); 
    }

}
