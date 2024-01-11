// SPDX-License-Identifier: AGPLv3

pragma solidity 0.8.10;

struct StrategyParams {
    uint256 activation;
    uint256 debtRatio;
    uint256 minDebtPerHarvest;
    uint256 maxDebtPerHarvest;
    uint256 lastReport;
    uint256 totalDebt;
    uint256 totalGain;
    uint256 totalLoss;
}

interface IVaultAPI {
    function strategies(address _strategy)
        external
        view
        returns (StrategyParams memory);
}
