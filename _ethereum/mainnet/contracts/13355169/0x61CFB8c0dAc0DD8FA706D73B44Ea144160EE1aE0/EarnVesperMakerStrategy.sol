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
    }

    function _claimRewardsAndConvertTo(address _toToken) internal override(Strategy, VesperMakerStrategy) {
        VesperMakerStrategy._claimRewardsAndConvertTo(_toToken);
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
        _forwardEarning();
        return collateralToken.balanceOf(address(this));
    }
}
