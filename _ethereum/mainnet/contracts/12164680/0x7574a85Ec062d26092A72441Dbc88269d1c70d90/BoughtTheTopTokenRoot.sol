// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./AccessControl.sol";
import "./Context.sol";

contract BoughtTheTopTokenRoot is Context, AccessControl, ERC20Burnable {
    /// @notice Role identifer for minter
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE` and `MINTER_ROLE` to the
     * account that deploys the contract.
     *
     * See {ERC20-constructor}.
     */
    constructor() ERC20("BoughtThe.top", "BTT") {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
    }

    /**
     * @dev Creates `amount` new tokens for `to`.
     *
     * See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to, uint256 amount) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "BoughtTheTopToken: must have minter role to mint");
        _mint(to, amount);
    }
}
