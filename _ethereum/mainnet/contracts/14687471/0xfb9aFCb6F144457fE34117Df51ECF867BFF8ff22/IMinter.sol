// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.6;

interface IMinter {
    function mint(address) external;
    function mint_for(address, address) external;
}