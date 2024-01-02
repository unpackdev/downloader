// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./Freezable.sol";

contract Gobubblefong is ERC20, ERC20Burnable, Pausable, Ownable, Freezable {
    constructor() ERC20("Gobubblefong", "GOBF") {
        _mint(msg.sender, 100000000 * 10 ** decimals());
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function freeze(address account) public onlyOwner {
        _freeze(account);
    }

    function unfreeze(address account) public onlyOwner {
        _unfreeze(account);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        whenNotFrozen(from)
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}

