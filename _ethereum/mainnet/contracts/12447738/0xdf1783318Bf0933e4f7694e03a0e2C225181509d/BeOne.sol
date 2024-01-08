// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "./ERC20Upgradeable.sol";
import "./ERC20BurnableUpgradeable.sol";
import "./AccessControlEnumerableUpgradeable.sol";
import "./ContextUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev {ERC20} token for BeOne:
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles.
 *
 * The account that deploys the contract will be granted the minter
 * role, as well as the default admin role, which will let it grant minter
 * roles to other accounts.
 */
contract BeOne is Initializable, ContextUpgradeable, AccessControlEnumerableUpgradeable, ERC20BurnableUpgradeable {
    function initialize(string memory name, string memory symbol) public virtual initializer {
        __BeOne_init(name, symbol);
    }
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE` and `PAUSER_ROLE` to the
     * account that deploys the contract.
     *
     * See {ERC20-constructor}.
     */
    function __BeOne_init(string memory name, string memory symbol) internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
        __AccessControlEnumerable_init_unchained();
        __ERC20_init_unchained(name, symbol);
        __ERC20Burnable_init_unchained();
        __BeOne_init_unchained(name, symbol);
    }

    function __BeOne_init_unchained(string memory /*name*/, string memory /*symbol*/) internal initializer {
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
        require(hasRole(MINTER_ROLE, _msgSender()), "BeOne: must have minter role to mint");
        _mint(to, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override(ERC20Upgradeable) {
        super._beforeTokenTransfer(from, to, amount);
    }
    uint256[50] private __gap;
}
