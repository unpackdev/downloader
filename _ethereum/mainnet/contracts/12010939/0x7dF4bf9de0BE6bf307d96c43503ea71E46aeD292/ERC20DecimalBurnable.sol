// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

import "./ERC20Burnable.sol";

/**
 * @dev {ERC20} token, including:
 *
 *  - Custom number of decimals
 *  - Preminted initial supply
 *  - Ability for holders to burn (destroy) their tokens
 *  - No access control mechanism (for minting/pausing) and hence no governance
 *
 * This contract uses {ERC20Burnable} to include burn capabilities - head to
 * its documentation for details.
 */
contract ERC20DecimalBurnable is ERC20Burnable {
    /**
     * @dev Mints `initialSupply` amount of token and transfers them to `owner`.  
     *
     * See {ERC20-constructor}.
     */
    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals,
        uint256 initialSupply,
        address owner
    ) public ERC20(name, symbol) {
        _setupDecimals(decimals);
        _mint(owner, initialSupply);
    }
}