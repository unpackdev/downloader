// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./Ownable.sol";

contract SenecaToken is ERC20, Ownable {
    constructor() ERC20("Seneca", "SNCA") Ownable(msg.sender) {
        _mint(msg.sender, 1700000000 * (10 ** uint256(decimals())));
    }

    function decimals() public view virtual override returns (uint8) {
        return 10;
    }

}
