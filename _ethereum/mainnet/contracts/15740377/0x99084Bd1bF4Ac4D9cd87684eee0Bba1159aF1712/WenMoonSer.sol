
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
pragma experimental ABIEncoderV2;

import "./ERC20.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";

contract WenMoonSer is ERC20, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    constructor() ERC20("Wen Moon Ser", "Pamp Pls") {
        uint256 totalSupply = 6_666_666_666 * 1e18;
        _mint(msg.sender, totalSupply);
    }
}
