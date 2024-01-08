// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

contract Events {
    event LogSell(
        address indexed buyToken,
        address indexed sellToken,
        uint256 buyAmt,
        uint256 sellAmt,
        uint256 getId,
        uint256 setId
    );
}
