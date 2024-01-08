// SPDX-License-Identifier: MIT

pragma solidity ^0.6.11;

import "./IERC20Upgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./AddressUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./ICurveFi.sol";

/*
    Expands swapping functionality over base strategy
    - ETH in and ETH out Variants
    - Sushiswap support in addition to Uniswap
*/
contract TokenSwapPathRegistry {
    mapping(address => mapping(address => address[])) public tokenSwapPaths;

    event TokenSwapPathSet(address tokenIn, address tokenOut, address[] path);

    function getTokenSwapPath(address tokenIn, address tokenOut) public view returns (address[] memory) {
        return tokenSwapPaths[tokenIn][tokenOut];
    }

    function _setTokenSwapPath(
        address tokenIn,
        address tokenOut,
        address[] memory path
    ) internal {
        tokenSwapPaths[tokenIn][tokenOut] = path;
        emit TokenSwapPathSet(tokenIn, tokenOut, path);
    }
}
