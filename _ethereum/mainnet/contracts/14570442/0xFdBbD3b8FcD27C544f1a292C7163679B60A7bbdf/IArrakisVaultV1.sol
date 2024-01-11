// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./SafeERC20.sol";
import "./IUniswapV3Pool.sol";

interface IArrakisVaultV1 {
    function mint(uint256 mintAmount, address receiver)
        external
        returns (
            uint256,
            uint256,
            uint128
        );

    function executiveRebalance(
        int24 newLowerTick,
        int24 newUpperTick,
        uint160 swapThresholdPrice,
        uint256 swapAmountBPS,
        bool zeroForOne
    ) external;

    function transferOwnership(address newOwner) external;

    function updateManagerParams(
        int16 newManagerFeeBPS,
        address newManagerTreasury,
        int16 newRebalanceBPS,
        int16 newSlippageBPS,
        int32 newSlippageInterval
    ) external;

    function getMintAmounts(uint256 amount0, uint256 amount1)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function manager() external view returns (address);

    function upperTick() external view returns (int24);

    function lowerTick() external view returns (int24);

    function pool() external view returns (IUniswapV3Pool);

    function token0() external view returns (IERC20);

    function token1() external view returns (IERC20);
}
