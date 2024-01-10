// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITheCoachFunds {
    function supplyLeftToPremint() external returns (uint256);

    function preMintAllowance(address addr) external returns (uint256);

    function preMintAddresses(uint256 index) external returns (address);

    function paused() external returns (bool);
}
