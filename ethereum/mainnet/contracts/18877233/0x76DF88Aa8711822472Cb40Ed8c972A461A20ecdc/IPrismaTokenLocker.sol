// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IPrismaTokenLocker {
    function withdrawExpiredLocks(uint256 _weeks) external returns (bool);
}
