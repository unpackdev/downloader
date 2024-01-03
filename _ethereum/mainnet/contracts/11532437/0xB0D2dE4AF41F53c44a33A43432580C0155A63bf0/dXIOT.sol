// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./ERC20PresetMinterPauser.sol";

contract dXIOT is ERC20PresetMinterPauser {
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _initialSupply
    ) public ERC20PresetMinterPauser(_name, _symbol) {
        _mint(msg.sender, _initialSupply);
    }
}
