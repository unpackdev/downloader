// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.6;

import "./ERC20BurnableUpgradeable.sol";
import "./ERC20PausableUpgradeable.sol";
import "./ERC20CappedUpgradeable.sol";
import "./Initializable.sol";
import "./ContextUpgradeable.sol";
import "./AccessControlEnumerableUpgradeable.sol";



/**
 * @dev {ERC20} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation)
 *  - a pauser role that allows to stop all token transfers
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter and pauser
 * roles, as well as the default admin role, which will let it grant both minter
 * and pauser roles to other accounts.
 */
contract ERC20ProxyTokenUpgradeable is
    Initializable,
    ContextUpgradeable,
    AccessControlEnumerableUpgradeable,
    ERC20CappedUpgradeable,
    ERC20BurnableUpgradeable,
    ERC20PausableUpgradeable
{
    function initialize(string memory name, string memory symbol, uint256 cap) public virtual initializer {
        __ERC20ProxyTokenUpgradeable_init(name, symbol, cap);
    }
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE` and `PAUSER_ROLE` to the
     * account that deploys the contract.
     *
     * See {ERC20-constructor}.
     */
    function __ERC20ProxyTokenUpgradeable_init(string memory name, string memory symbol, uint256 cap)
        internal
        initializer
    {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
        __AccessControlEnumerable_init_unchained();
        __ERC20_init_unchained(name, symbol);
        __ERC20Capped_init_unchained(cap);
        __ERC20Burnable_init_unchained();
        __Pausable_init_unchained();
        __ERC20Pausable_init_unchained();
        __ERC20ProxyTokenUpgradeable_init_unchained();
    }

    function __ERC20ProxyTokenUpgradeable_init_unchained() internal initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
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
    function mint(address to, uint256 amount) public virtual whenNotPaused {
        require(hasRole(MINTER_ROLE, _msgSender()), "must have minter role to mint");
        _mint(to, amount);
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "must have pauser role to pause");
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "must have pauser role to unpause");
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        virtual
        override(ERC20Upgradeable, ERC20PausableUpgradeable)
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _mint(address account, uint256 amount)
        internal
        virtual
        override(ERC20Upgradeable, ERC20CappedUpgradeable)
    {
        super._mint(account, amount);
    }

    uint256[50] private __gap;
}
