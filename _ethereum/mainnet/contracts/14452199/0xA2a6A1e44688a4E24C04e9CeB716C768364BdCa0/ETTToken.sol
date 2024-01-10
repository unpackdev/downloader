// SPDX-License-Identifier: MIT

// Created by 256bit Labs

pragma solidity ^0.8.4;

import "ERC20.sol";
import "Pausable.sol";
import "Ownable.sol";

/// @custom:security-contact 256bitio@gmail.com
contract ExtraterrestrialTouristsToken is ERC20, Pausable, Ownable {
    constructor() ERC20("Extraterrestrial Tourists Token", "ETTT") {
        // Total supply of 1 billion
        _mint(msg.sender, 1000000000 * 10**decimals());
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }
}
