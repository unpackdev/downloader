// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.3;

import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router02.sol";
import "./IERC20.sol";
import "./UniswapV2Library.sol";

contract TradeProxyV2 {
    address payable immutable private owner;
    address payable immutable private weth;

    constructor(
        address payable _owner,
        address payable _weth) {
        owner = _owner;
        weth = _weth;
    }

    receive() payable external {}

    // debug
    //    event Swap(uint256 amountIn, uint256 amount0Out, uint256 amount1Out,
    //        uint256 reserves0, uint256 reserves1, uint256 flag);
    // EVENTS
//    event BeforeTransfer(uint256 amountIn, uint256 amount0Out, uint256 amount1Out,
//        uint256 reserves0, uint256 reserves1, uint256 flag);
//    event BeforeSwap();

    // 测试uniswap的swap函数
    // 花费tknCost，得到tknGet;
    function swap(
        IUniswapV2Pair pair,
        IERC20 costToken,
        uint256 amountIn,
        uint256 flag  // 0 or 1
    ) private returns (uint256 amountOut) {
        uint256[2] memory reserves;
        (reserves[0], reserves[1],) = pair.getReserves();

        amountOut = UniswapV2Library.getAmountOut(
            amountIn, reserves[(flag ^ 0)], reserves[(flag ^ 1)]);

//        emit BeforeTransfer(amountIn, flag * amountOut, (1 - flag) * amountOut,
//            reserves[0], reserves[1], flag);
        // 向pair合约转入amount
        costToken.transfer(address(pair), amountIn);

//        emit BeforeSwap();
        // 将swap出来的token转入到本合约
        pair.swap(flag * amountOut, (1 - flag) * amountOut, address(this), new bytes(0));

        // debug
        //        emit Swap(amountIn, flag * amountOut, (1 - flag) * amountOut,
        //            reserves[0], reserves[1], flag);
    }

    // 起始token必须是WETH，pairs的第一个pair必须是WETH-xxx
    function doTrade(address[] calldata pairs,
        address[] calldata costToken,
        uint256 costWeth,
        uint256 flag) external {
        require(msg.sender == owner);

        uint256 amountIn = costWeth;
        for (uint i = 0; i < pairs.length; ++i) {
            amountIn = swap(
                IUniswapV2Pair(pairs[i]),
                IERC20(costToken[i]),
                amountIn,
                ((flag >> i) & 1));
        }
    }

    // 将套利合约的token转回来
    function moneyback(address tokenAddr) external {
        require(msg.sender == owner);

        // 将所有的token转给owner
        IERC20 tkn = IERC20(tokenAddr);
        uint balance = tkn.balanceOf(address(this));
        tkn.transfer(owner, balance);
    }

    // 将套利合约的eth转回来
    function ethback() external {
        require(msg.sender == owner);

        // 将所有的eth转给owner
        uint balance = address(this).balance;
        owner.transfer(balance);
    }
}
