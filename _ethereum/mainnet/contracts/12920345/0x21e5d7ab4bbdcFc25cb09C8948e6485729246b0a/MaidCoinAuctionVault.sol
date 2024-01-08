// SPDX-License-Identifier: MIT
pragma solidity =0.6.12;

import "./IWETH.sol";
import "./IUniswapV2Factory.sol";
import "./TransferHelper.sol";
import "./UniswapV2Library.sol";

contract MaidCoinAuctionVault {
    event Receive(address indexed sender, uint256 value);
    event AddLiquidity(
        address pair,
        uint256 amountToken,
        uint256 amountETH,
        uint256 liquidity
    );

    address public immutable factory;
    address public immutable token;
    address public immutable WETH;
    address public immutable owner;

    constructor(
        address _factory,
        address _token,
        address _WETH
    ) public {
        factory = _factory;
        token = _token;
        WETH = _WETH;
        owner = msg.sender;
    }

    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, "MaidCoinAuctionVault: EXPIRED");
        _;
    }

    receive() external payable {
        emit Receive(msg.sender, msg.value);
    }

    function addLiquidity(
        uint256 amountTokenDesired,
        uint256 amountETHDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        uint256 deadline
    )
        external
        ensure(deadline)
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        )
    {
        require(msg.sender == owner, "MaidCoinAuctionVault: FORBIDDEN");
        (amountToken, amountETH) = _addLiquidity(
            token,
            WETH,
            amountTokenDesired,
            amountETHDesired,
            amountTokenMin,
            amountETHMin
        );
        address pair = UniswapV2Library.pairFor(factory, token, WETH);
        TransferHelper.safeTransfer(token, pair, amountToken);
        IWETH(WETH).deposit{value: amountETH}();
        assert(IWETH(WETH).transfer(pair, amountETH));
        liquidity = IUniswapV2Pair(pair).mint(address(this));

        emit AddLiquidity(
            pair,
            amountToken,
            amountETH,
            liquidity
        );
    }

    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin
    ) internal virtual returns (uint256 amountA, uint256 amountB) {
        // create the pair if it doesn't exist yet
        if (IUniswapV2Factory(factory).getPair(tokenA, tokenB) == address(0)) {
            IUniswapV2Factory(factory).createPair(tokenA, tokenB);
        }
        (uint256 reserveA, uint256 reserveB) = UniswapV2Library.getReserves(factory, tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint256 amountBOptimal = UniswapV2Library.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, "MaidCoinAuctionVault: INSUFFICIENT_B_AMOUNT");
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint256 amountAOptimal = UniswapV2Library.quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, "MaidCoinAuctionVault: INSUFFICIENT_A_AMOUNT");
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }
}
