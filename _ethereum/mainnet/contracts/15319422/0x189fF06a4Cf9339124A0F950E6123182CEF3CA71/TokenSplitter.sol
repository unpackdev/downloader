// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "./IERC20.sol";

contract TokenSplitter {
    struct RecipientInfo {
        address recipient;
        uint256 splitRatio; // 1% = 1e18
    }

    IERC20 public immutable token;

    RecipientInfo[] public recipientInfo;

    constructor(IERC20 _token, RecipientInfo[] memory _recipientInfo) {
        token = _token;
        uint256 length = _recipientInfo.length;
        for (uint256 i = 0; i < length; ++i) {
            recipientInfo.push(_recipientInfo[i]);
        }
    }

    function getRecipientInfoLength() external view returns (uint256) {
        return recipientInfo.length;
    }

    function split(uint256 amount) external {
        uint256 length = recipientInfo.length;
        for (uint256 i = 0; i < length; ++i) {
            RecipientInfo memory info = recipientInfo[i];
            uint256 transferAmount = (amount * info.splitRatio) / 1e20;
            token.transferFrom(msg.sender, info.recipient, transferAmount);
        }
    }
}
