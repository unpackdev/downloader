// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity 0.8.0;

import "ERC20.sol";


contract MobixToken is ERC20 {

    uint8 private _decimals; 

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_, uint8 decimals_, uint256 totalSupply_) public ERC20(name_, symbol_) {
        _decimals = decimals_; 
        _mint(_msgSender(), totalSupply_);
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

}
