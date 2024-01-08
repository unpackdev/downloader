// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IINFPermissionManager {
    event LogWhiteListInvestor(address indexed investor, bool approved);
    event LogSetFeeAndFeeRecipient(uint256 fee, address indexed feeRecipient);
    event LogSetTokenFee(uint256 fee, address indexed tokenId);
    event LogFeeExempt(address indexed user, uint256 status);

    function getStatusAndFee(
        address sender,
        address receiver
    ) external view returns (bool exempt, uint256 fee, uint256 feePrecision, address feeRecipient);

    function setFeeExempt(address user, bool senderExempt, bool recipientExempt) external;

    function whitelistInvestor(address investor, bool approved) external;
}
