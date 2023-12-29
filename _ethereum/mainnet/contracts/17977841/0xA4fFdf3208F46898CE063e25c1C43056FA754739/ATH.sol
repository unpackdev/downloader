// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./ERC20Capped.sol";
import "./Ownable.sol";

/*
           __              __
           \ `-._......_.-` /
            `.  '.    .'  .'
             //  _`\/`_  \\
            ||  /\O||O/\  ||
            |\  \_/||\_/  /|
            \ '.   \/   .' /
            / ^ `'~  ~'`   \
           /  _-^_~ -^_ ~-  |
           | / ^_ -^_- ~_^\ |
           | |~_ ^- _-^_ -| |
           | \  ^-~_ ~-_^ / |
           \_/;-.,____,.-;\_/
       =======(_(_(==)_)_)========

    ==================================
*/

contract AthenaDAOToken is ERC20, ERC20Burnable, ERC20Capped, Ownable {
    constructor() ERC20("AthenaDAO Token", "ATH") ERC20Capped(100_000_000 ether) {}

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual override(ERC20, ERC20Capped) {
        super._mint(account, amount);
    }
}
