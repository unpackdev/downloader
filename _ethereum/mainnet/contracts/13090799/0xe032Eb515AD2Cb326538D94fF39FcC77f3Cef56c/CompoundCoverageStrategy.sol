// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./CompoundStrategy.sol";
import "./IVFRBuffer.sol";
import "./IVFRCoveragePool.sol";

// solhint-disable no-empty-blocks
abstract contract CompoundCoverageStrategy is CompoundStrategy {
    constructor(
        address _pool,
        address _swapManager,
        address _receiptToken
    ) CompoundStrategy(_pool, _swapManager, _receiptToken) {}

    function _realizeProfit(uint256 _totalDebt) internal override returns (uint256) {
        _claimRewardsAndConvertTo(address(collateralToken));
        uint256 _collateralBalance = _convertToCollateral(cToken.balanceOf(address(this)));
        if (_collateralBalance > _totalDebt) {
            _withdrawHere(_collateralBalance - _totalDebt);
        }

        uint256 balance = collateralToken.balanceOf(address(this));
        // If the buffer is not set, this will work exactly like a regular strategy
        address buffer = IVFRCoveragePool(pool).buffer();
        if (buffer != address(0)) {
            uint256 target = IVFRBuffer(buffer).target();
            uint256 inBuffer = collateralToken.balanceOf(buffer);
            if (inBuffer > target) {
                // If the buffer is above target, then request any additional funds
                IVFRBuffer(buffer).request(inBuffer - target);
            } else {
                // If the buffer is below target, send funds to it
                uint256 needed = target - inBuffer;
                if (balance >= needed) {
                    collateralToken.transfer(buffer, needed);
                } else {
                    collateralToken.transfer(buffer, balance);
                    return 0;
                }
            }
        }
        return collateralToken.balanceOf(address(this));
    }
}
