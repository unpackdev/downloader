// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./ERC20.sol";

contract DummyToken is ERC20 {
    constructor(string memory _name, string memory _symbol)
        ERC20(_name, _symbol)
    {
        _mint(msg.sender, 1);
    }

    function decimals() public pure override returns (uint8) {
        return 0;
    }
}
