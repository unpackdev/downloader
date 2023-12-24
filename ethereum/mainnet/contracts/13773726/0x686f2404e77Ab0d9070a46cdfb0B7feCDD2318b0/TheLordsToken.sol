// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./ERC20Snapshot.sol";
import "./ERC20Capped.sol";
import "./Ownable.sol";
import "./Pausable.sol";

contract TheLordsToken is
    ERC20,
    ERC20Burnable,
    ERC20Snapshot,
    ERC20Capped,
    Ownable,
    Pausable
{
    constructor(uint256 _cap) ERC20("Lords", "LORDS") ERC20Capped(_cap) {}

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

    function _mint(address account, uint256 amount)
        internal
        override(ERC20, ERC20Capped)
        whenNotPaused
    {
        super._mint(account, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Snapshot) whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }
}
