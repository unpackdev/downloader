// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;
pragma abicoder v2;

import "./Initializable.sol";
import "./AccessControlUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./PoolVestingable.sol";
import "./Depositable.sol";

/** @title PoolVestingDepositable.
@dev This contract manage deposits in vesting pools
*/
abstract contract PoolVestingDepositable is
    Initializable,
    PoolVestingable,
    Depositable
{
    using SafeMathUpgradeable for uint256;

    struct UserVestingPoolDeposit {
        uint256 initialAmount; // initial amount deposited in the pool
        uint256 withdrawnAmount; // amount already withdrawn from the pool
    }

    // mapping of deposits for a user
    // user -> pool index -> user deposit
    mapping(address => mapping(uint256 => UserVestingPoolDeposit))
        private _poolDeposits;

    /**
     * @dev Emitted when a user deposit in a pool
     */
    event VestingPoolDeposit(
        address indexed from,
        address indexed to,
        uint256 amount,
        uint256 poolIndex
    );

    /**
     * @dev Emitted when a user withdraw from a pool
     */
    event VestingPoolWithdraw(
        address indexed to,
        uint256 amount,
        uint256 poolIndex
    );

    /**
     * @notice Initializer
     * @param _depositToken: the deposited token
     */
    function __PoolVestingDepositable_init(IERC20Upgradeable _depositToken)
        internal
        onlyInitializing
    {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
        __PoolVestingable_init_unchained();
        __Depositable_init_unchained(_depositToken);
        __PoolVestingDepositable_init_unchained();
    }

    function __PoolVestingDepositable_init_unchained()
        internal
        onlyInitializing
    {}

    /**
     * @dev returns the vested amount of a pool deposit
     */
    function _vestedAmountOf(address account, uint256 poolIndex)
        private
        view
        returns (uint256 vestedAmount)
    {
        VestingPool memory pool = getVestingPool(poolIndex);
        for (uint256 i = 0; i < pool.timestamps.length; i++) {
            if (block.timestamp >= pool.timestamps[i]) {
                // this schedule is reached, calculate its amount
                uint256 scheduleAmount = _poolDeposits[account][poolIndex]
                    .initialAmount
                    .mul(pool.ratiosPerHundredThousand[i])
                    .div(100000);
                // add it to vested amount
                vestedAmount = vestedAmount.add(scheduleAmount);
            }
        }
    }

    /**
     * @dev returns the amount that can be withdraw from a pool deposit
     */
    function _withdrawableAmountOf(address account, uint256 poolIndex)
        private
        view
        returns (uint256)
    {
        require(
            poolIndex < vestingPoolsLength(),
            "PoolVestingDepositable: Invalid poolIndex"
        );
        return
            _vestedAmountOf(account, poolIndex).sub(
                _poolDeposits[account][poolIndex].withdrawnAmount
            );
    }

    /**
     * @dev returns the list of pool deposits for an account
     */
    function vestingPoolDepositOf(address account, uint256 poolIndex)
        external
        view
        returns (UserVestingPoolDeposit memory)
    {
        require(
            poolIndex < vestingPoolsLength(),
            "PoolVestingDepositable: Invalid poolIndex"
        );
        return _poolDeposits[account][poolIndex];
    }

    /**
     * @dev returns vested amount of an account for a specific pool. Public version
     */
    function vestingPoolVestedAmountOf(address account, uint256 poolIndex)
        external
        view
        returns (uint256)
    {
        return _vestedAmountOf(account, poolIndex);
    }

    /**
     * @dev returns the amount that can be withdraw from a pool
     */
    function vestingPoolWithdrawableAmountOf(address account, uint256 poolIndex)
        external
        view
        returns (uint256)
    {
        return _withdrawableAmountOf(account, poolIndex);
    }

    // block the default implementation
    function _deposit(
        address,
        address,
        uint256
    ) internal pure virtual override returns (uint256) {
        revert("PoolVestingDepositable: Must deposit with poolIndex");
    }

    // block the default implementation
    function _withdraw(address, uint256)
        internal
        pure
        virtual
        override
        returns (uint256)
    {
        revert("PoolVestingDepositable: Must withdraw with poolIndex");
    }

    /**
     * @dev Deposit tokens to pool at `poolIndex`
     */
    function _savePoolDeposit(
        address from,
        address to,
        uint256 amount,
        uint256 poolIndex
    ) private {
        require(
            poolIndex < vestingPoolsLength(),
            "PoolVestingDepositable: Invalid poolIndex"
        );
        UserVestingPoolDeposit storage poolDeposit = _poolDeposits[to][
            poolIndex
        ];
        poolDeposit.initialAmount = poolDeposit.initialAmount.add(amount);
        emit VestingPoolDeposit(from, to, amount, poolIndex);
    }

    /**
     * @dev Batch deposit tokens to pool at `poolIndex`
     */
    function _batchDeposits(
        address from,
        address[] memory to,
        uint256[] memory amounts,
        uint256 poolIndex
    ) internal virtual returns (uint256) {
        require(
            to.length == amounts.length,
            "PoolVestingDepositable: arrays to and amounts have different length"
        );

        uint256 totalTransferredAmount = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            uint256 transferredAmount = Depositable._deposit(
                from,
                to[i],
                amounts[i]
            );
            _savePoolDeposit(from, to[i], transferredAmount, poolIndex);
            totalTransferredAmount = totalTransferredAmount.add(
                transferredAmount
            );
        }

        return totalTransferredAmount;
    }

    /**
     * @dev Withdraw tokens from pool at `poolIndex`
     */
    function _withdraw(
        address to,
        uint256 amount,
        uint256 poolIndex
    ) internal virtual returns (uint256) {
        require(
            poolIndex < vestingPoolsLength(),
            "PoolVestingDepositable: Invalid poolIndex"
        );
        UserVestingPoolDeposit storage poolDeposit = _poolDeposits[to][
            poolIndex
        ];
        uint256 withdrawableAmount = _withdrawableAmountOf(to, poolIndex);

        require(
            withdrawableAmount >= amount,
            "PoolVestingDepositable: Withdrawable amount less than amount to withdraw"
        );
        require(
            withdrawableAmount > 0,
            "PoolVestingDepositable: No withdrawable amount to withdraw"
        );

        uint256 withdrawAmount = Depositable._withdraw(to, amount);
        poolDeposit.withdrawnAmount = poolDeposit.withdrawnAmount.add(
            withdrawAmount
        );

        emit VestingPoolWithdraw(to, amount, poolIndex);
        return withdrawAmount;
    }

    uint256[50] private __gap;
}
