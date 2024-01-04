// SPDX-License-Identifier: MIT
pragma solidity ^0.6.1;
import "./ERC20Like.sol";
import "./IUniswapV2Router02.sol";

abstract contract HardCoreLike is ERC20Like {
    function uniswapRouter() public virtual returns (IUniswapV2Router02);

    function tokenUniswapPair() public virtual returns (address);
}
