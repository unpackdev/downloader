// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

interface IDaiInterestRateStrategy {
    function recompute() external;
    function getBaseRate() external view returns (uint256);
    function getDebtRatio() external view returns (uint256);
}

contract DaiInterestRateStrategyResolver {

    IDaiInterestRateStrategy public immutable irs;

    constructor(address _irs) {
        irs = IDaiInterestRateStrategy(_irs);
    }

    function checker()
        external
        returns (bool canExec, bytes memory execPayload)
    {
        uint256 baseRate = irs.getBaseRate();
        uint256 debtRatio = irs.getDebtRatio();

        irs.recompute();

        canExec = irs.getBaseRate() != baseRate || irs.getDebtRatio() != debtRatio;
        
        execPayload = abi.encodeCall(IDaiInterestRateStrategy.recompute, ());
    }

}
