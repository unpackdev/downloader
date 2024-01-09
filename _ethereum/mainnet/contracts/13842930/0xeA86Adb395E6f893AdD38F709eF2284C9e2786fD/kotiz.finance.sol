// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Pausable.sol";
import "./Ownable.sol";

/// @custom:security-contact security@kotiz.finance
contract KotizFinance is ERC20, ERC20Burnable, Pausable, Ownable {
    constructor() ERC20("kotiz.finance", "KOFI") {
        _mint(msg.sender, 10000000000000000 * 10 ** decimals());
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

    function decimals() public view virtual override returns (uint8) {
        return 2;
    }
}
