// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./draft-ERC20Permit.sol";
import "./Ownable.sol";

contract XenlonMarsERC20 is ERC20Permit, Ownable {
    constructor() ERC20("Xenlon Mars", "XLON") ERC20Permit("Xenlon Mars") {}

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}
