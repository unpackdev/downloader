/*
   _____                           _ _      _____            _ _        _ 
  / ____|                         (_) |    / ____|          (_) |      | |
 | (___  _   _ _ __ ___  _ __ ___  _| |_  | |     __ _ _ __  _| |_ __ _| |
  \___ \| | | | '_ ` _ \| '_ ` _ \| | __| | |    / _` | '_ \| | __/ _` | |
  ____) | |_| | | | | | | | | | | | | |_  | |___| (_| | |_) | | || (_| | |
 |_____/ \__,_|_| |_| |_|_| |_| |_|_|\__|  \_____\__,_| .__/|_|\__\__,_|_|
                                                      | |                 
                                                      |_|              
                                                         
  Website:    https://summitcapital.xyz/
  Twitter:    https://twitter.com/summitalgo
  Telegram:   https://t.me/summitcapital
  Medium:     https://summitcapital.medium.com/
  Docs:       https://docs.summitcapital.xyz/
  ENS:        summitdeployer.eth

  This contract handles the programmatic buying and burning of the 
  SUMT token. The SUMT token is bought and burnt when the algo wallet 
  makes a profitable trade. This mechanism promotes reflexivity 
  and positive price action.

*/


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./INonfungiblePositionManager.sol";
import "./ISwapRouter.sol";
import "./IERC20.sol";

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

contract BuyAndBurn {

    INonfungiblePositionManager public nonfungiblePositionManager = INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);
    ISwapRouter constant router = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner!");
        _;
    }

    constructor() {
      owner = msg.sender;
    }

    function safeBuyAndBurn(
        address tokenIn,
        address tokenOut,
        uint24 poolFee,
        uint amountIn,
        uint amountOutMinimum
    ) public onlyOwner returns (uint amountOut) {
        IERC20(tokenIn).approve(address(router), amountIn);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                fee: poolFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: amountOutMinimum,
                sqrtPriceLimitX96: 0
            });

        amountOut = router.exactInputSingle(params);
        IERC20(tokenOut).transfer(address(0), amountOut);
    }

    function mintNewPosition(
        address token0,
        address token1,
        uint24 fee,
        int24 tickLower,
        int24 tickUpper,
        uint amount0Desired,
        uint amount1Desired,
        uint amount0Min,
        uint amount1Min
    ) public onlyOwner returns (uint tokenId, uint128 liquidity, uint amount0, uint amount1) {
        IERC20(token0).approve(address(nonfungiblePositionManager), amount0Desired);
        IERC20(token1).approve(address(nonfungiblePositionManager), amount1Desired);

        INonfungiblePositionManager.MintParams
            memory params = INonfungiblePositionManager.MintParams({
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
                deadline: block.timestamp
            });

        (tokenId, liquidity, amount0, amount1) = nonfungiblePositionManager.mint(
            params
        );
    }

    function collectAllFees(
        uint tokenId
    ) public onlyOwner returns (uint amount0, uint amount1) {
        INonfungiblePositionManager.CollectParams
            memory params = INonfungiblePositionManager.CollectParams({
                tokenId: tokenId,
                recipient: address(this),
                amount0Max: type(uint128).max,
                amount1Max: type(uint128).max
            });

        (amount0, amount1) = nonfungiblePositionManager.collect(params);
    }

    function increaseLiquidityCurrentRange(
        address token0,
        address token1,
        uint tokenId,
        uint amount0ToAdd,
        uint amount1ToAdd,
        uint amount0Min,
        uint amount1Min
    ) public onlyOwner returns (uint128 liquidity, uint amount0, uint amount1) {
        IERC20(token0).approve(address(nonfungiblePositionManager), amount0ToAdd);
        IERC20(token1).approve(address(nonfungiblePositionManager), amount1ToAdd);

        INonfungiblePositionManager.IncreaseLiquidityParams
            memory params = INonfungiblePositionManager.IncreaseLiquidityParams({
                tokenId: tokenId,
                amount0Desired: amount0ToAdd,
                amount1Desired: amount1ToAdd,
                amount0Min: amount0Min,
                amount1Min: amount1Min,
                deadline: block.timestamp
            });

        (liquidity, amount0, amount1) = nonfungiblePositionManager.increaseLiquidity(
            params
        );
    }

    function decreaseLiquidityCurrentRange(
        uint tokenId,
        uint128 liquidity,
        uint amount0Min,
        uint amount1Min
    ) public onlyOwner returns (uint amount0, uint amount1) {
        INonfungiblePositionManager.DecreaseLiquidityParams
            memory params = INonfungiblePositionManager.DecreaseLiquidityParams({
                tokenId: tokenId,
                liquidity: liquidity,
                amount0Min: amount0Min,
                amount1Min: amount1Min,
                deadline: block.timestamp
            });

        (amount0, amount1) = nonfungiblePositionManager.decreaseLiquidity(params);
    }

    function swapExactInputSingleHop(
        address tokenIn,
        address tokenOut,
        uint24 poolFee,
        uint amountIn,
        uint amountOutMinimum
    ) public onlyOwner returns (uint amountOut) {
        IERC20(tokenIn).approve(address(router), amountIn);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                fee: poolFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: amountOutMinimum,
                sqrtPriceLimitX96: 0
            });

        amountOut = router.exactInputSingle(params);
    }


    function upgradeOwner(address _owner) public onlyOwner {
      owner = _owner;
    }

    // Emergency
    function rescue(address token) public onlyOwner {
      if (token == 0x0000000000000000000000000000000000000000) {
        (bool sent, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
      } else {
        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(msg.sender, balance);
      }
    }

    receive() external payable {}

    function onERC721Received(
        address operator,
        address from,
        uint tokenId,
        bytes calldata
    ) external returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

}