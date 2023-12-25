// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

/// @custom:security-contact otaconai@proton.me
contract Otacon is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("Otacon", "OTACON") {
        _mint(msg.sender, 100000000 * 10 ** decimals());
    }
}
