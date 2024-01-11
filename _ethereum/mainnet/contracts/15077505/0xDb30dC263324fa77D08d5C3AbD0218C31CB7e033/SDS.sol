// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./ERC20Burnable.sol";

contract ThreeGreatPowers is ERC20, ERC20Burnable {
    constructor() ERC20("\u4e09\u5927\u52e2\u529b\u0020\u002d\u0020\u0054\u0068\u0072\u0065\u0065\u0020\u0047\u0072\u0065\u0061\u0074\u0020\u0050\u006f\u0077\u0065\u0072\u0073", "San Dai Seiryoku") {
        _mint(msg.sender, 3 * 10 ** decimals());
    }
}