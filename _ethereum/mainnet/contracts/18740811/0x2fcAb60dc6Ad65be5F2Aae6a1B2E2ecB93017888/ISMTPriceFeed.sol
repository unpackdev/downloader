//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.17;

interface ISMTPriceFeed {
    function latestAnswer() external view returns (uint256);
}
