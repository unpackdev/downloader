// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IEthlasFees {
    function getFee(
        uint16 _dstChainId,
        uint256 _amount,
        uint256 _estimatedFee
    ) external view returns (uint256);

    function percentSlip() external returns (uint256);
}
