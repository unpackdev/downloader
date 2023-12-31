/*

WEBSITE:    friendtok.app
TELEGRAM:   t.me/FriendTokOfficialPortal
TWITTER:    twitter.com/FriendTok_
WHITEPAPER: friendtok.app/wp-content/uploads/2023/09/Whitepaper.pdf
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

contract FRIENDTOK is ERC20 {
    constructor() ERC20("Friend Tok", "FTOK") {
        _mint(msg.sender, 100_000_000 * 10**18);
    }
}