//SPDX-License-Identifier: Unlicense
pragma solidity 0.5.16;

interface IUniswapV3Viewer {

  function getSqrtPriceX96(address _token0, address _token1, uint24 _fee) external view returns(uint160);

  function getSqrtPriceX96ForPosition(uint256 posId) external view returns(uint160);

  function getAmountsForPosition(uint256 posId) external view returns (uint256 amount0, uint256 amount1);

  function getAmountsForUserShare(address vaultAddr, uint256 userShare) external view returns (uint256 userAmount0, uint256 userAmount1);

  function enumerateNftRelevantTo(uint256 posId, address nftOwner) external view returns (uint256[] memory);

  function quoteV2Migration(address _token0, address _token1, uint256 _lpAmount) external view returns(uint256, uint256);

}