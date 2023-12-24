// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

interface IWstETH {
    function getStETHByWstETH(
        uint256 _wstETHAmount
    ) external view returns (uint256);

    function getWstETHByStETH(
        uint256 _stETHAmount
    ) external view returns (uint256);
}
