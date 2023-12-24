// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./Ownable.sol";

contract HarryPotterObamaStonkMemes is ERC20, Ownable {
    constructor() ERC20("HarryPotterObamaStonkMemes", "GOOGLE") {
        _mint(msg.sender, 100000000 * 10 ** decimals());
    }
}
