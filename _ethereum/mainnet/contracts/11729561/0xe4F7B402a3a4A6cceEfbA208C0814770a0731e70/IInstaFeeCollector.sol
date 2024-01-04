// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

interface IInstaFeeCollector {
    function setFeeCollector(address payable _feeCollector) external;

    function setFee(uint256 _fee) external;

    function fee() external view returns (uint256);

    function feeCollector() external view returns (address payable);
}
