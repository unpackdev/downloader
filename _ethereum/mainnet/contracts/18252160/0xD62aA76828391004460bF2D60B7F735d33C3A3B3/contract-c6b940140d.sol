// SPDX-License-Identifier: MIT

/*

“Show me the tendies, everybody.” - Keith Gill, 2021 & in Dumb Money: The Movie.

Tendies is a synonym for juicy gains.

Telegram: https://t.me/showmethetendies
Twitter: https://x.com/showmethetendies
Website: https://showmethetendies.com

0/0 tax, LP burned and renounced ownership!

Original quote: https://youtu.be/jKhzbiZknk4?si=_6UPKUamPP__NeV0

Movie appearance: https://youtu.be/Y__076nqvgc?si=AMnTJA0yQBczX6Ev

 _______  _______  __    _  ______   ___  _______ 
|       ||       ||  |  | ||      | |   ||       |
|_     _||    ___||   |_| ||  _    ||   ||    ___|
  |   |  |   |___ |       || | |   ||   ||   |___ 
  |   |  |    ___||  _    || |_|   ||   ||    ___|
  |   |  |   |___ | | |   ||       ||   ||   |___ 
  |___|  |_______||_|  |__||______| |___||_______|

*/

pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./ERC20Snapshot.sol";
import "./Ownable.sol";

/// @custom:security-contact showmethetendies@gmail.com
contract ShowMeTheTendies is ERC20, ERC20Burnable, ERC20Snapshot, Ownable {
    constructor() ERC20("Show Me The Tendies", "TENDIE") {
        _mint(msg.sender, 1000000000 * 10 ** decimals());
    }

    function snapshot() public onlyOwner {
        _snapshot();
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20, ERC20Snapshot)
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}
