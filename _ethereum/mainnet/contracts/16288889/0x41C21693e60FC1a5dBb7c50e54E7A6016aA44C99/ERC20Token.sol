// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./SafeMath.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";

contract ERC20Token is ERC20 {
    constructor(string memory _name, string memory _symbol)
        ERC20(_name, _symbol)
    {
        _mint(msg.sender, 1_000_000_000 * 10**uint256(decimals()));
    }
}
