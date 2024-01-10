// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20Upgradeable.sol";
import "./ERC20BurnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./draft-ERC20PermitUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./StringsUpgradeable.sol";

/// @custom:security-contact security@brale.xyz
contract StablecoinV0 is
    Initializable,
    ERC20Upgradeable,
    ERC20BurnableUpgradeable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    ERC20PermitUpgradeable,
    UUPSUpgradeable
{
    // Deny is first because we want it to be the default
    enum AccessControlType {
        Deny,
        Allow
    }

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant UNPAUSER_ROLE = keccak256("UNPAUSER_ROLE");
    bytes32 public constant RESTRICTION_ADMIN_ROLE =
        keccak256("RESTRICTION_ADMIN_ROLE");

    // Used to allow or deny accounts access
    bytes32 public constant RESTRICTION_ROLE = keccak256("RESTRICTION_ROLE");
    string public constant CONTRACT_VERSION = "0.0";

    AccessControlType private accessControlType;

    function initialize(
        string memory name,
        string memory symbol,
        address to,
        uint256 amount,
        address admin,
        address automator,
        AccessControlType _accessControlType
    ) public initializer {
        __ERC20_init(name, symbol);
        __ERC20Burnable_init();
        __Pausable_init();
        __AccessControl_init();
        __ERC20Permit_init(name);
        __UUPSUpgradeable_init();

        accessControlType = _accessControlType;
        if (_accessControlType == AccessControlType.Allow) {
            _grantRole(RESTRICTION_ROLE, to);
            _grantRole(RESTRICTION_ROLE, automator);

            // Needed due to address(0) being used as the `from` account when doing subsequent mints
            _grantRole(RESTRICTION_ROLE, address(0));
        }

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(UNPAUSER_ROLE, admin);
        _grantRole(UPGRADER_ROLE, admin);

        _grantRole(PAUSER_ROLE, automator);
        _grantRole(MINTER_ROLE, automator);
        _grantRole(RESTRICTION_ADMIN_ROLE, automator);

        _grantRole(MINTER_ROLE, msg.sender);

        mint(to, amount);

        _revokeRole(MINTER_ROLE, msg.sender);
        _revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(UNPAUSER_ROLE) {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    function approve(address spender, uint256 amount)
        public
        override
        whenAllowed(_msgSender())
        whenAllowed(spender)
        returns (bool)
    {
        return super.approve(spender, amount);
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        override
        whenAllowed(_msgSender())
        whenAllowed(spender)
        returns (bool)
    {
        return super.increaseAllowance(spender, addedValue);
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        override
        whenAllowed(_msgSender())
        returns (bool)
    {
        return super.decreaseAllowance(spender, subtractedValue);
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public override whenAllowed(owner) whenAllowed(spender) {
        return super.permit(owner, spender, value, deadline, v, r, s);
    }

    /**
     * @dev Modifier for requiring role assignment for participation in actions covered by {RESTRICTION_ROLE}.
     * @param account The address to check
     */
    modifier whenAllowed(address account) {
        if (accessControlType == AccessControlType.Deny) {
            require(
                !hasRole(RESTRICTION_ROLE, account),
                _accessControlError(account, " has been restricted by role ")
            );
        } else {
            require(
                hasRole(RESTRICTION_ROLE, account),
                _accessControlError(account, " does not have required role ")
            );
        }

        _;
    }

    /**
     * @notice Returns whether `account` is allowed to participate in the actions covered by {RESTRICTION_ROLE}.
     * @param account The address to check
     */
    function isAllowed(address account) external view returns (bool) {
        if (accessControlType == AccessControlType.Deny) {
            // Anyone that doesn't have the RESTRCTION_ROLE is allowed
            return !hasRole(RESTRICTION_ROLE, account);
        } else {
            // The account must have the RESTRICTION_ROLE
            return hasRole(RESTRICTION_ROLE, account);
        }
    }

    /**
     * @notice Permits `account` to participate in the actions covered by {RESTRICTION_ROLE}.
     * @dev If this contract is a `Allow` list contract, {RESTRICTION_ROLE} is granted.
     * @dev If this contract is a `Deny` list contract (the default), {RESTRICTION_ROLE} is revoked.
     * @param account The address to allow
     */
    function allow(address account) public onlyRole(RESTRICTION_ADMIN_ROLE) {
        if (accessControlType == AccessControlType.Allow) {
            _grantRole(RESTRICTION_ROLE, account);
        } else {
            _revokeRole(RESTRICTION_ROLE, account);
        }
    }

    /**
     * @notice Prevents `account` from being able to participate in the actions covered by {RESTRICTION_ROLE}.
     * @dev If this contract is a `Allow` list contract, {RESTRICTION_ROLE} is revoked.
     * @dev If this contract is a `Deny` list contract (the default), {RESTRICTION_ROLE} is granted.
     * @param account The address to deny
     */
    function deny(address account) public onlyRole(RESTRICTION_ADMIN_ROLE) {
        if (accessControlType == AccessControlType.Deny) {
            _grantRole(RESTRICTION_ROLE, account);
        } else {
            _revokeRole(RESTRICTION_ROLE, account);
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused whenAllowed(from) whenAllowed(to) {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {}

    function _accessControlError(address account, string memory message)
        private
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "AccessControl: account ",
                    StringsUpgradeable.toHexString(uint160(account), 20),
                    message,
                    StringsUpgradeable.toHexString(
                        uint256(RESTRICTION_ROLE),
                        32
                    )
                )
            );
    }
}
