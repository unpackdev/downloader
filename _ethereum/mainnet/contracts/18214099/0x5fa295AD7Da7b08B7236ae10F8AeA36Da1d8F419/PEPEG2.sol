// SPDX-License-Identifier: MIT
// https://pepegalactic.xyz/
// https://t.me/pepegalacticforthecommunity
// https://twitter.com/PepeGalactic
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./Ownable.sol";

contract PEPEGALACTIC is ERC20, Ownable {
    constructor() ERC20("PEPEGALACTIC", "PEPEG") {
        _mint(msg.sender, 1000000000000 * 10 ** decimals());
    }
}
