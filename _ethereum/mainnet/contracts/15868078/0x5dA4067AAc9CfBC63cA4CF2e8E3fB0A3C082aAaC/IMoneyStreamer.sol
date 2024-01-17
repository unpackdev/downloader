// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Types.sol";

interface IMoneyStreamer {
    event CreateStream(
        uint256 indexed streamId,
        address indexed sender,
        address indexed recipient,
        uint256 deposit,
        address tokenAddress,
        uint256 startTime,
        uint256 stopTime
    );

    event WithdrawFromStream(
        uint256 indexed streamId,
        address indexed recipient,
        uint256 amount
    );

    event CancelStream(
        uint256 indexed streamId,
        address indexed sender,
        address indexed recipient,
        uint256 senderBalance,
        uint256 recipientBalance
    );

    function balanceOf(uint256 streamId, address account)
        external
        view
        returns (uint256 balance);

    function getStreamById(uint256 streamId)
        external
        view
        returns (Types.Stream memory stream);

    function getActiveStreams(address userAddress)
        external
        view
        returns (Types.Stream[] memory streams);

    function getStreamsBySenderAddress(address sender)
        external
        view
        returns (Types.Stream[] memory streams);

    function getStreamsByRecipientAddress(address recipient)
        external
        view
        returns (Types.Stream[] memory streams);

    function withdrawFromStream(uint256 streamId, uint256 funds)
        external
        returns (bool);

    function cancelStream(uint256 streamId) external returns (bool);
}
