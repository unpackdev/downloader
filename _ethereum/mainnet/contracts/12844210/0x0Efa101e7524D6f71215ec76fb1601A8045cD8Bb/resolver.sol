pragma solidity >=0.7.0;
pragma abicoder v2;

import "./IUniswapV3Pool.sol";
import "./IUniswapV3Factory.sol";
import "./INonfungiblePositionManager.sol";
import "./FullMath.sol";
import "./TickMath.sol";
import "./LiquidityAmounts.sol";
import "./BytesLib.sol";


contract UniswapV3Resolver is LiquidityAmounts { 
    INonfungiblePositionManager constant public nonfungiblePositionManager = INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);
    IUniswapV3Factory constant public uniswapV3Factory = IUniswapV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984);
    function getNftIds(address user) public view returns(uint256[] memory ids) {
        uint256 len = nonfungiblePositionManager.balanceOf(user);
        ids = new uint256[](len);
        for (uint256 i = 0; i < len; i++) {
            ids[i] = nonfungiblePositionManager.tokenOfOwnerByIndex(user, i);
        }
    }

    struct Data {
        address token0;
        address token1;
        address poolAddress;
        uint24 fee;
        int24 tickLower;
        int24 tickCurrent;
        int24 tickUpper;
        uint128 liquidity;
        uint128 tokensOwed0;
        uint128 tokensOwed1;
        uint256 token0Amount;
        uint256 token1Amount;
    }

   function _getPosition(uint256 id) internal view returns (Data memory) {
       Data memory position;
        (bool success, bytes memory data) =
            address(nonfungiblePositionManager).staticcall(abi.encodeWithSelector(nonfungiblePositionManager.positions.selector, id));
        require(success, "fetching positions failed");
        {
            (
                ,
                ,
                position.token0,
                position.token1,
                position.fee,
                position.tickLower,
                position.tickUpper,
                position.liquidity
            ) = abi.decode(data, (
                uint96,
                address,
                address,
                address,
                uint24,
                int24,
                int24,
                uint128
                // uint256,
                // uint256,
                // uint128,
                // uint128
            ));
        }

        {
            bytes memory slicedData = BytesLib.slice(data, 320, 64);
            
            (
                position.tokensOwed0,
                position.tokensOwed1
            ) = abi.decode(slicedData, (
                uint128,
                uint128
            ));
        }
        {
            position.poolAddress = uniswapV3Factory.getPool(position.token0, position.token1, position.fee);
            (uint160 sqrtPriceX96, int24 tickCurrent,,,,,) = IUniswapV3Pool(position.poolAddress).slot0();
            position.tickCurrent = tickCurrent;
            (
                position.token0Amount,
                position.token1Amount
            ) = getAmountsForLiquidity(
                sqrtPriceX96,
                TickMath.getSqrtRatioAtTick(position.tickLower),
                TickMath.getSqrtRatioAtTick(position.tickUpper),
                position.liquidity
            );
        }
        return position;
   }

   function getPositions(uint256[] calldata ids) public view returns (Data[] memory) {
        uint256 len = ids.length;
        Data[] memory data = new Data[](len);
        for (uint256 i = 0; i < len; i++) {
            data[i] = _getPosition(ids[i]);
        }
        return data;
   }
}