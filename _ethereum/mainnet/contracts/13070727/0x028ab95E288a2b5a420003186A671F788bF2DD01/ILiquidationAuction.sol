// SPDX-License-Identifier: No License

pragma solidity ^0.8.0;

interface ILiquidationAuction {
    function buyout(address _asset, address _user) external;
}
