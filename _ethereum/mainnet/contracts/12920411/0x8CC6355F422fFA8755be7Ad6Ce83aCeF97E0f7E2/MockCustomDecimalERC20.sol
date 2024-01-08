// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.6.11;

import "./ERC20.sol";

contract MockCustomDecimalERC20 is ERC20 {
    constructor(
        string memory name,
        string memory symbol,
        uint256 _supply,
        uint8 _decimals
    ) public ERC20(name, symbol) {
        _setupDecimals(_decimals);
        _mint(msg.sender, _supply * (10**uint256(_decimals)));
    }

    function mint(address _to, uint256 _amount) public {
        _mint(_to, _amount);
    }
}