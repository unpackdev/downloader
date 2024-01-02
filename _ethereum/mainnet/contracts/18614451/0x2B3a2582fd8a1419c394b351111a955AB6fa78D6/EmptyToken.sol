// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./ERC20.sol";

contract EmptyToken is ERC20 {
    constructor() ERC20("", "") {}

    function transfer(address recipient, uint256 amount) public override returns (bool) {
       return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        return true;
    }
}
