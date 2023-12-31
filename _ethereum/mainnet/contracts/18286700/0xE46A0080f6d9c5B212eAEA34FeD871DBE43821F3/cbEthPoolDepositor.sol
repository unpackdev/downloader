// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.6;

import "./OwnableUpgradeable.sol";
import "./EnumerableSetUpgradeable.sol";
import "./Initializable.sol";
import "./ISwapRouter.sol";
import "./TransferHelper.sol";
import "./SafeMathUpgradeable.sol";

import "./IUniswapV3PoolActions.sol";
import "./IUniswapV3PositionNft.sol";
import "./IWeth.sol";
import "./IERC721.sol";
import "./console.sol";
// https://onthis.xyz
/*
 .d88b.  d8b   db d888888b db   db d888888b .d8888. 
.8P  Y8. 888o  88    88    88   88    88    88   YP 
88    88 88V8o 88    88    88ooo88    88     8bo.   
88    88 88 V8o88    88    88   88    88       Y8b. 
`8b  d8' 88  V888    88    88   88    88    db   8D 
 `Y88P'  VP   V8P    YP    YP   YP Y888888P  8888Y  
*/

contract CbEthWethLP is OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;

    event Minted(uint256 tokenId, address to);

    struct LpPosition {
        uint256 tokenId;
        address maker;
    }

    address public constant UNISWAP_CB_ETH_POOL =
        0x840DEEef2f115Cf50DA625F7368C24af6fE74410;
    address public constant UNISWAP_V3_POSITION_NFT =
        0xC36442b4a4522E871399CD717aBDD847Ab11FE88;
    address public constant UNISWAP_V3_ROUTER =
        0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address public constant CB_ETH = 0xBe9895146f7AF43049ca1c1AE358B0541Ea49704;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    uint24 public constant FEE = 500;

    uint256[50] private _gap;

    int24 public constant LOWER_TICK = 440;
    int24 public constant UPPER_TICK = 590;
    uint256 internal constant MAX_TICK = 887272;

    function initialize() public initializer {
        __Ownable_init();
    }

    function getSqrtRatioAtTick(
        int24 tick
    ) internal pure returns (uint160 sqrtPriceX96) {
        uint256 absTick = tick < 0
            ? uint256(-int256(tick))
            : uint256(int256(tick));
        require(absTick <= uint256(MAX_TICK), "T");

        uint256 ratio = absTick & 0x1 != 0
            ? 0xfffcb933bd6fad37aa2d162d1a594001
            : 0x100000000000000000000000000000000;
        if (absTick & 0x2 != 0)
            ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
        if (absTick & 0x4 != 0)
            ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
        if (absTick & 0x8 != 0)
            ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
        if (absTick & 0x10 != 0)
            ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
        if (absTick & 0x20 != 0)
            ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
        if (absTick & 0x40 != 0)
            ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
        if (absTick & 0x80 != 0)
            ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
        if (absTick & 0x100 != 0)
            ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
        if (absTick & 0x200 != 0)
            ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
        if (absTick & 0x400 != 0)
            ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
        if (absTick & 0x800 != 0)
            ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
        if (absTick & 0x1000 != 0)
            ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
        if (absTick & 0x2000 != 0)
            ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
        if (absTick & 0x4000 != 0)
            ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
        if (absTick & 0x8000 != 0)
            ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
        if (absTick & 0x10000 != 0)
            ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
        if (absTick & 0x20000 != 0)
            ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
        if (absTick & 0x40000 != 0)
            ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
        if (absTick & 0x80000 != 0)
            ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

        if (tick > 0) ratio = type(uint256).max / ratio;

        // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
        // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
        // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
        sqrtPriceX96 = uint160(
            (ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1)
        );
    }
    // same as at uniswapV2
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function withdrawERC20(
        address token,
        address to,
        uint256 amount
    ) external onlyOwner {
        if (token == address(0)) {
            payable(to).transfer(amount);
        } else {
            IERC20(token).transfer(to, amount);
        }
    }

    function withdrawERC721(
        address token,
        address to,
        uint256 tokenId
    ) external onlyOwner {
        IERC721(token).safeTransferFrom(address(this), to, tokenId, "0x");
    }

    function _swap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) private {
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                fee: FEE,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        ISwapRouter(UNISWAP_V3_ROUTER).exactInputSingle(params);
    }

    function _contractTokenBalance(address token) private returns (uint256) {
        return IWeth(token).balanceOf(address(this));
    }

    function _calculateTicks(
        int24 poolTick,
        int24 tickSpacing
    ) private pure returns (int24, int24) {
        int24 floorTickValue = _divideAndFloor(poolTick, 10);

        int24 tickUpper = floorTickValue * 10 + tickSpacing;
        int24 tickLower = floorTickValue * 10 - tickSpacing;

        return (tickLower, tickUpper);
    }

    function getPrice(
        uint256 sqrtPriceX96
    ) public pure returns (uint256 price) {
        return uint(sqrtPriceX96).mul(uint(sqrtPriceX96)).mul(1e18) >> (96 * 2);
    }

    function getToken0size(
        int24 currentTick,
        uint256 val
    ) public pure returns (uint256) {
        uint256 currentRatio = getSqrtRatioAtTick(currentTick);
        uint256 tickUpperRatio = getSqrtRatioAtTick(UPPER_TICK);
        uint256 tickLowerRatio = getSqrtRatioAtTick(LOWER_TICK);

        uint256 upperPrice = getPrice(tickUpperRatio);
        uint256 lowerPrice = getPrice(tickLowerRatio);
        uint256 currentPrice = getPrice(currentRatio);

        uint256 liqudity0 = (val * sqrt(currentPrice) * sqrt(upperPrice)) /
            (sqrt(upperPrice) - sqrt(currentPrice));
        uint256 liqudity1 = liqudity0 * (sqrt(currentPrice) - sqrt(lowerPrice));

        uint256 proportion = liqudity1 / val ;
        uint256 cbEthPart = (val * 10 ** 18) / (10 ** 18 + proportion);
        
        return cbEthPart;
    }

    function _divideAndFloor(
        int24 numerator,
        int24 denominator
    ) private pure returns (int24) {
        int24 result = numerator / denominator;
        return result;
    }

    receive() external payable virtual {
        IUniswapV3PoolActions.Slot0 memory slot0 = IUniswapV3PoolActions(
            UNISWAP_CB_ETH_POOL
        ).slot0();

        IWeth(WETH).deposit{value: msg.value}();
     
        uint256 amountIn = getToken0size(slot0.tick, msg.value);
        IWeth(WETH).approve(UNISWAP_V3_ROUTER, _contractTokenBalance(WETH));

        _swap(WETH, CB_ETH, amountIn);

        IWeth(WETH).approve(
            UNISWAP_V3_POSITION_NFT,
            _contractTokenBalance(WETH)
        );
        IWeth(CB_ETH).approve(
            UNISWAP_V3_POSITION_NFT,
            _contractTokenBalance(CB_ETH)
        );

        int24 tickSpacing = IUniswapV3PoolActions(UNISWAP_CB_ETH_POOL)
            .tickSpacing();

        (int24 lowerTick, int24 upperTick) = _calculateTicks(
            slot0.tick,
            tickSpacing
        );

        IUniswapV3PositionNFT.MintParams
            memory mintParams = IUniswapV3PositionNFT.MintParams(
                CB_ETH,
                WETH,
                FEE,
                LOWER_TICK,
                UPPER_TICK,
                _contractTokenBalance(CB_ETH),
                _contractTokenBalance(WETH),
                0,
                0,
                msg.sender,
                block.timestamp
            );

        (uint256 tokenId, , , ) = IUniswapV3PositionNFT(UNISWAP_V3_POSITION_NFT)
            .mint(mintParams);
        console.log(_contractTokenBalance(CB_ETH));
        console.log(_contractTokenBalance(WETH));
        if (_contractTokenBalance(CB_ETH) > 0) {
            IWeth(CB_ETH).approve(
                UNISWAP_V3_ROUTER,
                _contractTokenBalance(CB_ETH)
            );

            _swap(CB_ETH, WETH, _contractTokenBalance(CB_ETH));
        }

        if (_contractTokenBalance(WETH) > 0) {
            IWeth(WETH).transfer(msg.sender, _contractTokenBalance(WETH));
        }

        emit Minted(tokenId, msg.sender);
    }
}
