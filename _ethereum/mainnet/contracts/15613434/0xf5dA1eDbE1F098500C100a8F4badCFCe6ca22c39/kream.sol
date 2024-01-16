// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./Pausable.sol";
import "./Ownable.sol";

/// @custom:security-contact security@kreamteamx.com
contract Kream is ERC20, Pausable, Ownable {
    constructor() ERC20("Kream", "KREAM") {
        _mint(msg.sender, 69000000 * 10 ** decimals());
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}
