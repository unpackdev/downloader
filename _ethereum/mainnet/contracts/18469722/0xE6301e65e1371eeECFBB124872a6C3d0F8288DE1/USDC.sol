// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";

contract TestUSDC is ERC20 {
    constructor() ERC20("TestUSDC", "TUSDC") {}

    function decimals() public pure override returns (uint8) {
        return 6;
    }

    function mint(address _address, uint256 _amount) public {
        _mint(_address, _amount * 10 ** decimals());
    }
}
