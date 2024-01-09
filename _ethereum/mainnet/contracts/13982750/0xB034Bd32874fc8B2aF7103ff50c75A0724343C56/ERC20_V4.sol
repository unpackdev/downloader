// contracts/MyToken.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./Initializable.sol";
import "./ContextUpgradeable.sol";
import "./AccessControlEnumerableUpgradeable.sol";
import "./ERC20BurnableUpgradeable.sol";
import "./ERC20PausableUpgradeable.sol";

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
 * and pauser roles to aother accounts
 */
contract ERC20PresetMinterPauserUpgradeSafe is Initializable, ContextUpgradeable, AccessControlEnumerableUpgradeable, ERC20BurnableUpgradeable, ERC20PausableUpgradeable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /**
     * @dev Overrides the default decimals value of 18 
     */
    function decimals() public pure override returns (uint8) {
        return 6;
    }

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE` and `PAUSER_ROLE` to the
     * account that deploys the contract.
     *
     * See {ERC20-constructor}.
     */
    function initialize(string memory name, string memory symbol, address adminSafeAccount, address pauserSafeAccount) public {
        __ERC20PresetMinterPauser_init(name, symbol, adminSafeAccount, pauserSafeAccount);
    }

    function __ERC20PresetMinterPauser_init(string memory name, string memory symbol, address adminSafeAccount, address pauserSafeAccount) internal initializer {
        __Context_init_unchained();
        __AccessControl_init_unchained();
        __ERC20_init_unchained(name, symbol);
        __ERC20Burnable_init_unchained();
        __Pausable_init_unchained();
        __ERC20Pausable_init_unchained();
        __ERC20PresetMinterPauser_init_unchained(adminSafeAccount, pauserSafeAccount);
    }

    function __ERC20PresetMinterPauser_init_unchained(address adminSafeAccount, address pauserSafeAccount) internal initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, adminSafeAccount);
        _setupRole(MINTER_ROLE, adminSafeAccount);
        _setupRole(PAUSER_ROLE, pauserSafeAccount);
    }
    
    /**
     * @dev grant Role
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
    */
    function grantRole(bytes32 role, address account) public override{
        if(role == PAUSER_ROLE && getRoleMemberCount(role) > 0)
            require(hasRole(PAUSER_ROLE, _msgSender()), "Only PAUSER_ROLE can change the PAUSER_ROLE");
        else
            require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Only DEFAULT_ADMIN_ROLE can grant Roles");
        _setupRole(role, account);
    }
    
    /**
     * @dev revoke Role adding controle
     *
     * Requirements:
     *
     * - PAUSER_ROLE can't be revoked, it can only be renounced.
    */
    function revokeRole(bytes32 role, address account) public override {
        if(role == PAUSER_ROLE)
            require(false, "PAUSER_ROLE can't be revoked, it can only be renounced");
        super.revokeRole(role, account);
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
    function mint(address to, uint256 amount) public {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have minter role to mint");
        // Override the decimals() function
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
    function pause() public {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have pauser role to pause");
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
    function unpause() public {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have pauser role to unpause");
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override(ERC20Upgradeable, ERC20PausableUpgradeable){
        super._beforeTokenTransfer(from, to, amount);
    }

    uint256[50] private __gap;
}