// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PoolAddress.sol";

interface IAipFactory {
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);
    event PoolCreated(
        address token0,
        address token1,
        uint8 frequency,
        address pool
    );

    event Enabled(
        address swapManager,
        address DAI,
        address USDC,
        address USDT,
        address WETH9
    );

    function owner() external view returns (address);

    function swapManager() external view returns (address);

    function DAI() external view returns (address);

    function USDC() external view returns (address);

    function USDT() external view returns (address);

    function WETH9() external view returns (address);

    function enabled() external view returns (bool);

    function getPoolInfo(address addr)
        external
        view
        returns (
            address,
            address,
            uint8
        );

    function getPool(
        address token0,
        address token1,
        uint8 frequency
    ) external view returns (address pool);

    function createPool(
        address token0,
        address token1,
        uint8 frequency
    ) external returns (address pool);

    function enable(
        address _swapManager,
        address _DAI,
        address _USDC,
        address _USDT,
        address _WETH9
    ) external;

    function setOwner(address _owner) external;
}
