// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./MakerStrategy.sol";
import "./Earn.sol";
import "./CompoundMakerStrategy.sol";
import "./AaveCore.sol";
import "./IPoolRewards.sol";

/// @dev This strategy will deposit collateral token in Maker, borrow Dai and
/// deposit borrowed DAI in Aave to earn interest.
abstract contract EarnCompoundMakerStrategy is Earn, CompoundMakerStrategy {
    //solhint-disable no-empty-blocks
    constructor(
        address _pool,
        address _cm,
        address _swapManager,
        address _receiptToken,
        bytes32 _collateralType
    ) CompoundMakerStrategy(_pool, _cm, _swapManager, _receiptToken, _collateralType) {}

    /**
     * @notice Update update period of distribution of earning done in one rebalance
     * @dev _dripPeriod in seconds
     */
    function updateDripPeriod(uint256 _dripPeriod) external onlyGovernor {
        require(_dripPeriod != 0, "dripPeriod-zero");
        dripPeriod = _dripPeriod;
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
    ) internal virtual override returns (uint256) {
        _claimRewardsAndConvertTo(DAI);
        _rebalanceDaiInLender();
        _forwardEarning(DAI, feeCollector, pool);
        return collateralToken.balanceOf(address(this));
    }
}
