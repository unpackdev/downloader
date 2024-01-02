// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.22;

import "./ERC20.sol";

contract StandardERC20 is ERC20 {
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_
    ) ERC20(name_, symbol_) {
        _mint(msg.sender, totalSupply_ * 10 ** decimals());
    }
}
