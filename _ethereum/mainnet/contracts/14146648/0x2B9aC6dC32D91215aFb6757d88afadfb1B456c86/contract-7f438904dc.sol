// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./ERC20Snapshot.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./draft-ERC20Permit.sol";

/// @custom:security-contact office@wyrebitcoin.com
contract WyreBitcoin is ERC20, ERC20Burnable, ERC20Snapshot, Ownable, Pausable, ERC20Permit {
    constructor() ERC20("WyreBitcoin", "WyBTC") ERC20Permit("WyreBitcoin") {}

    function snapshot() public onlyOwner {
        _snapshot();
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
        override(ERC20, ERC20Snapshot)
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}
