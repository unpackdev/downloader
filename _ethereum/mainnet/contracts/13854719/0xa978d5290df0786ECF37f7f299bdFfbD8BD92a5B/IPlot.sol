//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPlot {
  function getPlotCoordinate(uint256 tokenId)
    external
    view
    returns (int256, int256);
}
