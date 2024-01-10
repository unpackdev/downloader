// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./PoolDepositable.sol";
import "./Tierable.sol";
import "./Suspendable.sol";

/** @title LockedLBToken.
 * @dev PoolDepositable contract implementation with tiers
 */
contract LockedLBToken is
    Initializable,
    PoolDepositable,
    Tierable,
    Suspendable
{
    /**
     * @notice Initializer
     * @param _depositToken: the deposited token
     * @param tiersMinAmount: the tiers min amount
     * @param _pauser: the address of the account granted with PAUSER_ROLE
     */
    function initialize(
        IERC20Upgradeable _depositToken,
        uint256[] memory tiersMinAmount,
        address _pauser
    ) external initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
        __Poolable_init_unchained();
        __Depositable_init_unchained(_depositToken);
        __PoolDepositable_init_unchained();
        __Tierable_init_unchained(tiersMinAmount);
        __Pausable_init_unchained();
        __Suspendable_init_unchained(_pauser);
        __LockedLBToken_init_unchained();
    }

    function __LockedLBToken_init_unchained() internal onlyInitializing {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function _deposit(
        address from,
        address to,
        uint256 amount
    ) internal pure override(PoolDepositable, Depositable) returns (uint256) {
        return PoolDepositable._deposit(from, to, amount);
    }

    function _withdraw(address to, uint256 amount)
        internal
        pure
        override(PoolDepositable, Depositable)
        returns (uint256)
    {
        return PoolDepositable._withdraw(to, amount);
    }

    /**
     * @notice Deposit amount token in pool at index `poolIndex` to the sender address balance
     */
    function deposit(uint256 amount, uint256 poolIndex) external whenNotPaused {
        _deposit(_msgSender(), _msgSender(), amount, poolIndex);
    }

    /**
     * @notice Withdraw amount token in pool at index `poolIndex` from the sender address balance
     */
    function withdraw(uint256 amount, uint256 poolIndex)
        external
        whenNotPaused
    {
        _withdraw(_msgSender(), amount, poolIndex);
    }

    uint256[50] private __gap;
}
