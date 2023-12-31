// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./ERC20FlashMint.sol";

/// @custom:security-contact info@conmodum.com
contract ConmodumBank is ERC20, ERC20Burnable, Pausable, Ownable, ERC20FlashMint {
    constructor() ERC20("Conmodum Bank", "CBGT") {
        _mint(msg.sender, 500000000000 * 10 ** decimals());
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
}
