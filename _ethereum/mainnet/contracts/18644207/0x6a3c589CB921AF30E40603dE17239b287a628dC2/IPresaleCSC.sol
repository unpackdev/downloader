// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.20;

interface IPresaleCSC {
    function getLockedAmount(address buyer) external view returns(uint256);
    function vestingStartTime() external view returns (uint256);
}
