// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20Upgradeable.sol";
import "./Initializable.sol";

contract NEXXO is Initializable, ERC20Upgradeable {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() public initializer {
        __ERC20_init("NEXXO", "NEXXO");

        _mint(msg.sender, 100000000000 * 10**decimals());
    }
}
