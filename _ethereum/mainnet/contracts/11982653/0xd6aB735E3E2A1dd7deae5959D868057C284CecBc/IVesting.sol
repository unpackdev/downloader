//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface IVesting {
    function initialize(
        uint256[] memory periods,
        uint256[] memory tokenAmounts,
        address beneficiary,
        address token
    ) external returns(bool);

    function release() external;

    function getPeriodData(uint index) external view returns(uint amount, uint timestamp);
    function getGlobalData() 
        external 
        view 
        returns(uint releasedPeriods, uint totalPeriods, uint totalReleased, address beneficiary, address token);

}
