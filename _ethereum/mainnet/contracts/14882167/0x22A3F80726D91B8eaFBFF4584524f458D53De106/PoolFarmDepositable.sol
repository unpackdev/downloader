// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;
pragma abicoder v2;

import "./Initializable.sol";
import "./AccessControlUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./MathUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./PoolFarmable.sol";
import "./Depositable.sol";
import "./ITierable.sol";

/** @title PoolFarmDepositable.
@dev This contract manage deposits in farm pools
*/
abstract contract PoolFarmDepositable is
    Initializable,
    AccessControlUpgradeable,
    PoolFarmable,
    Depositable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;

    struct UserFarmPoolDeposit {
        uint256 amount; // amount deposited in the pool
        uint256 date; // date of the deposit
    }

    // mapping of deposits for a user
    // user -> pool index -> array of user deposit
    mapping(address => mapping(uint256 => UserFarmPoolDeposit[]))
        private _poolDeposits;

    // mapping of total deposits per pool
    // pool index -> total deposit
    mapping(uint256 => uint256) private _poolTotalDeposits;

    // tier contract
    ITierable public tier;

    // wallet to take interest from
    address public interestWallet;

    /**
     * @dev Emitted when a user deposit in a pool
     */
    event FarmPoolDeposit(
        address indexed from,
        address indexed to,
        uint256 indexed poolIndex,
        uint256 depositIndex,
        uint256 amount
    );

    /**
     * @dev Emitted when a user withdraw from a pool
     */
    event FarmPoolWithdraw(
        address indexed from,
        address indexed to,
        uint256 indexed poolIndex,
        uint256 depositIndex,
        uint256 amount,
        uint256 interest
    );

    /**
     * @notice Initializer
     * @param _depositToken: the deposited token
     */
    function __PoolFarmDepositable_init(
        IERC20Upgradeable _depositToken,
        ITierable _tier,
        address _interestWallet
    ) internal onlyInitializing {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
        __PoolFarmable_init_unchained();
        __Depositable_init_unchained(_depositToken);
        __PoolFarmDepositable_init_unchained(_tier, _interestWallet);
    }

    function __PoolFarmDepositable_init_unchained(
        ITierable _tier,
        address _interestWallet
    ) internal onlyInitializing {
        tier = _tier;
        interestWallet = _interestWallet;
    }

    /**
     * @dev returns the deposit of an account in a pool
     */
    function farmPoolDepositOf(address account, uint256 poolIndex)
        public
        view
        checkFarmPoolIndex(poolIndex)
        returns (UserFarmPoolDeposit memory)
    {
        // Hardcoded deposit index of zero for now. Multi-deposit feature will come later.
        uint256 depositIndex = 0;

        // assert deposit exist
        require(
            _poolDeposits[account][poolIndex].length > depositIndex,
            "PoolFarmDepositable: Deposit in this pool not found"
        );

        return _poolDeposits[account][poolIndex][depositIndex];
    }

    /**
     * @dev returns the interest of a user deposit
     */
    function farmPoolInterestOf(address account, uint256 poolIndex)
        public
        view
        returns (uint256)
    {
        FarmPool memory pool = getFarmPool(poolIndex);
        UserFarmPoolDeposit memory deposit = farmPoolDepositOf(
            account,
            poolIndex
        );

        // deposit duration = diff between now and deposit date
        // capped to pool max deposit duration
        uint256 depositDuration = MathUpgradeable.min(
            block.timestamp.sub(deposit.date),
            pool.maxDepositDuration
        );

        // interest = deposit amount * deposit duration * pool interest numerator / pool interest denominator
        uint256 interest = deposit
            .amount
            .mul(depositDuration)
            .mul(pool.interestNumerator)
            .div(pool.interestDenominator);
        return interest;
    }

    /**
     * @dev returns the total amount deposited in a pool
     */
    function farmPoolTotalDepositOfPool(uint256 poolIndex)
        public
        view
        checkFarmPoolIndex(poolIndex)
        returns (uint256)
    {
        return _poolTotalDeposits[poolIndex];
    }

    /**
     * @dev Batch deposit tokens to pool at `poolIndex`
     */
    function _deposit(
        address from,
        address to,
        uint256 amount,
        uint256 poolIndex
    ) internal virtual checkFarmPoolIndex(poolIndex) returns (uint256) {
        // get farm pool
        FarmPool memory pool = getFarmPool(poolIndex);

        // check opened
        require(pool.opened, "PoolFarmDepositable: Pool is closed");

        // check maxUserDepositAmount
        require(
            amount <= pool.maxUserDepositAmount,
            "PoolFarmDepositable: Amount to deposit is more than the pool max deposit per user"
        );

        // check tier of to address
        int256 userTier = tier.tierOf(to);
        require(
            userTier >= pool.minTier,
            "PoolFarmDepositable: Tier of the to address is less than required by the pool"
        );

        // transfer amount
        uint256 transferredAmount = Depositable._deposit(from, to, amount);

        if (_poolDeposits[to][poolIndex].length > 0) {
            // Hardcoded deposit index of zero for now. Multi-deposit feature will come later.
            uint256 depositIndex = 0;

            // update user deposit
            UserFarmPoolDeposit storage deposit = _poolDeposits[to][poolIndex][
                depositIndex
            ];

            // assert no previous deposit or previous deposit was fully withdraw
            require(
                deposit.amount == 0,
                "PoolFarmDepositable: Already deposited in this pool"
            );

            deposit.amount = deposit.amount.add(transferredAmount);
            deposit.date = block.timestamp;
        } else {
            // add user deposit
            _poolDeposits[to][poolIndex].push(
                UserFarmPoolDeposit({
                    amount: transferredAmount,
                    date: block.timestamp
                })
            );
        }

        // update total amount deposited in pool
        _poolTotalDeposits[poolIndex] = _poolTotalDeposits[poolIndex].add(
            transferredAmount
        );

        // check maxTotalDepositAmount. requires transferredAmount.
        require(
            _poolTotalDeposits[poolIndex] <= pool.maxTotalDepositAmount,
            "PoolFarmDepositable: Pool max total deposit amount surpassed with this deposit"
        );

        // emit event
        emit FarmPoolDeposit(
            from,
            to,
            poolIndex,
            _poolDeposits[to][poolIndex].length - 1,
            transferredAmount
        );

        // return transferred amount
        return transferredAmount;
    }

    /**
     * @dev Withdraw tokens from a pool with interest
     */
    function _withdraw(
        address from,
        address to,
        uint256 amount,
        uint256 poolIndex
    ) internal virtual checkFarmPoolIndex(poolIndex) returns (uint256) {
        // get farm pool
        FarmPool memory pool = getFarmPool(poolIndex);

        // Hardcoded deposit index of zero for now. Multi-deposit feature will come later.
        uint256 depositIndex = 0;

        // assert deposit exist
        require(
            _poolDeposits[to][poolIndex].length > depositIndex,
            "PoolFarmDepositable: Deposit in this pool not found"
        );

        // get user deposit
        UserFarmPoolDeposit storage deposit = _poolDeposits[to][poolIndex][
            depositIndex
        ];

        // check deposit duration is more than or equal to pool's min deposit duration
        uint256 depositDuration = block.timestamp.sub(deposit.date);
        require(
            depositDuration >= pool.minDepositDuration,
            "PoolFarmDepositable: Deposit duration is less than pool min deposit duration"
        );

        // check amount is less or equal to deposit amount
        require(
            amount <= deposit.amount,
            "PoolFarmDepositable: Amount to withdraw is more than the deposited amount"
        );

        // calculate interest
        uint256 interest = farmPoolInterestOf(from, poolIndex);

        // transfer amount
        uint256 withdrawAmount = Depositable._withdraw(to, amount);

        // transfer interest
        depositToken.safeTransferFrom(interestWallet, to, interest);

        // subtract amount from user deposit
        deposit.amount = deposit.amount.sub(withdrawAmount);

        // subtract amount from total pool deposit
        _poolTotalDeposits[poolIndex] = _poolTotalDeposits[poolIndex].sub(
            withdrawAmount
        );

        // emit event
        emit FarmPoolWithdraw(
            from,
            to,
            poolIndex,
            depositIndex,
            withdrawAmount,
            interest
        );

        // return withdraw amount
        return withdrawAmount;
    }

    /**
     * @dev Update the interest wallet
     */
    function updateInterestWallet(address _interestWallet)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        interestWallet = _interestWallet;
    }

    uint256[50] private __gap;
}
