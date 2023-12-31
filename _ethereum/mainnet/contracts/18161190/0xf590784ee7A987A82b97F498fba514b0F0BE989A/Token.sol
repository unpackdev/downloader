// SPDX-License-Identifier: MIT
/**
yea ah I love bananas
I eat bananas any kind of way
Now we can say we've turned ice cream
Into a healthy snack
With vitamins and Potassium
It's such a flavorful hack
You need to know it's your duty
To spread the news far and wide
I want the world to get fruity
And I need you by my side
https://www.youtube.com/watch?v=zkEtLRI45KsOoh
**/

pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract BananaSong is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("Banana Song", unicode"БАН") {
        _mint(msg.sender,  10000000 * (10 ** decimals())); 
    }
}
