
/*
Flipping the Future, One Meme at a Time!

ǝdǝd
Welcome to the most unconventional, out-of-the-box, and downright wacky project in the crypto universe – ǝdǝd (ǝdǝd)!
Picture this: an upside-down Pepe meme as the face of our project! Why, you ask? 
Because life’s too short not to have a good laugh, and the crypto space could use a bit more humor.
At ǝdǝd (ǝdǝd), we believe in the power of laughter and the resilience of our community. 
Even when the markets are as topsy-turvy as our logo, we’ve got the energy to turn things around.
*/
//  https://ededcoin.com
//  https://t.me/ededOfficialPortal
//  https://twitter.com/eded_ERC20


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20.sol";
import "./Ownable.sol";

contract eded is ERC20 {
    constructor() ERC20(unicode"ǝdǝd", unicode"ǝdǝd") { 
        _mint(msg.sender, 420_690_000 * 10**18);
    }
}