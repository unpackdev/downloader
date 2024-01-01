// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20Upgradeable.sol";
import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./ERC20PermitUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";

contract StablyUsd is Initializable, ERC20Upgradeable, PausableUpgradeable, OwnableUpgradeable, AccessControlUpgradeable, ERC20PermitUpgradeable, UUPSUpgradeable {
    event Minted(uint256 amount, address indexed to, address indexed sender);
    event Burned(uint256 amount, address indexed sender);
    event IncreasedMaxSupply(uint256 value, address indexed sender);
    event DecreasedMaxSupply(uint256 value, address indexed sender);
    event BlockedAddress(address indexed account, address indexed sender);
    event UnblockedAddress(address indexed account, address indexed sender);
    event AddedMintRecipient(address indexed account, address indexed sender);
    event RemovedMintRecipient(address indexed account, address indexed sender);

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UNPAUSER_ROLE = keccak256("UNPAUSER_ROLE");
    bytes32 public constant BLOCKER_ROLE = keccak256("BLOCKER_ROLE");
    bytes32 public constant UNBLOCKER_ROLE = keccak256("UNBLOCKER_ROLE");

    mapping(address => bool) private _blockedList;
    mapping(address => bool) private _mintRecipientList;

    uint256 private _maxSupply;

    uint256 private _adminRoleCount;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address admin) initializer public {
        _maxSupply = 0;
        _adminRoleCount = 0;

        __ERC20_init("Stably USD", "USDS");
        __Pausable_init();
        __Ownable_init();
        __AccessControl_init();
        __ERC20Permit_init("Stably USD");
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    modifier whenNotInBlockedList(address account) {
        require(!_blockedList[account], "Address is blocked");
        _;
    }

    /** @dev Creates `amount` tokens and assigns them to `to`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     * Emits a {Minted} event with `to` set to to, `amount` set to the amount, and `sender` set to the sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - The sum of `amount` and totalSupply cannot go over the maxSupply.
     * - `to` must be on the list of addresses that can accept a minted tokens
     */
    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        require(totalSupply() + amount <= _maxSupply, "Max supply exceeded");
        require(_mintRecipientList[to], "Account not a valid recipient");

        _mint(to, amount);

        emit Minted(amount, to, _msgSender());
    }

    /**
     * @dev Destroys `amount` tokens from `sender`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     * Emits a {Burned} event with `amount` set to the amount, and `sender` set to the sender.
     *
     * Requirements:
     *
     * - `sender` must have at least `amount` tokens.
     */
    function burn(uint256 amount) public onlyRole(MINTER_ROLE) {
        _burn(_msgSender(), amount);

        emit Burned(amount, _msgSender());
    }

    /**
     * @dev Triggers stopped state.
     *
     * Emits a {Paused} event with `account` set to the sender.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /**
     * @dev Returns to normal state.
     *
     * Emits an {Unpaused} event with `account` set to the sender.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function unpause() public onlyRole(UNPAUSER_ROLE) {
        _unpause();
    }

    /**
     * @dev Blocks the `account` from minting, burning, and transferring tokens.
     *
     * May emit a {BlockedAddress} event with `account` set to account, and `sender` set to the sender.
     */
    function blockAddress(address account) public onlyRole(BLOCKER_ROLE) {
        if (!_blockedList[account]) {
            _blockedList[account] = true;
            emit BlockedAddress(account, _msgSender());
        }
    }

    /**
     * @dev Unblocks a minter `account` from minting and burning. Unblocks any `account` from transferring tokens.
     *
     * May emit a {UnblockedAddress} event with `account` set to account, and `sender` set to the sender.
     */
    function unblockAddress(address account) public onlyRole(UNBLOCKER_ROLE) {
        if (_blockedList[account]) {
            delete _blockedList[account];
            emit UnblockedAddress(account, _msgSender());
        }
    }

    /**
     * @dev Increases the max supply by `amount` tokens.
     *
     * Emits an {IncreasedMaxSupply} event with `amount` set to the amount, and `sender` set to the sender.
     */
    function increaseMaxSupply(uint256 amount) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _maxSupply += amount;

        emit IncreasedMaxSupply(amount, _msgSender());
    }

    /**
     * @dev Decreases the max supply by `amount` tokens.
     *
     * Emits an {DecreasedMaxSupply} event with `amount` set to the amount, and `sender` set to the sender.
     *
     * Requirements:
     *
     * - `amount` should not result in a max supply lower than the total supply.
     */
    function decreaseMaxSupply(uint256 amount) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_maxSupply - amount >= totalSupply(), "Resulting max supply is lower than total supply");

        _maxSupply -= amount;

        emit DecreasedMaxSupply(amount, _msgSender());
    }

    /**
     * @dev Adds the `account` to a list of addresses that can receive from a mint.
     *
     * May emit an {AddedMintRecipient} event with `account` set to account, and `sender` set to the sender.
     */
    function addMintRecipient(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        if (!_mintRecipientList[account]) {
            _mintRecipientList[account] = true;
            emit AddedMintRecipient(account, _msgSender());
        }
    }

    /**
     * @dev Removes the `account` from a list of addresses that can receive from a mint.
     *
     * May emit a {RemovedMintRecipient} event with `account` set to account, and `sender` set to the sender.
     */
    function removeMintRecipient(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_mintRecipientList[account]) {
            delete _mintRecipientList[account];
            emit RemovedMintRecipient(account, _msgSender());
        }
    }


    /**
     * @dev Retrieves `maxSupply`.
     */
    function getMaxSupply() public view returns (uint256) {
        return _maxSupply;
    }

    /**
     * @dev Retrieves `decimals`.
     */
    function decimals() public view virtual override returns (uint8) {
        return 6;
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Requirements:
     *
     * - Should not result in an empty DEFAULT_ADMIN_ROLE
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        require(role != DEFAULT_ADMIN_ROLE || _adminRoleCount > 1, "Cannot revoke last admin role");

        bool accountHasRole = hasRole(role, account);

        super._revokeRole(role, account);

        if (role == DEFAULT_ADMIN_ROLE && accountHasRole) {
            _adminRoleCount -= 1;
        }
    }

    /**
     * @dev Grants `role` to `account`.
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        bool accountAlreadyHasRole = hasRole(role, account);

        super._grantRole(role, account);

        if (role == DEFAULT_ADMIN_ROLE && !accountAlreadyHasRole) {
            _adminRoleCount += 1;
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
    internal
    whenNotPaused
    whenNotInBlockedList(from)
    whenNotInBlockedList(to)
    override
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _authorizeUpgrade(address newImplementation)
    internal
    onlyRole(DEFAULT_ADMIN_ROLE)
    override
    {}
}
