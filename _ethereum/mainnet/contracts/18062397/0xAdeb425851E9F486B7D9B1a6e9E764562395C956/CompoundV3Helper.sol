// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface ICompoundV3 {
    function getUtilization() external view returns (uint);

    function getSupplyRate(uint256) external view returns (uint64);

    function getBorrowRate(uint256) external view returns (uint64);
}


contract CompoundV3Helper {
    uint256 public constant SECONDS_PER_YEAR = 31536000; // 60 * 60 * 24 * 365

    function getCompoundV3SupplyAPR(address market) public view returns (uint256) {
        uint utilization = ICompoundV3(market).getUtilization();
        uint64 supplyRate = ICompoundV3(market).getSupplyRate(utilization);
        uint256 supplyApr = supplyRate * SECONDS_PER_YEAR * 100;

        return supplyApr;
    }

    function getCompoundV3BorrowAPR(address market) public view returns (uint256) {
        uint utilization = ICompoundV3(market).getUtilization();
        uint64 borrowRate = ICompoundV3(market).getBorrowRate(utilization);
        uint256 borrowApr = borrowRate * SECONDS_PER_YEAR * 100;

        return borrowApr;
    }
}
