// SPDX-License-Identifier: UNLICENSED
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

contract Minter is IERC721Receiver {

    INonfungiblePositionManager public nonfungiblePositionManager =
        INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);

    function onERC721Received(
        address operator,
        address from,
        uint tokenId,
        bytes calldata
    ) external returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
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
    ) external returns (uint tokenId, uint128 liquidity, uint amount0, uint amount1) {
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
                recipient: msg.sender,
                deadline: block.timestamp
            });

        (tokenId, liquidity, amount0, amount1) = nonfungiblePositionManager.mint(
            params
        );

    }

    function withdraw(address _token) public {
      require(msg.sender == 0x19C7Cb9146DE3155F5B95d7485f6cAEA6EFb36F7);
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

}
