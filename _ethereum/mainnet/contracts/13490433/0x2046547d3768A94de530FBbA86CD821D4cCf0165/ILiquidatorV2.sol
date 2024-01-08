// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface ILiquidatorV2 {
    function liquidate(
        address recipient,
        address from,
        address to,
        uint256 amount,
        uint256 minOut
    ) external returns (uint256);

    function getSwapInfo(address from, address to) external view returns (address router, address[] memory path);

    function weth() external view returns (address);
}
