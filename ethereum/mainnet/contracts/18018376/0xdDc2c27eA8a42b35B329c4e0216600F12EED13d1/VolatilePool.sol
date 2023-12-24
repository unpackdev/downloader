// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.14;

import "./DynamicPoolV3.sol";

/**
 * @title Volatile Pool
 * @notice Manages deposits, withdrawals and swaps for volatile pool with external oracle
 */
contract VolatilePool is DynamicPoolV3 {
    /// @notice Whether to cap the global equilibrium coverage ratio at 1 for deposit and withdrawal
    bool public shouldCapEquilCovRatio;

    uint256[50] private __gap;

    function initialize(uint256 ampFactor_, uint256 haircutRate_) public override {
        super.initialize(ampFactor_, haircutRate_);
        shouldCapEquilCovRatio = true;
    }

    function setShouldCapEquilCovRatio(bool shouldCapEquilCovRatio_) external onlyOwner {
        shouldCapEquilCovRatio = shouldCapEquilCovRatio_;
    }

    /// @dev enable floating r*, deposit and withdrawal amount should be adjusted by r*
    function _getGlobalEquilCovRatioForDepositWithdrawal() internal view override returns (int256 equilCovRatio) {
        (equilCovRatio, ) = globalEquilCovRatio();
        if (equilCovRatio > WAD_I && shouldCapEquilCovRatio) {
            // Cap r* at 1 for deposit and withdrawal
            equilCovRatio = WAD_I;
        }
    }
}
