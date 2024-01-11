// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IVesting {
    function vest(address beneficiary, uint256 amount, uint256 duration, uint256 releaseTimestamp) external;
    function mint() external;
    function mintFor(address grantee) external;
}
