// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

import "./AccessControlUpgradeable.sol";
import "./Initializable.sol";
import "./PausableUpgradeable.sol";
import "./IPausable.sol";
import "./IDeposits.sol";

/**
 * @title HManagementContract
 * @dev Shared smart contract responsible for:
 * - access control
 * - whitelisting and superwhitelisting
 * - freezing of accounts
 *
 * The contract uses {Initializable}, {AccessControlUpgradeable} and {PausableUpgradeable} by OpenZeppelin
 *
 * Account that is passed to the initialize function will be granted admin, minter, pauser and whitelister roles.
 *
 * Whitelisted accounts are addresses which have passed KYC and don't have transfer delays through pending deposits.
 *
 * SuperWhitelisted account is a special account that belongs to
 * Himalaya Group and allows non whitelisted users to instantly transfer funds even if the have any tokens
 * locked in pending deposits.
 */
contract HManagementContract is Initializable, AccessControlUpgradeable, PausableUpgradeable {
    /**
     * @dev Role which allows to {mint} tokens
     */
    bytes32 private constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /**
     * @dev Role which allows to {pause} the contracts
     */
    bytes32 private constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /**
     * @dev Role which allows to {whitelist} and {unWhitelist}
     */
    bytes32 private constant WHITELIST_ROLE = keccak256("WHITELIST_ROLE");

    /**
     * @dev Mapping of whitelisted accounts which have passed KYC and don't require {nonWhitelistedDelay}
     */
    mapping(address => bool) private whitelisted;

    /**
     * @dev Mapping of superWhitelisted addresses. SuperWhitelisted account is a special account that belongs to
     * Himalaya Group and allows non whitelisted users to instantly transfer funds even if the have any tokens
     * locked in {HHH-pendingDeposits}
     */
    mapping(address => bool) private superWhiteListed;

    /**
     * @dev Mapping of frozen accounts
     */
    mapping(address => bool) private frozen;

    /**
     * @dev Time that is necessary to unlock {HHH-pendingDeposits} from non whitelisted accounts
     */
    uint256 public nonWhitelistedDelay;

    /**
     * @dev Maximum number of {HHH-pendingDeposits} allowed at the same time.
     */
    uint256 public nonWhitelistedDepositLimit;

    /**
     * @dev List of all tokens, that are using this contract
     */
    address[] private tokenList;

    /**
     * @dev Emitted when a new `addr` is whitelisted.
     */
    event Whitelist(address addr);

    /**
     * @dev Emitted when `addr` is unwhitelisted.
     */
    event UnWhitelist(address addr);

    /**
     * @dev Emitted when `addr` is frozen.
     */
    event Freeze(address addr);

    /**
     * @dev Emitted when `addr` is unfrozen.
     */
    event UnFreeze(address addr);

    /**
     * @dev Emitted when `addr` is added to the {superWhiteListed}.
     */
    event SuperWhitelist(address addr);

    /**
     * @dev Emitted when `addr` is removed from the {superWhiteListed}.
     */
    event UnSuperWhitelist(address addr);

    /**
     * @dev Sets the value of `admin` to the Admin, minter, pauser and whitelister roles. Initializes
     * {nonWhitelistedDelay} to 24 hours, {nonWhitelistedDepositLimit} to 100 and sets 0x0 address as whitelisted
     * in order to save storage by not collecting pendingDeposits on the 0x0 address during token burning
     */
    function initialize(address admin) public virtual initializer {
        require(admin != address(0), "Adming address cannot be null");
        __Pausable_init_unchained();
        __AccessControl_init_unchained();

        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(MINTER_ROLE, admin);
        _setupRole(PAUSER_ROLE, admin);
        _setupRole(WHITELIST_ROLE, admin);

        nonWhitelistedDelay = 366 days;
        nonWhitelistedDepositLimit = 100; // this is to avoid griefing attack, an attacker sending too many miniscule transactions clogging data structures, potentially beyond block gas limit

        whitelisted[address(0)] = true; // cannot call whitelist() function as whitelister permissions are not setup at this point
        whitelisted[admin] = true;
    }

    /**
     * @dev Only address which is set to Admin role can call functions with this modifier
     */
    modifier onlyAdmin virtual {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "must have ADMIN ROLE");
        _;
    }

    /**
     * @dev Only address with WHITELIST_ROLE can call functions with this modifier
     */
    modifier onlyWhitelister virtual {
        require(hasRole(WHITELIST_ROLE, _msgSender()), "must have WHITELIST ROLE");
        _;
    }

    /**
     * @dev Set the {nonWhitelistedDelay}. It can be set to 0 in case we want to remove the delay.
     *
     * Requirements:
     *
     * - the caller must have the `DEFAULT_ADMIN_ROLE`.
     */
    function setNonWhitelistedDelay(uint256 _nonWhitelistedDelay) external virtual onlyAdmin {
        nonWhitelistedDelay = _nonWhitelistedDelay;
    }

    /**
     * @dev Set the {nonWhitelistedDepositLimit}. It can be set to 0 to prevent deposits to non-whitelisted users.
     *
     * Requirements:
     *
     * - the caller must have the `DEFAULT_ADMIN_ROLE`.
     */
    function setNonWhitelistedDepositLimit(uint256 _nonWhitelistedDepositLimit) external virtual onlyAdmin {
        nonWhitelistedDepositLimit = _nonWhitelistedDepositLimit;
    }

    /**
     * @dev Whitelist `addr`. Only Whitelister Role can call this. It is used when a new account
     * has completed KYC. It allows the `addr` to receive funds without the {nonWhitelistedDelay}
     *
     * Emits {Whitelist} event
     *
     * Requirements:
     *
     * - the caller must have the `WHITELIST_ROLE`.
     */
    function whitelist(address addr) external virtual onlyWhitelister {
        whitelisted[addr] = true;

        for (uint256 i = 0; i < tokenList.length; i++) {
            IDeposits(tokenList[i]).removeAllPendingDepositsExternal(addr);
        }

        emit Whitelist(addr);
    }

    /**
     * @dev Removes an account from the {whitelisted} list.
     * The contract cannot be paused.
     *
     * Emits {UnWhitelist} event.
     *
     * Requirements:
     *
     * - the caller must have the `WHITELIST_ROLE`.
     * - contract must not be paused.
     */
    function unWhitelist(address addr) external virtual onlyWhitelister whenNotPaused() {
        require(whitelisted[addr], "Only whitelisted users can be unwhitelisted"); // calling unwhitelist on onwhitelisted might lead to locked amount being greater that banalce of address
        whitelisted[addr] = false;

        for (uint256 i = 0; i < tokenList.length; i++) {
            IDeposits(tokenList[i]).putTotalBalanceToLock(addr);
        }

        emit UnWhitelist(addr);
    }

    /**
     * @dev View function which checks if `addr` is whitelisted.
     *
     * Returns `true` or `false`
     */
    function isWhitelisted(address addr) external virtual view returns (bool) {
        return whitelisted[addr];
    }

    /**
     * @dev Set `addr` to frozen status.
     *
     * Emits {Freeze} event.
     *
     * Requirements:
     *
     * - the caller must have the `WHITELIST_ROLE`.
     */
    function freeze(address addr) external virtual onlyWhitelister {
        frozen[addr] = true;
        emit Freeze(addr);
    }

    /**
     * @dev Removes `addr` from the the frozen list.
     *
     * Emits {UnFreeze} event.
     *
     * Requirements:
     *
     * - the caller must have the `WHITELIST_ROLE`.
     * - contract must not be paused.
     */
    function unFreeze(address addr) external virtual onlyWhitelister whenNotPaused() {
        frozen[addr] = false;
        emit UnFreeze(addr);
    }

    /**
     * @dev View only function which checks is `addr` is frozen.
     *
     * Returns `true` or `false`
     */
    function isFrozen(address addr) external virtual view returns (bool) {
        return frozen[addr];
    }

    /**
     * @dev Adds `addr` to the {superWhitelisted} list. Sender must have Admin Role.
     *
     * Emits {SuperWhitelist} event.
     *
     * Requirements:
     *
     * - the caller must have the `DEFAULT_ADMIN_ROLE`.
     */
    function addSuperWhitelisted(address addr) external virtual onlyAdmin {
        superWhiteListed[addr] = true;
        emit SuperWhitelist(addr);
    }

    /**
     * @dev Removes `addr` from the {superWhitelisted} list.
     *
     * Requirements:
     *
     * - the caller must have the `DEFAULT_ADMIN_ROLE`.
     */
    function removeSuperWhitelisted(address addr) external virtual onlyAdmin {
        superWhiteListed[addr] = false;
        emit UnSuperWhitelist(addr);
    }

    /**
     * @dev View which checks if `addr` is on the {superWhitelisted} list.
     *
     * Returns `true` or `false`
     */
    function isSuperWhitelisted(address addr) external virtual view returns (bool) {
        return superWhiteListed[addr];
    }

    /**
     * @dev Pauses all contracts from transfering funds. Sender must have Pauser Role.
     */
    function pause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "Must have pauser role to do global pause");
        _pause();
    }

    /**
     * @dev Unpauses contracts from transfering funds. Sender must have Pauser Role.
     */
    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "Must have pauser role to do the global unpause");
        _unpause();
    }

    /**
     * @dev Pauses specific token from transfering funds. Sender must have Pauser Role.
     */
    function pauseToken(address token) public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "Must have pauser role to pause individual contract");
        IPausable(token).pause();
    }

    /**
     * @dev UnPauses specific token from transfering funds. Sender must have Pauser Role.
     */
    function unpauseToken(address token) public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "Must have pauser role to pause individual contract");
        IPausable(token).unpause();
    }

    ////////////////////////////// TOKENS

    /**
     * @dev Adds `tokenAddress` to the {tokenList} list. If token is already on the lists, it is not added again. Sender must have Admin Role.
     *
     * Requirements:
     *
     * - the caller must have the `DEFAULT_ADMIN_ROLE`.
     */
    function addToken(address tokenAddress) external virtual onlyAdmin {
        // check token is not already added
        // tokenlist is expected to be short, and this action should be infrequent, so looping is completely fine.
        for (uint256 i = 0; i < tokenList.length; i++) {
            if (tokenList[i] == tokenAddress) {
                return;
            }
        }
        tokenList.push(tokenAddress);
    }

    /**
     * @dev REmoves `tokenAddress` from the {tokenList} list. If token is not on the lists, nothing happens. Sender must have Admin Role.
     *
     * Requirements:
     *
     * - the caller must have the `DEFAULT_ADMIN_ROLE`.
     */
    function removeToken(address tokenAddress) external virtual onlyAdmin {
        // tokenlist is expected to be short, and this action should be infrequent, so looping is completely fine.
        // alternatively, we'd need another mapping tokenAddres => index of tokenAddress in tokenList, which is inefficient for short lists.
        for (uint256 i = 0; i < tokenList.length; i++) {
            if (tokenList[i] == tokenAddress) {
                tokenList[i] = tokenList[tokenList.length - 1];
                tokenList.pop();
                break;
            }
        }
    }

    /**
     * @dev View that returns list of all tokens, connected to this contract.
     *
     * Returns list of addresses `address[]`
     */
    function getTokenList() external virtual view returns (address[] memory) {
        return tokenList;
    }
}
