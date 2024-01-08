// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./VesperMakerStrategy.sol";
import "./Earn.sol";

/// @dev This strategy will deposit collateral token in Maker, borrow Dai and
/// deposit borrowed DAI in Vesper pool to earn interest.
abstract contract EarnVesperMakerStrategy is VesperMakerStrategy, Earn {
    using SafeERC20 for IERC20;

    constructor(
        address _pool,
        address _cm,
        address _swapManager,
        address _vPool,
        bytes32 _collateralType,
        address _dripToken
    ) VesperMakerStrategy(_pool, _cm, _swapManager, _vPool, _collateralType) Earn(_dripToken) {
        require(address(IVesperPool(_vPool).token()) == DAI, "not-a-valid-dai-pool");
        address _dripContract = IVesperPool(_pool).poolRewards();
        address _growPool = IEarnDrip(_dripContract).growToken();
        // underlying vPool of MakerStrategy must be equal to the growToken
        // Otherwise we cannot forward earnings without withdrawing/redepositing first
        // Example: Underlying vPool is vDAI v2 and growToken is vDAI v3 won't work
        require(receiptToken == _growPool, "not-a-valid-grow-pool");
    }

    function _claimRewardsAndConvertTo(address _toToken) internal override(Strategy, VesperMakerStrategy) {
        VesperMakerStrategy._claimRewardsAndConvertTo(_toToken);
    }

    function _rebalanceDaiInLender() internal override {
        uint256 _daiDebt = cm.getVaultDebt(address(this));

        // DAI balance collected from _claimRewardsAndConvertTo (VSP rewards)
        uint256 _daiFromRewards = IERC20(dripToken).balanceOf(address(this));

        address _dripContract = IVesperPool(pool).poolRewards();
        address _growPool = IEarnDrip(_dripContract).growToken();

        if (_daiFromRewards != 0) {
            // If we have any spare DAI collected from _claimRewardsAndConvertTo
            // We want to deposit them in vPool
            IVesperPool(_growPool).deposit(_daiFromRewards);
        }

        // DAI balance deposited in vPool
        uint256 _daiBalance = _getDaiBalance();

        if (_daiBalance > _daiDebt) {
            // If actual DAI balance in vPool has increased we want to forward this to EarnDrip
            uint256 _daiEarned = _daiBalance - _daiDebt;
            uint256 _vAmount = (_daiEarned * 1e18) / IVesperPool(receiptToken).pricePerShare();

            if (_vAmount != 0) {
                totalEarned += _daiEarned;

                (, uint256 _interestFee, , , , , , ) = IVesperPool(pool).strategy(address(this));
                uint256 _growPoolBalance = IERC20(_growPool).balanceOf(address(this));
                uint256 _growPoolShares = (_vAmount > _growPoolBalance) ? _growPoolBalance : _vAmount;
                uint256 _fee = (_growPoolShares * _interestFee) / 10000;
                if (_fee != 0) {
                    IERC20(_growPool).safeTransfer(feeCollector, _fee);
                    _growPoolShares = _growPoolShares - _fee;
                }
                IERC20(_growPool).safeTransfer(_dripContract, _growPoolShares);
                IEarnDrip(_dripContract).notifyRewardAmount(_growPool, _growPoolShares, dripPeriod);
            }
        }
    }

    /**
     * @notice Calculate earning and convert it to collateral token
     * @dev Also claim rewards if available.
     *      Withdraw excess DAI from lender.
     *      Swap net earned DAI to collateral token
     * @return profit in collateral token
     */
    function _realizeProfit(
        uint256 /*_totalDebt*/
    ) internal virtual override(Strategy, MakerStrategy) returns (uint256) {
        _claimRewardsAndConvertTo(dripToken);
        _rebalanceDaiInLender();
        return collateralToken.balanceOf(address(this));
    }
}
