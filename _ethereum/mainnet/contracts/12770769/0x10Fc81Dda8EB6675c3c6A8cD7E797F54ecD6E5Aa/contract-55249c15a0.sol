// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./ERC20Snapshot.sol";
import "./Ownable.sol";
import "./draft-ERC20Permit.sol";

contract MRNAVaccines is ERC20, ERC20Burnable, ERC20Snapshot, Ownable, ERC20Permit {
    constructor() ERC20("mRNA Vaccines", "MRNA") ERC20Permit("mRNA Vaccines") {
        _mint(msg.sender, 666666666666000000000000000000 * 1 ** decimals());
    }

    function snapshot() public onlyOwner {
        _snapshot();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20, ERC20Snapshot)
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}
