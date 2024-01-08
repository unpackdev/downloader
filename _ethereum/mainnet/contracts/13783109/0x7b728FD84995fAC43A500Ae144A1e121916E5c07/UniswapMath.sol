// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;
import "./IUniswapV3Pool.sol";
import "./IERC20.sol";
import "./INonfungiblePositionManager.sol";

library UniswapMath {
    int24 constant tick500 = -887270;
    int24 constant tick3000 = -887220;
    int24 constant tick10000 = -887200;

    function getLowerTick(uint24 fee) private pure returns (int24 tick) {
        if (fee == 500) return tick500;
        else if (fee == 3000) return tick3000;
        else if (fee == 10000) return tick10000;
    }

    function getUpperTick(uint24 fee) private pure returns (int24 tick) {
        if (fee == 500) return -tick500;
        else if (fee == 3000) return -tick3000;
        else if (fee == 10000) return -tick10000;
    }

    function createDAOTokenPoolAndMint(
        INonfungiblePositionManager inpm,
        uint256 _baseTokenAmount,
        address _quoteTokenAddress,
        uint256 _quoteTokenAmount,
        uint24 _fee,
        int24 _tickLower,
        int24 _tickUpper,
        uint160 _sqrtPriceX96,
        uint256 _value
    )
        internal
        returns (
            address lpPool,
            address lpToken0,
            address lpToken1,
            uint256 amount0,
            uint256 amount1
        )
    {
        INonfungiblePositionManager.MintParams memory params = buildMintParams(
            _baseTokenAmount,
            _quoteTokenAddress,
            _quoteTokenAmount,
            _fee,
            _tickLower,
            _tickUpper
        );

        lpToken0 = params.token0;
        lpToken1 = params.token1;

        lpPool = inpm.createAndInitializePoolIfNecessary(params.token0, params.token1, _fee, _sqrtPriceX96);

        (, , amount0, amount1) = inpm.mint{value: _value}(params);
    }

    function buildMintParams(
        uint256 _baseTokenAmount,
        address _quoteTokenAddress,
        uint256 _quoteTokenAmount,
        uint24 fee,
        int24 tickLower,
        int24 tickUpper
    ) internal view returns (INonfungiblePositionManager.MintParams memory params) {
        address token0;
        address token1;
        uint256 amount0Desired;
        uint256 amount1Desired;
        if (address(this) > _quoteTokenAddress) {
            token0 = _quoteTokenAddress;
            token1 = address(this);
            amount0Desired = _quoteTokenAmount;
            amount1Desired = _baseTokenAmount;
        } else {
            token0 = address(this);
            token1 = _quoteTokenAddress;
            amount0Desired = _baseTokenAmount;
            amount1Desired = _quoteTokenAmount;
        }

        uint256 amount0Min = (amount0Desired * 0) / 10;
        uint256 amount1Min = (amount1Desired * 0) / 10;
        uint256 deadline = block.timestamp + 60 * 60;

        params = INonfungiblePositionManager.MintParams({
            token0: token0,
            token1: token1,
            fee: fee,
            tickLower: tickLower,
            tickUpper: tickUpper,
            amount0Desired: amount0Desired,
            amount1Desired: amount1Desired,
            amount0Min: amount0Min,
            amount1Min: amount1Min,
            recipient: address(this),
            deadline: deadline
        });
    }

    function getNearestSingleMintParams(address lpPool)
        internal
        view
        returns (
            address quoteTokenAddress,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper
        )
    {
        IUniswapV3Pool pool = IUniswapV3Pool(lpPool);

        (, int24 tick, , , , , ) = pool.slot0();

        fee = pool.fee();

        int24 tickSpacing = pool.tickSpacing();

        if (address(this) == pool.token0()) {
            tickLower = getNearestTickLower(tick, fee, tickSpacing);
            tickUpper = getUpperTick(fee);
            quoteTokenAddress = pool.token1();
        } else {
            tickLower = getLowerTick(fee);
            tickUpper = getNearestTickUpper(tick, fee, tickSpacing);
            quoteTokenAddress = pool.token0();
        }
    }

    function getNearestTickLower(
        int24 tick,
        uint24 fee,
        int24 tickSpacing
    ) internal pure returns (int24 tickLower) {
        // 比 tick 大
        // TODO 测试
        int24 bei = (getUpperTick(fee) - tick) / tickSpacing;
        tickLower = getUpperTick(fee) - tickSpacing * bei;
    }

    function getNearestTickUpper(
        int24 tick,
        uint24 fee,
        int24 tickSpacing
    ) internal pure returns (int24 tickLower) {
        // 比 tick 小
        // TODO 测试
        int24 bei = (tick - getLowerTick(fee)) / tickSpacing;
        tickLower = getLowerTick(fee) + tickSpacing * bei;
    }

    function mintToLPByTick(
        INonfungiblePositionManager inpm,
        address lpPool,
        uint256 lpMintValue,
        int24 tickLower,
        int24 tickUpper
    ) internal returns (uint256 amount0, uint256 amount1) {
        (
            address quoteTokenAddress,
            uint24 fee,
            int24 nearestTickLower,
            int24 nearestTickUpper
        ) = getNearestSingleMintParams(lpPool);
        require(tickLower >= nearestTickLower);
        require(tickUpper <= nearestTickUpper);

        INonfungiblePositionManager.MintParams memory params = buildMintParams(
            lpMintValue,
            quoteTokenAddress,
            0,
            fee,
            tickLower,
            tickUpper
        );

        if (params.token0 == quoteTokenAddress) {
            params.amount0Min = 0;
        } else {
            params.amount1Min = 0;
        }
        (, , amount0, amount1) = inpm.mint(params);
    }

    function bonusWithdrawByTokenId(
        INonfungiblePositionManager inpm,
        uint256 tokenId,
        address _lpToken0,
        address _lpToken1
    ) internal returns (uint256 token0Add, uint256 token1Add) {
        (, , address token0, address token1, , , , , , , , ) = inpm.positions(tokenId);

        if (_lpToken0 != token0 || _lpToken1 != token1) {
            token0Add = 0;
            token1Add = 0;
        } else {
            INonfungiblePositionManager.CollectParams memory bonusParams = INonfungiblePositionManager.CollectParams({
                tokenId: tokenId,
                recipient: address(this),
                amount0Max: type(uint128).max,
                amount1Max: type(uint128).max
            });
            uint256 token0Before = IERC20(token0).balanceOf(address(this));
            uint256 token1Before = IERC20(token1).balanceOf(address(this));
            inpm.collect(bonusParams);
            token0Add = IERC20(token0).balanceOf(address(this)) - token0Before;
            token1Add = IERC20(token1).balanceOf(address(this)) - token1Before;
        }
    }
}
