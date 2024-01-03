// SPDX-License-Identifier: MIT

pragma solidity >=0.6.8;
import "./IERC20Burnable.sol";
interface IUniswapV2Pair is IERC20 {
    function sync() external;
}