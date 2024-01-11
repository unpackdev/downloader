// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./PoolDepositable.sol";
import "./Tierable.sol";
import "./Suspendable.sol";
import "./PoolVestingDepositable.sol";

/** @title LockedLBToken.
 * @dev PoolDepositable contract implementation with tiers
 */
contract LockedLBToken is
    Initializable,
    PoolDepositable,
    Tierable,
    Suspendable,
    PoolVestingDepositable
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
        __PoolVestingable_init_unchained();
        __PoolVestingDepositable_init_unchained();
        __LockedLBToken_init_unchained();
    }

    function __LockedLBToken_init_unchained() internal onlyInitializing {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function _deposit(
        address,
        address,
        uint256
    )
        internal
        pure
        override(PoolDepositable, Depositable, PoolVestingDepositable)
        returns (uint256)
    {
        revert("LockedLBToken: Must deposit with poolIndex");
    }

    function _withdraw(address, uint256)
        internal
        pure
        override(PoolDepositable, Depositable, PoolVestingDepositable)
        returns (uint256)
    {
        revert("LockedLBToken: Must withdraw with poolIndex");
    }

    function _withdraw(
        address,
        uint256,
        uint256
    )
        internal
        pure
        override(PoolDepositable, PoolVestingDepositable)
        returns (uint256)
    {
        revert("LockedLBToken: Must withdraw with on a specific pool type");
    }

    /**
     * @notice Deposit amount token in pool at index `poolIndex` to the sender address balance
     */
    function deposit(uint256 amount, uint256 poolIndex) external whenNotPaused {
        PoolDepositable._deposit(_msgSender(), _msgSender(), amount, poolIndex);
    }

    /**
     * @notice Withdraw amount token in pool at index `poolIndex` from the sender address balance
     */
    function withdraw(uint256 amount, uint256 poolIndex)
        external
        whenNotPaused
    {
        PoolDepositable._withdraw(_msgSender(), amount, poolIndex);
    }

    /**
     * @notice Batch deposits into a vesting pool
     */
    function vestingBatchDeposits(
        address from,
        address[] memory to,
        uint256[] memory amounts,
        uint256 poolIndex
    ) external whenNotPaused onlyRole(DEFAULT_ADMIN_ROLE) {
        PoolVestingDepositable._batchDeposits(from, to, amounts, poolIndex);
    }

    /**
     * @notice Withdraw from a vesting pool
     */
    function vestingWithdraw(uint256 amount, uint256 poolIndex)
        external
        whenNotPaused
    {
        PoolVestingDepositable._withdraw(_msgSender(), amount, poolIndex);
    }

    /**
     * @notice Batch transfer amount from one vesting pool deposit to another
     */
    function transferVestingPoolDeposits(
        address[] calldata accounts,
        uint256[] calldata amounts,
        uint256 fromPoolIndex,
        uint256 toPoolIndex
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            accounts.length == amounts.length,
            "LockedLBToken: account and amounts length are not equal"
        );
        for (uint256 i = 0; i < accounts.length; i++) {
            PoolVestingDepositable._transferVestingPoolDeposit(
                accounts[i],
                amounts[i],
                fromPoolIndex,
                toPoolIndex
            );
        }
    }

    uint256[50] private __gap;
}
