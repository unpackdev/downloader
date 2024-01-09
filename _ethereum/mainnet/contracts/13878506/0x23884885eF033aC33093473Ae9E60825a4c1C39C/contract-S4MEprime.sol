// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./ERC20Snapshot.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./ERC20FlashMint.sol";

/// @custom:security-contact s4me@sim4ple.io
   
contract Sim4pleS4MEPrime is ERC20, ERC20Burnable, ERC20Snapshot, Ownable, Pausable, ERC20FlashMint {
    constructor() ERC20("sim4ple S4ME prime", "4ME") {
        _mint(msg.sender, 10000000000 * 10 ** decimals());
    }

    function snapshot() public onlyOwner {
        _snapshot();
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
        override(ERC20, ERC20Snapshot)
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}
