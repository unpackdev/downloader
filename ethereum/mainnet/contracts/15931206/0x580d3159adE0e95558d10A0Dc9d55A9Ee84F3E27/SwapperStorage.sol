//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.1;

import "./ISwapRouter.sol";
import "./IQuoter.sol";
import "./IWETH.sol";

contract SwapperStorage  {

    address public wton;            //decimal = 27 (RAY)
    address public ton;             //decimal = 18 (WAD)
    address public tos;             //decimal = 18 (WAD)

    IWETH public _WETH;
    
    ISwapRouter public uniswapRouter;

    bool check;

    mapping (address => bool) public tokenCheck;
}