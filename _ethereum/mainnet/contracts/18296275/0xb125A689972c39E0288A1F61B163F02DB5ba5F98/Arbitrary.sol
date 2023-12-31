// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IERC20.sol";

interface IERC721Receiver {
  function onERC721Received(
    address operator,
    address from,
    uint tokenId,
    bytes calldata data
  ) external returns (bytes4);
}

contract Arbitrary is IERC721Receiver {
  INonfungiblePositionManager public nonfungiblePositionManager =
    INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);

  address public token;
  address public weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

  function createWall(uint amountOf0, uint amountOf1) public returns (uint tokenId, uint128 liquidity, uint amount0, uint amount1) {
    IERC20(token).approve(address(nonfungiblePositionManager), amountOf0);
    IERC20(weth).approve(address(nonfungiblePositionManager), amountOf1);

    INonfungiblePositionManager.MintParams
        memory params = INonfungiblePositionManager.MintParams({
            token0: token,
            token1: weth,
            fee: 3000,
            tickLower: -500,
            tickUpper: -400,
            amount0Desired: amountOf0,
            amount1Desired: amountOf1,
            amount0Min: 0,
            amount1Min: 0,
            recipient: address(this),
            deadline: block.timestamp
        });

    (tokenId, liquidity, amount0, amount1) = nonfungiblePositionManager.mint(
        params
    );
  }

  function setToken(address _token) public {
    token = _token;
  }

  function onERC721Received(
    address operator,
    address from,
    uint tokenId,
    bytes calldata
  ) external returns (bytes4) {
    return IERC721Receiver.onERC721Received.selector;
  }

  function withdraw(address _token) public {
    uint balance = IERC20(_token).balanceOf(address(this));
    IERC20(_token).transfer(msg.sender, balance);
  }

}

interface INonfungiblePositionManager {
    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint amount0Desired;
        uint amount1Desired;
        uint amount0Min;
        uint amount1Min;
        address recipient;
        uint deadline;
    }

    function mint(
        MintParams calldata params
    )
        external
        payable
        returns (uint tokenId, uint128 liquidity, uint amount0, uint amount1);

    struct IncreaseLiquidityParams {
        uint tokenId;
        uint amount0Desired;
        uint amount1Desired;
        uint amount0Min;
        uint amount1Min;
        uint deadline;
    }

    function increaseLiquidity(
        IncreaseLiquidityParams calldata params
    ) external payable returns (uint128 liquidity, uint amount0, uint amount1);

    struct DecreaseLiquidityParams {
        uint tokenId;
        uint128 liquidity;
        uint amount0Min;
        uint amount1Min;
        uint deadline;
    }

    function decreaseLiquidity(
        DecreaseLiquidityParams calldata params
    ) external payable returns (uint amount0, uint amount1);

    struct CollectParams {
        uint tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    function collect(
        CollectParams calldata params
    ) external payable returns (uint amount0, uint amount1);
}
