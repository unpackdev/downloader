// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

interface IFeeCollector {
    function collectTokenFees(
        address tokenAddress,
        uint256 partnerFee,
        uint256 swingFee,
        address partnerAddress
    ) payable external;
    function getPartnerSwingCut(address partnerAddress) external view returns (uint256);
}

