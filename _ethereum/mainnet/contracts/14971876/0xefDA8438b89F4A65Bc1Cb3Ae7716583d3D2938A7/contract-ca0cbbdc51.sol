// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./Ownable.sol";

contract BOON is ERC20, Ownable {
    constructor() ERC20("BOON", "BOON") {
        _mint(msg.sender, 5 * 10 ** decimals());
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}
