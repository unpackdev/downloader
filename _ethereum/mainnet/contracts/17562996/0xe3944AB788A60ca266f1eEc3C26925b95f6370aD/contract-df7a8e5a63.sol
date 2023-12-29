// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./Ownable.sol";

contract PrecipitateAI is ERC20, Ownable {
    constructor() ERC20("Precipitate.AI", "RAIN") {
        _mint(msg.sender, 1000000000 * 10 ** decimals());
    }
}
