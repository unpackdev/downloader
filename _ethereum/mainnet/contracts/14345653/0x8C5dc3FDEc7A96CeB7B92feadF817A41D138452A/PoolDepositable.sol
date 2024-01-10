// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;
pragma abicoder v2;

import "./Initializable.sol";
import "./AccessControlUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./Poolable.sol";
import "./Depositable.sol";

/** @title PoolDepositable.
@dev This contract manage pool of deposits
*/
abstract contract PoolDepositable is
    Initializable,
    AccessControlUpgradeable,
    Poolable,
    Depositable
{
    using SafeMathUpgradeable for uint256;

    struct UserPoolDeposit {
        uint256 poolIndex; // index of the pool
        uint256 amount; // amount deposited in the pool
        uint256 depositDate; // date of last deposit
    }

    struct BatchDeposit {
        address to; // destination address
        uint256 amount; // amount deposited
        uint256 poolIndex; // index of the pool
    }

    // mapping of deposits for a user
    mapping(address => UserPoolDeposit[]) private _poolDeposits;

    /**
     * @dev Emitted when a user deposit in a pool
     */
    event PoolDeposit(
        address indexed from,
        address indexed to,
        uint256 amount,
        uint256 poolIndex
    );

    /**
     * @dev Emitted when a user withdraw from a pool
     */
    event PoolWithdraw(address indexed to, uint256 amount, uint256 poolIndex);

    /**
     * @notice Initializer
     * @param _depositToken: the deposited token
     */
    function __PoolDepositable_init(IERC20Upgradeable _depositToken)
        internal
        onlyInitializing
    {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
        __Poolable_init_unchained();
        __Depositable_init_unchained(_depositToken);
        __PoolDepositable_init_unchained();
    }

    function __PoolDepositable_init_unchained() internal onlyInitializing {}

    /**
     * @dev returns the index of a user's pool deposit (`UserPoolDeposit`) for the specified pool at index `poolIndex`
     */
    function _indexOfPoolDeposit(address account, uint256 poolIndex)
        private
        view
        returns (int256)
    {
        for (uint256 i = 0; i < _poolDeposits[account].length; i++) {
            if (_poolDeposits[account][i].poolIndex == poolIndex) {
                return int256(i);
            }
        }
        return -1;
    }

    /**
     * @dev returns the list of pool deposits for an account
     */
    function poolDepositsOf(address account)
        public
        view
        returns (UserPoolDeposit[] memory)
    {
        return _poolDeposits[account];
    }

    /**
     * @dev returns the list of pool deposits for an account
     */
    function poolDepositOf(address account, uint256 poolIndex)
        external
        view
        returns (UserPoolDeposit memory poolDeposit)
    {
        int256 depositIndex = _indexOfPoolDeposit(account, poolIndex);
        if (depositIndex > -1) {
            poolDeposit = _poolDeposits[account][uint256(depositIndex)];
        }
    }

    // block the default implementation
    function _deposit(
        address,
        address,
        uint256
    ) internal pure virtual override returns (uint256) {
        revert("PoolDepositable: Must deposit with poolIndex");
    }

    // block the default implementation
    function _withdraw(address, uint256)
        internal
        pure
        virtual
        override
        returns (uint256)
    {
        revert("PoolDepositable: Must withdraw with poolIndex");
    }

    /**
     * @dev Deposit tokens to pool at `poolIndex`
     */
    function _deposit(
        address from,
        address to,
        uint256 amount,
        uint256 poolIndex
    ) internal virtual whenPoolOpened(poolIndex) returns (uint256) {
        uint256 depositAmount = super._deposit(from, to, amount);

        int256 depositIndex = _indexOfPoolDeposit(to, poolIndex);
        if (depositIndex > -1) {
            UserPoolDeposit storage pool = _poolDeposits[to][
                uint256(depositIndex)
            ];
            pool.amount = pool.amount.add(depositAmount);
            pool.depositDate = block.timestamp; // update date to last deposit
        } else {
            _poolDeposits[to].push(
                UserPoolDeposit({
                    poolIndex: poolIndex,
                    amount: depositAmount,
                    depositDate: block.timestamp
                })
            );
        }

        emit PoolDeposit(from, to, amount, poolIndex);
        return depositAmount;
    }

    /**
     * @dev Withdraw tokens from a specific pool
     */
    function _withdrawPoolDeposit(
        address to,
        uint256 amount,
        UserPoolDeposit storage poolDeposit
    )
        private
        whenUnlocked(poolDeposit.poolIndex, poolDeposit.depositDate)
        returns (uint256)
    {
        require(
            poolDeposit.amount >= amount,
            "PoolDepositable: Pool deposit less than amount"
        );
        require(poolDeposit.amount > 0, "PoolDepositable: No deposit in pool");

        uint256 withdrawAmount = super._withdraw(to, amount);
        poolDeposit.amount = poolDeposit.amount.sub(withdrawAmount);

        emit PoolWithdraw(to, amount, poolDeposit.poolIndex);
        return withdrawAmount;
    }

    /**
     * @dev Withdraw tokens from pool at `poolIndex`
     */
    function _withdraw(
        address to,
        uint256 amount,
        uint256 poolIndex
    ) internal virtual returns (uint256) {
        int256 depositIndex = _indexOfPoolDeposit(to, poolIndex);
        require(depositIndex > -1, "PoolDepositable: Not deposited");
        return
            _withdrawPoolDeposit(
                to,
                amount,
                _poolDeposits[to][uint256(depositIndex)]
            );
    }

    /**
     * @dev Batch deposits token in pools
     */
    function batchDeposits(address from, BatchDeposit[] memory deposits)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        for (uint256 i = 0; i < deposits.length; i++) {
            _deposit(
                from,
                deposits[i].to,
                deposits[i].amount,
                deposits[i].poolIndex
            );
        }
    }

    uint256[50] private __gap;
}
