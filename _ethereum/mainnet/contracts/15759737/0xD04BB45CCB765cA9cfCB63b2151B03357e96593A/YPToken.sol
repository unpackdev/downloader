// SPDX-License-Identifier: MIT
// @title: YACHT PUNKZ
// @author: yachtpunkz.com
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@k;;;;;;;;;;;;;;;;;;;;R@@@@@@@@@@@@@@@@
// @@@@@@@@@@S!,                    :!K@@@@@@@@@@@@@@
// @@@@@@@@y+'                        y@@@@@@@@@@@@@@
// @@@@@@@@=                          y@@@@@@@@@@@@@@
// @@@@@@@@=                          y@@@@@@@@@@@@@@
// @@@@@@@@=                          y@@@@@@@@@@@@@@
// @@@@@@@@=                          y@@@@@@@@@@@@@@
// @@@@@@@@=                          y@@@@@@@@@@@@@@
// @@@@@@@@=                          y@@@@@@@@@@@@@@
// @@@@@@@@=                          y@@@@@@@@@@@@@@
// @@@@@@@@j^'                        y@@@@@@@@@@@@@@
// @@@@@@@@@@i                        y@@@@@@@@@@@@@@
// @@@@@@@@@@i                        y@@@@@@@@@@@@@@
// @@@@@@@@@@i `'`                    y@@@@@@@@@@@@@@
// @@@@@@@@@@i ~z^`                 ',k@@@@@@@@@@@@@@
// @@@@@@@@@@i .~~~,              .'K@@@@@@@@@@@@@@@@
// @@@@@@@@@@i .~~~~~~~,  ````````%@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@i .~~~~~~~, `@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@i .~~~~~~~: .@@@@@@@@@@@@@@@@@@@@@@@@@@@

pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./draft-ERC20Permit.sol";
import "./ERC20Votes.sol";

contract YPToken is ERC20, ERC20Burnable, Pausable, Ownable, ERC20Permit, ERC20Votes {
    constructor() ERC20("Yacht Punkz Token", "YCHT") ERC20Permit("Yacht Punkz Token") {
        _mint(msg.sender, 69420 * 10 ** decimals());
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    // The following functions are overrides required by Solidity.

    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._burn(account, amount);
    }
}
