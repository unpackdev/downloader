// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

interface IPsm {
    function tout() external view returns (uint256);

    function daiJoin() external view returns (address);

    function gemJoin() external view returns (address);

    function sellGem(address usr, uint256 gemAmt) external;

    function buyGem(address usr, uint256 gemAmt) external;
}
