// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./ERC20.sol";

uint256 constant _total = 1_000_000_000;
string constant _name = "TSLx Token";
string constant _symbol = "TSL";

contract Erc20Token is ERC20 {
    constructor() ERC20(_name, _symbol) {
        _mint(msg.sender, _total * 10**uint256(decimals()));
    }

    function decimals() public pure override returns (uint8) {
        return 6;
    }
}
