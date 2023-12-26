//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./IERC20Upgradeable.sol";
import "./IUniswapV3Pool.sol";
import "./DataTypesLib.sol";
import "./IRangeProtocolVault.sol";

abstract contract RangeProtocolVaultStorage is IRangeProtocolVault {
    DataTypesLib.State internal state;

    function factory() external view override returns (address) {
        return state.factory;
    }

    function pool() external view override returns (IUniswapV3Pool) {
        return state.pool;
    }

    function token0() external view override returns (IERC20Upgradeable) {
        return state.token0;
    }

    function token1() external view override returns (IERC20Upgradeable) {
        return state.token1;
    }

    function lowerTick() external view override returns (int24) {
        return state.lowerTick;
    }

    function upperTick() external view override returns (int24) {
        return state.upperTick;
    }

    function tickSpacing() external view override returns (int24) {
        return state.tickSpacing;
    }

    function inThePosition() external view override returns (bool) {
        return state.inThePosition;
    }

    function managingFee() external view override returns (uint16) {
        return state.managingFee;
    }

    function performanceFee() external view override returns (uint16) {
        return state.performanceFee;
    }

    function managerBalance() external view override returns (uint256) {
        return state.managerBalance;
    }

    function userVaults(address user) external view override returns (DataTypesLib.UserVault memory) {
        return state.vaults[user];
    }

    function userCount() external view override returns (uint256) {
        return state.users.length;
    }

    function users(uint256 index) external view override returns (address) {
        return state.users[index];
    }

    function poolAddressesProvider() external view override returns (address) {
        return address(state.poolAddressesProvider);
    }

    function gho() external view override returns (address) {
        return address(state.token0);
    }

    function collateralToken() external view override returns (address) {
        return address(state.token1);
    }
}
