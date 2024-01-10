// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./ERC20Capped.sol";
import "./Pausable.sol";
import "./Ownable.sol";

contract META is ERC20,ERC20Burnable, ERC20Capped, Pausable, Ownable {
    constructor() ERC20("11Metaverse", "11META") ERC20Capped( 3000000000 * 10 ** 18) {
        ERC20._mint(msg.sender, 3000000000 * 10 ** 18);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyOwner{
        _mint(to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual override(ERC20, ERC20Capped) {
        super._mint(account, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}
