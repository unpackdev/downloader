// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./console.sol";

interface IPunk {
    function punkIndexToAddress(uint256) external returns (address);

    function transferPunk(address, uint256) external;

    function balanceOf(address) external returns (uint256);
}
