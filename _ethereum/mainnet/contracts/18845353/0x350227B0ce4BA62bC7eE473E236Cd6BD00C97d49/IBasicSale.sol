// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import "./Sale.sol";

interface CNCIBasicSale {
    function getCurrentSale()
        external
        view
        returns (
            uint8,
        CNCSaleType,
            uint256,
            uint256
        );

    function setCurrentSale(CNCSale calldata sale) external;

    // payable for testability
    function withdraw() external payable;

    function setWithdrawAddress(address payable value) external;

    function setMaxSupply(uint256 value) external;

    function pause() external;

    function unpause() external;
}
