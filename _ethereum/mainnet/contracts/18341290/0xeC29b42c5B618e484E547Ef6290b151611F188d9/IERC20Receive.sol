// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IERC20Receive {
    event ReceivedFor(
        address indexed _from,
        address indexed _sender,
        uint256 indexed _tokenId,
        uint256 _amount
    );

    function receiveFor(
        address _from,
        address _sender,
        uint256 _tokenId,
        uint256 _amount
    ) external;
}
