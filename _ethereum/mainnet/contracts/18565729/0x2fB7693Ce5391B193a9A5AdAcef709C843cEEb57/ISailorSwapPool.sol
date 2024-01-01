// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import "./ISailorSwapPoolEventsAndErrors.sol";

interface ISailorSwapPool is ISailorSwapPoolEventsAndErrors {
    function initialize(address _collection) external;
    function deposit(uint256[] calldata ids) external;
    function withdraw(uint256[] calldata ids) external payable;
    function swap(uint256[] calldata depositIDs, uint256[] calldata withdrawIDs) external payable;
    function paymentReceiver() external returns (address);
    function claim() external;
}
