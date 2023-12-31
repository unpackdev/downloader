// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./Initializable.sol";
import "./IDramFreezable.sol";
import "./ContextUpgradeable.sol";

/**
 * @notice An abstract contract provide freezing functionalities and modifiers
 */
abstract contract DramFreezable is
    Initializable,
    IDramFreezable,
    ContextUpgradeable
{
    mapping(address => bool) private _isFreezed;

    /**
     * @dev A modifier that checks if the account is not freezed, else reverts.
     */
    modifier whenNotFreezed(address account) {
        _requireNotFreezed(account);
        _;
    }

    /**
     * @dev A modifier that checks if the account is freezed, else reverts.
     */
    modifier whenFreezed(address account) {
        _requireFreezed(account);
        _;
    }

    // solhint-disable-next-line func-name-mixedcase
    function __DramFreezable_init() internal onlyInitializing {
        __DramFreezable_init_unchained();
    }

    // solhint-disable-next-line func-name-mixedcase, no-empty-blocks
    function __DramFreezable_init_unchained() internal onlyInitializing {}

    /**
     * @inheritdoc IDramFreezable
     */
    function isFreezed(
        address account
    ) public view virtual override returns (bool) {
        return _isFreezed[account];
    }

    /**
     * @dev Freezes an account.
     * @param account Address to be freezed.
     */
    function _freeze(address account) internal virtual whenNotFreezed(account) {
        _isFreezed[account] = true;
        emit Freezed(account, _msgSender());
    }

    /**
     * @dev Un-freezes an account.
     * @param account Address to be un-freezed.
     */
    function _unfreeze(address account) internal virtual whenFreezed(account) {
        _isFreezed[account] = false;
        emit Unfreezed(account, _msgSender());
    }

    /**
     * Checks if an account is freezed and reverts.
     * @param account Account to be checked
     */
    function _requireNotFreezed(address account) internal view {
        if (isFreezed(account)) {
            revert FreezedError();
        }
    }

    /**
     * Checks if an account is not freezed and reverts.
     * @param account Account to be checked
     */
    function _requireFreezed(address account) internal view {
        if (!isFreezed(account)) {
            revert NotFreezedError();
        }
    }

    uint256[49] private __gap;
}
