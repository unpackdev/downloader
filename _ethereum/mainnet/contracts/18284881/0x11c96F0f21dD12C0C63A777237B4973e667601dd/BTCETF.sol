// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./SafeMath.sol";

contract BTCETF is ERC20 {
    using SafeMath for uint256;

    constructor() ERC20("BTCETF", "BTCETF") {
        _mint(msg.sender, 444444444444 * 10 ** decimals());
    }
}
