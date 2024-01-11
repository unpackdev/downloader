// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IFlybyMarket {

    function init(bytes calldata data) external payable;
    function initMarket( bytes calldata data ) external;
    function marketTemplate() external view returns (uint256);

}