//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./IERC20Upgradeable.sol";
import "./IUniswapV3Pool.sol";
import "./DataTypesLib.sol";

interface IRangeProtocolVaultGetters {
    // @return address of range protocol factory.
    function factory() external view returns (address);

    // @return address of AMM pool for which vault is created.
    function pool() external view returns (IUniswapV3Pool);

    // @return address of token0.
    function token0() external view returns (IERC20Upgradeable);

    // @return address of token1.
    function token1() external view returns (IERC20Upgradeable);

    // @return lower tick of the vault position.
    function lowerTick() external view returns (int24);

    // @return upper tick of the vault position.
    function upperTick() external view returns (int24);

    // @return space between two ticks.
    function tickSpacing() external view returns (int24);

    // @return true if the vault has an opened position in the AMM pool.
    function inThePosition() external view returns (bool);

    // @return true if token0 is GHO.
    function isToken0GHO() external view returns (bool);

    // @return returns managing fee percentage out of 10_000.
    function managingFee() external view returns (uint16);

    // @return returns performance fee percentage out of 10_000.
    function performanceFee() external view returns (uint16);

    // @return returns manager balance in token0.
    function managerBalance0() external view returns (uint256);

    // @return returns manager balance in token1.
    function managerBalance1() external view returns (uint256);

    // @return returns user's vault exposure in token0 and token1.
    function userVaults(address user) external view returns (DataTypesLib.UserVault memory);

    // @return returns total count of the user.
    function userCount() external view returns (uint256);

    // @return returns address of the user at {index} position in the users array.
    function users(uint256 index) external view returns (address);

    // @return address of the pool addresses provider.
    function poolAddressesProvider() external view returns (address);

    // @return address of gho token.
    function gho() external view returns (address);

    // @return address of collateral token.
    function collateralToken() external view returns (address);
}
