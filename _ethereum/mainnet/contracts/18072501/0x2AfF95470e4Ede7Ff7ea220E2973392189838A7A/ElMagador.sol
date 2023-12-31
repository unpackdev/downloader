//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC20.sol";

contract ElMagador is ERC20 {
    constructor(uint256 _totalSupply) ERC20("El Magador", "ELMAGA") {
        _mint(msg.sender, _totalSupply);
    }

    /**
     * @dev Destroys `_value` tokens from the caller.
     * @param _value, amount to burn
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 _value) external {
        _burn(msg.sender, _value);
    }
}
