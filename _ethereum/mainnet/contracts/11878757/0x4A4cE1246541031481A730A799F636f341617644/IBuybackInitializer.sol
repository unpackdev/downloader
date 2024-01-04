// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

interface IBuybackInitializer {
    function init(address _token, address _uniswapRouter, uint256 _minTokensToHold) external payable;
}
