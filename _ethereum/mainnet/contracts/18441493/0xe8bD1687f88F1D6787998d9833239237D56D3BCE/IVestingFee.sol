// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.14;

interface IVestingFee {
    function setFee(uint256 _feePercent) external;

    function updateFeeReceiver(address _newReceiver) external;

    function updateconversionThreshold(uint256 _threshold) external;
}
