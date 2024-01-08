// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./CompoundStrategy.sol";
import "./IVFRBuffer.sol";
import "./IVFRStablePool.sol";

// solhint-disable no-empty-blocks
abstract contract CompoundStableStrategy is CompoundStrategy {
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
        address buffer = IVFRStablePool(pool).buffer();
        if (buffer != address(0)) {
            uint256 targetAmount = IVFRStablePool(pool).amountToReachTarget(address(this));
            if (balance >= targetAmount) {
                collateralToken.transfer(buffer, balance - targetAmount);
                balance = targetAmount;
            } else {
                uint256 amountNeeded = targetAmount - balance;
                uint256 amountInBuffer = collateralToken.balanceOf(buffer);
                uint256 amountReceived = amountInBuffer >= amountNeeded ? amountNeeded : amountInBuffer;
                IVFRBuffer(buffer).request(amountReceived);
                balance = balance + amountReceived;
            }
        }
        return balance;
    }
}
