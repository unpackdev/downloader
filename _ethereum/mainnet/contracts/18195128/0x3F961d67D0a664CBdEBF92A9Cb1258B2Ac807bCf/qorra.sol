// SPDX-License-Identifier: MIT

/// Company: Qorra Pty Ltd 
/// @title Qorra
/// @author Qorra

pragma solidity ^0.8.18;

import "./ERC20.sol";
import "./Ownable.sol";

contract Qorra is ERC20, Ownable {
    address constant PINKSALE_FACTORY_ADDRESS = 0x5f9322b5a8E24D891061dfA6698D36578c8Aa35f;
    address constant PINKLOCK_LOCKUP_ADDRESS = 0x71B5759d73262FBb223956913ecF4ecC51057641;

    constructor() ERC20("Qorra", "PQOR") {
        _mint(_msgSender(), 100_000_000 * 10 ** 18);
    }

    // Check if a given address is one of the hardcoded excluded addresses
    function isExcludedAddress(address account) external pure returns (bool) {
        return account == PINKSALE_FACTORY_ADDRESS || account == PINKLOCK_LOCKUP_ADDRESS;
    }
}
