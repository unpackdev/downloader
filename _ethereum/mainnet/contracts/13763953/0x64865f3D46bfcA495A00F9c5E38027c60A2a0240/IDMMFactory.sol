// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;
import "./IERC20.sol";

interface IDMMFactory {
    function createPool(
        IERC20 tokenA,
        IERC20 tokenB,
        uint32 ampBps
    ) external returns (address pool);

    function getPools(IERC20 token0, IERC20 token1)
        external
        view
        returns (address[] memory _tokenPools);
}
