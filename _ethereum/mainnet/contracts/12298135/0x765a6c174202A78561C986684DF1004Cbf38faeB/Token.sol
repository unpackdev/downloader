// SPDX-License-Identifier: UNLICENCED

pragma solidity ^0.5.5;

import "./ERC20.sol";
import "./ERC20Detailed.sol";
import "./ERC20Mintable.sol";

contract CatsToken is Context, ERC20, ERC20Detailed, ERC20Mintable {

    using Roles for Roles.Role;

    Roles.Role private _minters;

    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply
    ) public ERC20Detailed(name, symbol, 18) {
        _minters.add(_msgSender());
        _mint(_msgSender(), initialSupply);
    }

}
