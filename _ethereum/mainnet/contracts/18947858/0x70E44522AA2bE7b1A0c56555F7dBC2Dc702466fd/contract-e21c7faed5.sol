// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

/// @custom:security-contact https://t.me/PLUTOPORTALS
contract PLUTO is ERC20, ERC20Burnable, Ownable {
    constructor(address initialOwner)
        ERC20("PLUTO", "PLUTO")
        Ownable(initialOwner)
    {
        _mint(msg.sender, 100000000 * 10 ** decimals());
    }
}
/// https://twitter.com/PLUTOERC2/status/1743590334045544891?t=vNw58aflSR_H6sv0d8ECNw&s=19
///https://www.pluto-token.com/