// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

interface PrizePoolInterface {
    function prizeStrategy() external view returns (address);
}