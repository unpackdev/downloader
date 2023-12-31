// SPDX-License-Identifier: MIT
pragma solidity =0.8.14;

interface IICO {
    event BuyTokenDetail(
        uint256 buyAmount,
        uint256 tokenAmount,
        uint256 referralReward,
        uint32 timestamp,
        uint8 buyType,
        uint8 phaseNo,
        address referralAddress,
        address userAddress
    );

    event UserKYC(address[] userAddress, bool success);

    function buyTokens(
        uint8 _type,
        uint256 _usdtAmount,
        address _referralAddress
    ) external payable;
}
