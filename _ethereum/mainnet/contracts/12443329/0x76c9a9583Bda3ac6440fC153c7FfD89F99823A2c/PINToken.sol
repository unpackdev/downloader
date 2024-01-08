// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./ERC20Snapshot.sol";
import "./Ownable.sol";
import "./draft-ERC20Permit.sol";

contract PINToken is ERC20, ERC20Snapshot, Ownable, ERC20Permit {
    constructor() ERC20("Pinjour", "PIN") ERC20Permit("Pinjour") {
        _mint(msg.sender, 10000000 * 10 ** decimals());
    }

    function snapshot() public onlyOwner {
        _snapshot();
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20, ERC20Snapshot)
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}
