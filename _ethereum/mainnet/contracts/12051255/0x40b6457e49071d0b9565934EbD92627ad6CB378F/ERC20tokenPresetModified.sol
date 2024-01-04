// SPDX-License-Identifier: UNLICENSED
// Modified from: https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/master/contracts/presets/ERC20PresetMinterPauserUpgradeable.sol

pragma solidity 0.6.12;

// MODIFIED: import paths
// import "./AccessControl.sol";
import "./ContextUpgradeable.sol";
import "./ERC20Upgradeable.sol";
import "./ERC20BurnableUpgradeable.sol";
import "./ERC20PausableUpgradeable.sol";
import "./Initializable.sol";
import "./IManagementContract.sol";

/**
 * @dev {ERC20} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation)
 *  - a pauser role that allows to stop all token transfers
 *
 * - This is a slighlty modified version of {ERC20PresetMinterPauserUpgradeable} by OpenZeppelin.
 *
 * The contract uses {Initializable}, {ContextUpgradeable}, {ERC20BurnableUpgradeable}, {ERC20PausableUpgradeable} from OpenZeppelin
 *
 * This contract uses {HManagementContract} to control permissions using the
 * different roles..
 *
 * The account that deploys the contract will be granted the minter and pauser
 * roles, as well as the default admin role, which will let it grant both minter
 * and pauser roles to aother accounts
 */
contract ERC20PresetMinterPauserUpgradeableModified is Initializable, ContextUpgradeable, ERC20BurnableUpgradeable, ERC20PausableUpgradeable { // MODIFIED
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00; // ADDED
    // bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 private constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    IManagementContract public managementContract; // ADDED

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE` and `PAUSER_ROLE` to the
     * account that deploys the contract.
     *
     * `managementContractAddress` is a custom variable pointing to the
     * Himalaya's management contract in order to offload certain functionality
     * to the shared contract
     *
     * See {ERC20-constructor}.
     */

    function initialize(string memory name, string memory symbol, address managementContractAddress) public virtual {
        // MODIFIED
        managementContract = IManagementContract(managementContractAddress); // ADDED
        __ERC20PresetMinterPauser_init(name, symbol);
    }

    /**
     * @dev Modified function. Two functions `__AccessControl_init_unchained` and `__ERC20PresetMinterPauser_init_unchained`
     * have been moved to the {HManagementContract}
     *
     */
    function __ERC20PresetMinterPauser_init(string memory name, string memory symbol) internal initializer {
        __Context_init_unchained();
        // __AccessControl_init_unchained();               // MODIFIED
        __ERC20_init_unchained(name, symbol);
        __ERC20Burnable_init_unchained();
        __Pausable_init_unchained();
        __ERC20Pausable_init_unchained();
        // __ERC20PresetMinterPauser_init_unchained(name, symbol); // MODIFIED
    }

    /**
     * @dev Modified function. Setting up roles is moved to the {managamentContract}
     * Also the mint function is only in the `mainnet` version (not on `quorum` version)
     */
    function __ERC20PresetMinterPauser_init_unchained(string memory name, string memory symbol) internal initializer {
        // _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());    // MODIFIED
        // _setupRole(MINTER_ROLE, _msgSender());           // MODIFIED
        // _setupRole(PAUSER_ROLE, _msgSender());           // MODIFIED
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
        require(managementContract.hasRole(PAUSER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have pauser role to pause"); // MODIFIED
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
        require(managementContract.hasRole(PAUSER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have pauser role to unpause"); // MODIFIED
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override(ERC20Upgradeable, ERC20PausableUpgradeable) {
        // MODIFIED
        super._beforeTokenTransfer(from, to, amount);
    }

    uint256[50] private __gap;
}
