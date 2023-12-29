// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./ERC20Pausable.sol";
import "./AccessControl.sol";
import "./IAccessControl.sol";
import "./AccessControlEnumerable.sol";
import "./ERC20Permit.sol";

import "./IMintable.sol";

contract FortunaGovernanceToken is
    IMintable,
    ERC20,
    ERC20Pausable,
    AccessControlEnumerable,
    ERC20Permit
{
    error CapHasBeenReached();
    error CannotUnbanMyself();
    error Banned(address who);
    error MaxTaxHasBeenReached(uint256 passedValue);

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant TAX_MARKER_ROLE = keccak256("TAX_MARKER_ROLE");
    bytes32 public constant UNTAXABLE_ROLE = keccak256("UNTAXABLE_ROLE");
    bytes32 public constant BANNED_ROLE = keccak256("BANNED_ROLE");

    uint256 public constant CAP = 1_000_000_000 ether;
    uint256 public constant MAX_BPS = 10000;
    uint256 public constant MAX_TAX_FOR_DEX_TRADING = 1000;

    uint256 public currentTaxForDexTrading; // EXAMPLE: 9800 == 5%
    address public taxReceiver;

    constructor(
        address admin
    ) 
        ERC20("$FORTUNA", "$FTNA") 
        ERC20Permit("$FORTUNA")
    {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(PAUSER_ROLE, admin);
        _grantRole(MINTER_ROLE, admin);
        _grantRole(BURNER_ROLE, admin);
        _grantRole(UNTAXABLE_ROLE, admin);
        taxReceiver = admin;
        _pause();
    }

    function setTaxMarkers(
        address[] memory dexPairs
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i; i < dexPairs.length; i++) {
            _grantRole(TAX_MARKER_ROLE, dexPairs[i]);
        }
    }

    /// @notice You should specify an amount of BPS that are going to go to the user and not tax receiver.
    /// For example: if `_newTax` = 9800 then 98% are going to the user, 2% to the tax receiver.
    function setTaxForDexTrading(
        uint256 _newTax
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_newTax > MAX_TAX_FOR_DEX_TRADING) {
            revert MaxTaxHasBeenReached(_newTax);
        }
        currentTaxForDexTrading = _newTax;
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function mint(
        address to,
        uint256 amount
    ) public override onlyRole(MINTER_ROLE) {
        if (totalSupply() + amount > CAP) {
            revert CapHasBeenReached();
        }
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) public onlyRole(BURNER_ROLE) {
        _burn(from, amount);
    }

    function renounceRole(
        bytes32 role,
        address callerConfirmation
    ) public override(IAccessControl, AccessControl) {
        if (role == BANNED_ROLE) {
            revert CannotUnbanMyself();
        }
        super.renounceRole(role, callerConfirmation);
    }

    function _update(
        address from,
        address to,
        uint256 value
    ) internal override(ERC20, ERC20Pausable) {
        if (from == address(0)) {
            if (hasRole(BANNED_ROLE, to)) {
                revert Banned(to);
            }
        } else {
            if (hasRole(BANNED_ROLE, from)) {
                revert Banned(from);
            }
        }
        if (paused()) {
            if (from != address(0)) {
                revert EnforcedPause();
            } else {
                super._update(from, to, value);
            }
        } else {
            if (hasRole(TAX_MARKER_ROLE, to) && !hasRole(UNTAXABLE_ROLE, from)) {
                uint256 tax = (value * currentTaxForDexTrading) / MAX_BPS;
                super._update(from, taxReceiver, tax);
                super._update(from, to, value - tax);
            } else {
                super._update(from, to, value);
            }
        }
    }
}
