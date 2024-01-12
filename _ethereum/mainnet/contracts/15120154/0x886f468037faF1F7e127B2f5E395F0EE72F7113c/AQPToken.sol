// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./Ownable.sol";

contract AQPToken is ERC20, Ownable {
    constructor() ERC20("AQP Token", "AQP") {}

    /**
     * @dev Mint `amount` tokens to `account`. It is called by AQP platform
     *
     * Requirements:
     *
     * - the caller must be the owner of the contract
     */
    function mint(address account, uint256 amount) external onlyOwner {
        _mint(account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`. It is called by AQP platform
     *
     * Requirements:
     *
     * - the caller must be the owner of the contract
     */
    function burnFrom(address account, uint256 amount) external onlyOwner {
        _burn(account, amount);
    }
}
