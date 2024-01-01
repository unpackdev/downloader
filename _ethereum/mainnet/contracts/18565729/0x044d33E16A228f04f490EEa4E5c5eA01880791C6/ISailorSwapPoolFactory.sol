// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import "./ISailorSwapPoolFactoryEventsAndErrors.sol";

interface ISailorSwapPoolFactory is ISailorSwapPoolFactoryEventsAndErrors {
    function swapFee() external view returns (uint256);
    function daoFeeRate() external view returns (uint256);
    function depositLockup() external view returns (uint256);
    function sznsDao() external view returns (address);
    function createPool(address collection) external returns (address pool);
    function paused() external view returns (bool);
}
