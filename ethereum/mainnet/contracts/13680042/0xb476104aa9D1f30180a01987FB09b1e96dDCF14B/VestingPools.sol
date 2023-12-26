// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC20.sol";

import "./Constants.sol";
import "./Types.sol";
import "./IMintable.sol";
import "./IVestingPools.sol";
import "./Claimable.sol";
import "./Linking.sol";
import "./SafeUints.sol";

/**
 * @title VestingPools
 * @notice It mints and vests a (mintable) ERC-20 token to "Vesting Pools".
 * @dev Each "Vesting Pool" (or a "pool") has a `wallet` and `PoolParams`.
 * The `wallet` requests vesting and receives vested tokens, or nominate
 * another address that receives them.
 * `PoolParams` deterministically define minting and unlocking schedule.
 * Once added, a pool can not be removed. Subject to strict limitations,
 * owner may update a few parameters of a pool.
 */
contract VestingPools is
    Ownable,
    Claimable,
    SafeUints,
    Constants,
    IVestingPools
{
    /// @notice Accumulated amount to be vested to all pools
    uint96 public totalAllocation;
    /// @notice Total amount already vested to all pools
    uint96 public totalVested;

    // ID of a pool (i.e. `poolId`) is the index in these two arrays
    address[] internal _wallets;
    PoolParams[] internal _pools;

    /// @inheritdoc IVestingPools
    function token() external view override returns (address) {
        return _getToken();
    }

    /// @inheritdoc IVestingPools
    function getWallet(uint256 poolId)
        external
        view
        override
        returns (address)
    {
        _throwInvalidPoolId(poolId);
        return _wallets[poolId];
    }

    /// @inheritdoc IVestingPools
    function getPool(uint256 poolId)
        external
        view
        override
        returns (PoolParams memory)
    {
        return _getPool(poolId);
    }

    /// @inheritdoc IVestingPools
    function releasableAmount(uint256 poolId)
        external
        view
        override
        returns (uint256)
    {
        PoolParams memory pool = _getPool(poolId);
        return _getReleasable(pool, _timeNow());
    }

    /// @inheritdoc IVestingPools
    function vestedAmount(uint256 poolId)
        external
        view
        override
        returns (uint256)
    {
        PoolParams memory pool = _getPool(poolId);
        return uint256(pool.vested);
    }

    /// @inheritdoc IVestingPools
    function release(uint256 poolId, uint256 amount)
        external
        override
        returns (uint256 released)
    {
        return _releaseTo(poolId, msg.sender, amount);
    }

    /// @inheritdoc IVestingPools
    function releaseTo(
        uint256 poolId,
        address account,
        uint256 amount
    ) external override returns (uint256 released) {
        _throwZeroAddress(account);
        return _releaseTo(poolId, account, amount);
    }

    /// @inheritdoc IVestingPools
    function updatePoolWallet(uint256 poolId, address newWallet)
        external
        override
    {
        _throwZeroAddress(newWallet);
        _throwUnauthorizedWallet(poolId, msg.sender);

        _wallets[poolId] = newWallet;
        emit WalletUpdated(poolId, newWallet);
    }

    /// @inheritdoc IVestingPools
    function addVestingPools(
        address[] memory wallets,
        PoolParams[] memory pools
    ) external override onlyOwner {
        require(wallets.length == pools.length, "VPools: length mismatch");

        uint256 timeNow = _timeNow();
        IMintable theToken = IMintable(_getToken());
        uint256 updAllocation = uint256(totalAllocation);
        uint256 preMinted = 0;
        uint256 poolId = _pools.length;
        for (uint256 i = 0; i < wallets.length; i++) {
            _throwZeroAddress(wallets[i]);
            require(pools[i].start >= timeNow, "VPools: start already passed");
            require(pools[i].sAllocation != 0, "VPools: zero sAllocation");
            require(
                pools[i].sAllocation >= pools[i].sUnlocked,
                "VPools: too big sUnlocked"
            );
            require(pools[i].vested == 0, "VPools: zero vested expected");

            uint256 allocation = uint256(pools[i].sAllocation) * SCALE;
            updAllocation += allocation;

            _wallets.push(wallets[i]);
            _pools.push(pools[i]);
            emit PoolAdded(poolId++, wallets[i], allocation);

            if (pools[i].isPreMinted) {
                preMinted += allocation;
            }
        }
        // left outside the cycle to save gas for a non-reverting transaction
        require(updAllocation <= MAX_SUPPLY, "VPools: supply exceeded");
        totalAllocation = _safe96(updAllocation);

        if (preMinted != 0) {
            require(theToken.mint(address(this), preMinted), "VPools:E5");
        }
    }

    /// @inheritdoc IVestingPools
    /// @dev Vesting schedule for a pool may be significantly altered by this.
    /// However, pool allocation (i.e. token amount to vest) remains unchanged.
    function updatePoolTime(
        uint256 poolId,
        uint32 start,
        uint16 vestingDays
    ) external override onlyOwner {
        PoolParams memory pool = _getPool(poolId);

        require(pool.isAdjustable, "VPools: non-adjustable");
        require(
            uint256(pool.sAllocation) * SCALE > uint256(pool.vested),
            "VPools: fully vested"
        );
        uint256 end = uint256(start) + uint256(vestingDays) * 1 days;
        // `end` may NOT be in the past, unlike `start` that may be even zero
        require(_timeNow() > end, "VPools: too late updates");

        pool.start = start;
        pool.vestingDays = vestingDays;
        _pools[poolId] = pool;

        emit PoolUpdated(poolId, start, vestingDays);
    }

    /**
     * @notice Withdraws accidentally sent token from this contract.
     * @dev Owner may call only.
     */
    function claimErc20(
        address claimedToken,
        address to,
        uint256 amount
    ) external onlyOwner nonReentrant {
        IERC20 vestedToken = IERC20(_getToken());
        if (claimedToken == address(vestedToken)) {
            uint256 actual = vestedToken.balanceOf(address(this));
            uint256 expected = vestedToken.totalSupply() - totalVested;
            require(actual >= expected + amount, "VPools: too big amount");
        }
        _claimErc20(claimedToken, to, amount);
    }

    /// @notice Removes the contract from blockchain if there is no tokens to vest.
    /// @dev Owner may call only.
    function removeContract() external onlyOwner {
        // intended "strict comparison"
        require(totalAllocation == totalVested, "VPools:E1");
        selfdestruct(payable(msg.sender));
    }

    //////////////////
    //// Internal ////
    //////////////////

    /// @dev Returns token contract address
    // (declared `view` rather than `pure` to facilitate testing)
    function _getToken() internal view virtual returns (address) {
        return address(TokenAddress);
    }

    /// @dev Returns pool params for the pool with the given ID
    function _getPool(uint256 poolId)
        internal
        view
        returns (PoolParams memory)
    {
        _throwInvalidPoolId(poolId);
        return _pools[poolId];
    }

    /// @dev Returns amount that may be released now for the pool given
    function _getReleasable(PoolParams memory pool, uint256 timeNow)
        internal
        pure
        returns (uint256)
    {
        if (timeNow < pool.start) return 0;

        uint256 allocation = uint256(pool.sAllocation) * SCALE;
        if (pool.vested >= allocation) return 0;

        uint256 releasable = allocation - uint256(pool.vested);
        uint256 duration = uint256(pool.vestingDays) * 1 days;
        uint256 end = uint256(pool.start) + duration;
        if (timeNow < end) {
            uint256 unlocked = uint256(pool.sUnlocked) * SCALE;
            uint256 locked = ((allocation - unlocked) * (end - timeNow)) /
                duration; // can't be 0 here

            releasable = locked > releasable ? 0 : releasable - locked;
        }

        return releasable;
    }

    /// @dev Vests from the pool the given or releasable amount to the given address
    function _releaseTo(
        uint256 poolId,
        address to,
        uint256 amount
    ) internal returns (uint256 released) {
        PoolParams memory pool = _getPool(poolId);
        _throwUnauthorizedWallet(poolId, msg.sender);

        uint256 releasable = _getReleasable(pool, _timeNow());
        require(releasable >= amount, "VPools: not enough to release");

        released = amount == 0 ? releasable : amount;

        _pools[poolId].vested = _safe96(released + uint256(pool.vested));
        totalVested = _safe96(released + uint256(totalVested));

        // reentrancy impossible (known contract called)
        if (pool.isPreMinted) {
            require(IERC20(_getToken()).transfer(to, released), "VPools:E6");
        } else {
            require(IMintable(_getToken()).mint(to, released), "VPools:E7");
        }
        emit Released(poolId, to, released);
    }

    function _throwZeroAddress(address account) private pure {
        require(account != address(0), "VPools: zero address(account|wallet)");
    }

    function _throwInvalidPoolId(uint256 poolId) private view {
        require(poolId < _pools.length, "VPools: invalid pool id");
    }

    function _throwUnauthorizedWallet(uint256 poolId, address wallet)
        private
        view
    {
        _throwZeroAddress(wallet);
        require(_wallets[poolId] == wallet, "VPools: unauthorized");
    }

    /// @dev Returns the current block timestamp (added to ease testing)
    function _timeNow() internal view virtual returns (uint256) {
        return block.timestamp;
    }
}
