// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface ICNFD {
    function getPriorVotes(address account, uint blockNumber) external view returns (uint96);
}
