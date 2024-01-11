// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./CartPoolBase.sol";
import "./IFactory.sol";

/**
 * @title CART Core Pool
 *
 * @notice Core pools represent permanent pools like CART or CART/ETH Pair pool,
 *      core pools allow staking for arbitrary periods of time up to 1 year
 *
 * @dev See CartPoolBase for more details
 *
 */
contract CartCorePool is CartPoolBase {
    /// @dev Flag indicating pool type, false means "core pool"
    bool public constant override isFlashPool = false;

    /// @dev Pool tokens value available in the pool;
    ///      pool token examples are CART (CART core pool) or CART/ETH pair (LP core pool)
    /// @dev For LP core pool
    ///      while for CART core pool it does count for such tokens as well
    uint256 public poolTokenReserve;

    /**
     * @dev Creates/deploys an instance of the core pool
     *
     * @param _cart CART ERC20 Token IlluviumERC20 address
     * @param _factory Pool factory CartPoolFactory address
     * @param _poolToken token the pool operates on, for example CART or CART/ETH pair
     * @param _weight number representing a weight of the pool, actual weight fraction
     *      is calculated as that number divided by the total pools weight and doesn't exceed one
     */
    constructor(
        address _cart,
        address _factory,
        address _poolToken,
        uint256 _weight
    ) CartPoolBase(_cart, _factory, _poolToken, _weight) {}

    /**
     * @notice Service function to calculate
     *
     * @dev Internally executes similar function `_processRewards` from the parent smart contract
     *      to calculate and pay yield rewards
     *
     * @dev Can be executed by anyone at any time, but has an effect only when
     *      executed by deposit holder and when at least one block passes from the
     *      previous reward processing
     * @dev Executed internally when "staking as a pool" (`stakeAsPool`)
     * @dev When timing conditions are not met (executed too frequently, or after factory
     *      end block), function doesn't throw and exits silently
     *
     * @dev Reentrancy safety enforced via `ReentrancyGuard.nonReentrant`
     *
     */
    function processRewards() external override nonReentrant{
        _processRewards(msg.sender, true);
        User storage user = users[msg.sender];
    }

    /**
     * @dev Executed internally by the pool itself (from the parent `CartPoolBase` smart contract)
     *      as part of yield rewards processing logic (`CartPoolBase._processRewards` function)
     *
     * @dev Because the reward in all pools should be regarded as a yield staking in CART token pool
     *      thus this function can only be excecuted within CART token pool
     *
     * @param _staker an address which stakes (the yield reward)
     * @param _amount amount to be staked (yield reward amount)
     */
    function stakeAsPool(address _staker, uint256 _amount) external {
        require(IFactory(factory).isPoolExists(msg.sender), "access denied");
        require(poolToken == CART, "not CART token pool");

        _sync();
        User storage user = users[_staker];
        if (user.tokenAmount > 0) {
            _processRewards(_staker, false);
        }
        // if length of deposits is zero, then push zero value of unlocked deposit
        if (user.deposits.length == 0) {
            // create zero value of unlocked deposit and save the deposit (append it to deposits array)
            Deposit memory unlockedDeposit =
                Deposit({
                    tokenAmount: 0,
                    weight: 0,
                    lockedFrom: 0,
                    lockedUntil: 0,
                    isYield: false
                });
            user.deposits.push(unlockedDeposit);
        }
        // staking for a year, stakeWeight should be 2
        uint256 depositWeight = _amount * 2 * weightMultiplier;
        Deposit memory newDeposit =
            Deposit({
                tokenAmount: _amount,
                lockedFrom: uint64(now256()),
                lockedUntil: uint64(now256() + 365 days),
                weight: depositWeight,
                isYield: true
            });
        user.tokenAmount += _amount;
        user.rewardAmount += _amount;
        user.totalWeight += depositWeight;
        user.deposits.push(newDeposit);

        usersLockingWeight += depositWeight;

        user.subYieldRewards = weightToReward(user.totalWeight, yieldRewardsPerWeight);

        // update `poolTokenReserve` only if this is a LP Core Pool (stakeAsPool can be executed only for LP pool)
        poolTokenReserve += _amount;
    }
    
    /**
     * @inheritdoc CartPoolBase
     *
     * @dev Additionally to the parent smart contract
     *      and updates (increases) pool token reserve (pool tokens value available in the pool)
     */
    function _stake(
        address _staker,
        uint256 _amount,
        uint64 _lockPeriod,
        address _nftAddress,
        uint256 _nftTokenId
    ) internal override {
        super._stake(_staker, _amount, _lockPeriod, _nftAddress, _nftTokenId);
        User storage user = users[_staker];

        poolTokenReserve += _amount;
    }

    /**
     * @inheritdoc CartPoolBase
     *
     * @dev Additionally to the parent smart contract
     *      and updates (decreases) pool token reserve (pool tokens value available in the pool)
     */
    function _unstake(
        address _staker,
        uint256 _depositId,
        uint256 _amount
    ) internal override {
        User storage user = users[_staker];
        Deposit memory stakeDeposit = user.deposits[_depositId];
        require(stakeDeposit.lockedFrom == 0 || now256() > stakeDeposit.lockedUntil, "deposit not yet unlocked");
        poolTokenReserve -= _amount;
        super._unstake(_staker, _depositId, _amount);
    }

    /**
     * @inheritdoc CartPoolBase
     *
     * @dev Additionally to the parent smart contract
     *      and updates (decreases) pool token reserve (pool tokens value available in the pool)
     */
    function _emergencyWithdraw(
        address _staker
    ) internal override {
        User storage user = users[_staker];
        uint256 amount = user.tokenAmount;

        poolTokenReserve -= amount;
        super._emergencyWithdraw(_staker);
    }

    /**
     * @inheritdoc CartPoolBase
     *
     * @dev Additionally to the parent smart contract
     *      and for CART pool updates (increases) pool token reserve (pool tokens value available in the pool)
     */
    function _processRewards(
        address _staker,
        bool _withUpdate
    ) internal override returns (uint256 pendingYield) {
        pendingYield = super._processRewards(_staker, _withUpdate);
    }

    /**
     * @dev Executes SafeERC20.safeTransfer on a CART token
     *
     */
    function transferCartToken(address _to, uint256 _value) internal {
        // just delegate call to the target
        SafeERC20.safeTransfer(IERC20(CART), _to, _value);
    }

    /**
     * @dev Executes SafeERC20.safeTransferFrom on a CART token
     *
     */
    function transferCartTokenFrom(
        address _from,
        address _to,
        uint256 _value
    ) internal {
        // just delegate call to the target
        SafeERC20.safeTransferFrom(IERC20(CART), _from, _to, _value);
    }
}