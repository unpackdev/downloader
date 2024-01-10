// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./AccessControlUpgradeable.sol";
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
    uint256[] private _tiersMinAmount;

    /**
     * @dev Emitted when tiers amount are changed
     */
    event TiersMinAmountChange(uint256[] amounts);

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
        uint256 balance = depositOf(account);
        uint256 max = _tiersMinAmount.length;

        for (uint256 i = 0; i < max; i++) {
            if (balance < _tiersMinAmount[i]) return int256(i) - 1;
        }

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

    uint256[50] private __gap;
}
