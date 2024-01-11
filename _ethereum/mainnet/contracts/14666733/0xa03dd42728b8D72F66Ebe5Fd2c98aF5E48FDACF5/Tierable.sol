// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./AccessControlUpgradeable.sol";
import "./EnumerableSet.sol";
import "./Depositable.sol";
import "./ITierable.sol";

/** @title Tierable.
 * @dev Depositable contract implementation with tiers
 */
abstract contract Tierable is
    Initializable,
    AccessControlUpgradeable,
    Depositable,
    ITierable
{
    using EnumerableSet for EnumerableSet.AddressSet;

    uint256[] private _tiersMinAmount;
    EnumerableSet.AddressSet private _whitelist;

    /**
     * @dev Emitted when tiers amount are changed
     */
    event TiersMinAmountChange(uint256[] amounts);

    /**
     * @dev Emitted when a new account is added to the whitelist
     */
    event AddToWhitelist(address account);

    /**
     * @dev Emitted when an account is removed from the whitelist
     */
    event RemoveFromWhitelist(address account);

    /**
     * @notice Initializer
     * @param _depositToken: the deposited token
     * @param tiersMinAmount: the tiers min amount
     */
    function __Tierable_init(
        IERC20Upgradeable _depositToken,
        uint256[] memory tiersMinAmount
    ) internal onlyInitializing {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
        __Depositable_init_unchained(_depositToken);
        __Tierable_init_unchained(tiersMinAmount);
    }

    function __Tierable_init_unchained(uint256[] memory tiersMinAmount)
        internal
        onlyInitializing
    {
        _tiersMinAmount = tiersMinAmount;
    }

    /**
     * @dev Returns the index of the tier for `account`
     * @notice returns -1 if the total deposit of `account` is below the first tier
     */
    function tierOf(address account) public view override returns (int256) {
        // set max tier
        uint256 max = _tiersMinAmount.length;

        // check if account in whitelist
        if (_whitelist.contains(account)) {
            // return max tier
            return int256(max) - 1;
        }

        // check balance of account
        uint256 balance = depositOf(account);
        for (uint256 i = 0; i < max; i++) {
            // return its tier
            if (balance < _tiersMinAmount[i]) return int256(i) - 1;
        }
        // return max tier if balance more than last tiersMinAmount
        return int256(max) - 1;
    }

    /**
     * @notice update the tiers brackets
     * Only callable by owners
     */
    function changeTiersMinAmount(uint256[] memory tiersMinAmount)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _tiersMinAmount = tiersMinAmount;
        emit TiersMinAmountChange(_tiersMinAmount);
    }

    /**
     * @notice returns the list of min amount per tier
     */
    function getTiersMinAmount() external view returns (uint256[] memory) {
        return _tiersMinAmount;
    }

    /**
     * @notice Add new accounts to the whitelist
     * Only callable by owners
     */
    function addToWhitelist(address[] memory accounts)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        for (uint256 i = 0; i < accounts.length; i++) {
            bool result = _whitelist.add(accounts[i]);
            if (result) emit AddToWhitelist(accounts[i]);
        }
    }

    /**
     * @notice Remove an account from the whitelist
     * Only callable by owners
     */
    function removeFromWhitelist(address[] memory accounts)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        for (uint256 i = 0; i < accounts.length; i++) {
            bool result = _whitelist.remove(accounts[i]);
            if (result) emit RemoveFromWhitelist(accounts[i]);
        }
    }

    /**
     * @notice Remove accounts from whitelist
     * Only callable by owners
     */
    function getWhitelist()
        external
        view
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (address[] memory)
    {
        return _whitelist.values();
    }

    uint256[50] private __gap;
}
