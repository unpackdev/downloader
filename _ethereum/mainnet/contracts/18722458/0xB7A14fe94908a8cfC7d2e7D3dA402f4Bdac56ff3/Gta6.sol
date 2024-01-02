// SPDX-License-Identifier: MIT
/**
 * GTA6 Token. For the gamers.
 * https://twitter.com/RockstarGames/status/1732037140111102460
*/
pragma solidity ^0.8.19;

import "./Context.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./ERC20.sol";

contract Gta6 is ERC20, Ownable {
    uint256 private _totalSupply = 1000000000 * (10 ** 18);

    constructor() ERC20("GTA6", "GTA6") {
        _mint(msg.sender, _totalSupply);
    }

}
