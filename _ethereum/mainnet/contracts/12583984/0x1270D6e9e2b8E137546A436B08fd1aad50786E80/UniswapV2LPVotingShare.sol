// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "./IShare.sol";
import "./MapReducer.sol";

interface IUniswapV2Pair {
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

contract UniswapV2LPVotingShare is IShare, MapReducer {
  IUniswapV2Pair immutable pair;
  bool immutable isAsset0;
  
  /// @dev Expect pair_ to be in stores_
  constructor(address pair_, bool isAsset0_, address[] memory stores_) MapReducer(stores_) {
    pair = IUniswapV2Pair(pair_);
    isAsset0 = isAsset0_;
  }

  function shareBalanceToTokenBalance(uint256 shareBalance) public view returns (uint256) {
    (uint112 reserve0, uint112 reserve1, ) = pair.getReserves(); 
    uint112 reserve = isAsset0 ? reserve0 : reserve1;
    return shareBalance * reserve / pair.totalSupply();
  }

  function sane(address storeOfLp) internal view override(MapReducer) returns (bool) {
    IShare(storeOfLp).balanceOf(owner());
    return true;
  }

  function map(address storeOfLP, address account) internal view override(MapReducer) returns (uint256) {
    return IShare(storeOfLP).balanceOf(account);
  }

  function balanceOf(address owner) external view override(IShare) returns (uint256) {
    return shareBalanceToTokenBalance(reduce(owner));
  }
  
}