// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.7.5;

interface IOrderMonitor {

    function startMonitor(uint256 _tokenId) external;

    function stopMonitor(uint256 _tokenId) external;

    function getTokenIdsLength() external view returns (uint256);

    function monitorSize() external view returns (uint256);

}