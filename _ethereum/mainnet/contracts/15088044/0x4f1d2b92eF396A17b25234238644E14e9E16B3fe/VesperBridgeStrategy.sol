// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IController.sol";
import "./Strategy.sol";
import "./ISwapManager.sol";
import "./IVesperPoolV5.sol";
import "./IStrategyV4.sol";
import "./IPoolRewardsV4.sol";

/// @title This strategy will deposit collateral token in Vesper V5(and up) and earn interest.
contract VesperBridgeStrategy is Strategy {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    string public constant NAME = "VesperBridgeStrategy";
    string public constant VERSION = "2.1.0";

    address public constant VSP = 0x1b40183EFB4Dd766f11bDa7A7c3AD8982e998421;
    IVesperPoolV5 internal immutable vToken;

    constructor(
        address _controller,
        address _pool,
        address _receiptToken
    ) public Strategy(_controller, _pool, _receiptToken) {
        vToken = IVesperPoolV5(_receiptToken);
    }

    /**
     * @notice Migrate tokens from pool to this address
     * @dev Any working VesperV5 strategy has vTokens in strategy contract.
     * @dev There can be scenarios when pool already has vTokens and new
     * strategy will have to move those tokens from pool to self address.
     * @dev Only valid pool strategy is allowed to move tokens from pool.
     */
    function _migrateIn() internal override {
        require(controller.isPool(pool), "not-a-valid-pool");
        require(controller.strategy(pool) == address(this), "not-a-valid-strategy");
        IERC20(vToken).safeTransferFrom(pool, address(this), vToken.balanceOf(pool));
    }

    /**
     * @notice Migrate tokens out to pool.
     * @dev There can be scenarios when we want to use new strategy without
     * calling withdrawAll(). We can achieve this by moving tokens in pool
     * and new strategy will take care from there.
     * @dev Pause this strategy and move tokens out.
     */
    function _migrateOut() internal override {
        require(controller.isPool(pool), "not-a-valid-pool");
        _pause();
        IERC20(vToken).safeTransfer(pool, vToken.balanceOf(address(this)));
    }

    /// @notice Vesper pools are using this function so it should exist in all strategies.
    //solhint-disable-next-line no-empty-blocks
    function beforeWithdraw() external override onlyPool {}

    /**
     * @dev Claim VSP rewards and convert to collateral.
     * Transfer all collateral from pool to here.
     * Deposit all collateral from this contract into Vesper V5(and up) pool
     */
    function rebalance() external override onlyKeeper {
        _claimReward();
        uint256 _collateralInPool = collateralToken.balanceOf(pool);
        if (_collateralInPool > 0) {
            collateralToken.safeTransferFrom(pool, address(this), _collateralInPool);
        }
        // There may be some collateral already here due to rewards, hence reading balance again.
        uint256 _collateralHere = collateralToken.balanceOf(address(this));
        if (_collateralHere > 0) {
            vToken.deposit(_collateralHere);
        }
    }

    /**
     * @notice Returns interest earned since last rebalance.
     */
    function interestEarned() public view override returns (uint256 collateralEarned) {
        // Pool rewardToken can change over time so we don't store it in contract
        address _poolRewards = vToken.poolRewards();
        if (_poolRewards != address(0)) {
            (address[] memory _rewardTokens, uint256[] memory _claimableRewards) =
                IPoolRewardsV4(_poolRewards).claimable(address(this));
            // if there's any reward earned we add that to collateralEarned
            if (_claimableRewards[0] > 0 && _rewardTokens[0] == VSP) {
                (, collateralEarned, ) = swapManager.bestOutputFixedInput(
                    VSP,
                    address(collateralToken),
                    _claimableRewards[0]
                );
            }
        }

        address[] memory _strategies = vToken.getStrategies();
        uint256 _len = _strategies.length;
        uint256 _unrealizedGain;

        for (uint256 i = 0; i < _len; i++) {
            uint256 _totalValue = IStrategyV4(_strategies[i]).totalValue();
            uint256 _debt = vToken.totalDebtOf(_strategies[i]);
            if (_totalValue > _debt) {
                _unrealizedGain = _unrealizedGain.add(_totalValue.sub(_debt));
            }
        }

        if (_unrealizedGain > 0) {
            // collateralEarned = rewards + unrealizedGain proportional to v2 share in v5
            collateralEarned = collateralEarned.add(
                _unrealizedGain.mul(vToken.balanceOf(address(this))).div(vToken.totalSupply())
            );
        }
    }

    /// @notice Returns true if strategy can be upgraded.
    /// @dev If there are no vTokens in strategy then it is upgradable
    function isUpgradable() external view override returns (bool) {
        return vToken.balanceOf(address(this)) == 0;
    }

    /// @notice This method is deprecated and will be removed from Strategies in next release
    function isReservedToken(address _token) public view override returns (bool) {
        address _poolRewards = vToken.poolRewards();
        return
            _token == address(vToken) ||
            (_poolRewards != address(0) && IPoolRewardsV4(_poolRewards).isRewardToken(_token));
    }

    function _approveToken(uint256 _amount) internal override {
        collateralToken.safeApprove(pool, _amount);
        collateralToken.safeApprove(address(vToken), _amount);

        for (uint256 i = 0; i < swapManager.N_DEX(); i++) {
            IERC20(VSP).safeApprove(address(swapManager.ROUTERS(i)), _amount);
        }
    }

    /**
     * @dev Converts rewardToken from V5(and up) Pool to collateralToken
     */
    function _claimReward() internal override {
        address _poolRewards = vToken.poolRewards();
        if (_poolRewards != address(0)) {
            IPoolRewardsV4(_poolRewards).claimReward(address(this));
            uint256 _vspAmount = IERC20(VSP).balanceOf(address(this));
            if (_vspAmount > 0) {
                _safeSwap(VSP, address(collateralToken), _vspAmount);
            }
        }
    }

    /**
     * @notice Total collateral locked in VesperV5.
     * @return Return value will be in collateralToken defined decimal.
     */
    function totalLocked() public view override returns (uint256) {
        uint256 _totalVTokens = vToken.balanceOf(pool).add(vToken.balanceOf(address(this)));
        return _convertToCollateral(_totalVTokens);
    }

    /// @dev _deposit function is only being used via parent contract. Rebalance is not using it.
    function _deposit(uint256 _amount) internal virtual override {
        collateralToken.safeTransferFrom(pool, address(this), _amount);
        vToken.deposit(_amount);
    }

    function _withdraw(uint256 _amount) internal override {
        _safeWithdraw(_convertToShares(_amount));
        collateralToken.safeTransfer(pool, collateralToken.balanceOf(address(this)));
    }

    /**
     * @dev V5(and up) Pools may withdraw a partial amount of requested shares.
     * This can cause V2 pool to burn more shares than actual collateral withdrawn.
     * Hence the check to verify correct withdrawal.
     */
    function _safeWithdraw(uint256 _shares) internal {
        if (_shares > 0) {
            uint256 _sharesBefore = vToken.balanceOf(address(this));
            // WhitelistedWithdraw is deprecated in V4
            vToken.withdraw(_shares);
            require(
                vToken.balanceOf(address(this)) == _sharesBefore.sub(_shares),
                "Not enough shares withdrawn"
            );
        }
    }

    function _withdrawAll() internal override {
        _safeWithdraw(vToken.balanceOf(address(this)));
        _claimReward();
        collateralToken.safeTransfer(pool, collateralToken.balanceOf(address(this)));
    }

    /// @dev V5(and up) pools uses pricePerShare for all internal calculations, hence using pricePerShare here.
    function _convertToCollateral(uint256 _vTokenAmount) internal view returns (uint256) {
        return _vTokenAmount.mul(vToken.pricePerShare()).div(1e18);
    }

    /// @dev V5(and up) pools uses pricePerShare for all internal calculations, hence using pricePerShare here.
    function _convertToShares(uint256 _collateralAmount) internal view returns (uint256) {
        uint256 _pricePerShare = vToken.pricePerShare();
        uint256 _shares = _collateralAmount.mul(1e18).div(_pricePerShare);
        return _collateralAmount > (_shares.mul(_pricePerShare).div(1e18)) ? _shares + 1 : _shares;
    }

    /// @dev This strategy will not collect any fee as fee will be levied by V5(and up) pool and strategies
    //solhint-disable-next-line no-empty-blocks
    function _updatePendingFee() internal override {}
}
