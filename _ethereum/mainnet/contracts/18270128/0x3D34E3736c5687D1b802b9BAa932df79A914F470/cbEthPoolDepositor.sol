// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.6;

import "./OwnableUpgradeable.sol";
import "./EnumerableSetUpgradeable.sol";
import "./Initializable.sol";
import "./ISwapRouter.sol";
import "./TransferHelper.sol";

import "./IUniswapV3PoolActions.sol";
import "./IUniswapV3PositionNft.sol";
import "./IWeth.sol";
import "./IERC721.sol";

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


    function initialize() public initializer {
        __Ownable_init();
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

    function _divideAndFloor(
        int24 numerator,
        int24 denominator
    ) private pure returns (int24) {
        int24 result = numerator / denominator;
        return result;
    }

    receive() external payable virtual {
        IWeth(WETH).deposit{value: msg.value}();

        IWeth(WETH).approve(UNISWAP_V3_ROUTER, _contractTokenBalance(WETH));

        _swap(WETH, CB_ETH, _contractTokenBalance(WETH) / 2);

        IWeth(WETH).approve(
            UNISWAP_V3_POSITION_NFT,
            _contractTokenBalance(WETH)
        );
        IWeth(CB_ETH).approve(
            UNISWAP_V3_POSITION_NFT,
            _contractTokenBalance(CB_ETH)
        );

        IUniswapV3PoolActions.Slot0 memory slot0 = IUniswapV3PoolActions(
            UNISWAP_CB_ETH_POOL
        ).slot0();

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
