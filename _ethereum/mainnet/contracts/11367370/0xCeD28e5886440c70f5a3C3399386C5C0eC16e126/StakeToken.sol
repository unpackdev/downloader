// SPDX-License-Identifier: MIT
pragma solidity ^0.5.5;

import "./ERC20.sol";
import "./ERC20Detailed.sol";
import "./ERC20Pausable.sol";
import "./ERC20Mintable.sol";


contract StakeToken is ERC20, ERC20Detailed, ERC20Pausable, ERC20Mintable {
    constructor(uint256 initialSupply) ERC20Detailed("Guarda Reward Token", "grETH", 18) public {
        _mint(msg.sender, initialSupply);
    }

    function multiMint ( address[] memory recipients, uint256[] memory amounts) public onlyMinter returns (bool) {
        require(recipients.length == amounts.length);
        for (uint i = 0; i < recipients.length; ++i) {
            _mint(recipients[i], amounts[i]);
        }
        return true;
    }
}
