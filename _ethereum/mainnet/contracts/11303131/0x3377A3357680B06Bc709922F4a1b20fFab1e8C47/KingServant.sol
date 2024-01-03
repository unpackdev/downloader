pragma solidity 0.6.12;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./IKingSwapERC20.sol";
import "./IKingSwapPair.sol";
import "./IKingSwapFactory.sol";

contract KingServant is Ownable {
    using SafeMath for uint256;

    IKingSwapFactory public factory;
    address public table;
    address public king;
    address public weth;
    uint8 public burnRatio = 0;

    constructor(IKingSwapFactory _factory, address _table, address _king, address _weth) public {
        require(
            address(_factory) != address(0) && _table != address(0) && _king != address(0) && _weth != address(0),
            "invalid address"
        );
        factory = _factory;
        king = _king;
        table = _table;
        weth = _weth;
    }

    function convert(address token0, address token1) public {
        // At least we try to make front-running harder to do.
        require(msg.sender == tx.origin, "do not convert from contract");
        IKingSwapPair pair = IKingSwapPair(factory.getPair(token0, token1));
        pair.transfer(address(pair), pair.balanceOf(address(this)));
        pair.burn(address(this));
        uint256 wethAmount = _toWETH(token0) + _toWETH(token1);
        uint256 wethAmountToBurn = burnRatio == 0 ? 0 : wethAmount.mul(burnRatio).div(10);
        uint256 wethAmountOnTable = wethAmount.sub(wethAmountToBurn);
        IERC20(weth).transfer(factory.getPair(weth, king), wethAmountOnTable);
        _toKING(wethAmountOnTable, table);
        if (wethAmountToBurn != 0) {
            IERC20(weth).transfer(factory.getPair(weth, king), wethAmountToBurn);
            _toKING(wethAmountToBurn, address(1));
        }
    }

    function _toWETH(address token) internal returns (uint256) {
        if (token == king) {
            uint amount = IERC20(token).balanceOf(address(this));
            uint amountToBurn = amount.mul(burnRatio).div(10);
            uint amountOnTable = amount.sub(amountToBurn);
            IERC20(token).transfer(table, amountOnTable);
            IERC20(token).transfer(address(1), amountToBurn);
            return 0;
        }
        if (token == weth) {
            uint amount = IERC20(token).balanceOf(address(this));
            return amount;
        }
        IKingSwapPair pair = IKingSwapPair(factory.getPair(token, weth));
        if (address(pair) == address(0)) {
            return 0;
        }
        (uint reserve0, uint reserve1,) = pair.getReserves();
        address token0 = pair.token0();
        (uint reserveIn, uint reserveOut) = token0 == token ? (reserve0, reserve1) : (reserve1, reserve0);
        uint amountIn = IERC20(token).balanceOf(address(this));
        uint amountInWithFee = amountIn.mul(9975);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(10000).add(amountInWithFee);
        uint amountOut = numerator / denominator;
        (uint amount0Out, uint amount1Out) = token0 == token ? (uint(0), amountOut) : (amountOut, uint(0));
        IERC20(token).transfer(address(pair), amountIn);
        pair.swap(amount0Out, amount1Out, address(this), new bytes(0));
        return amountOut;
    }

    function _toKING(uint256 amountIn, address to) internal {
        IKingSwapPair pair = IKingSwapPair(factory.getPair(weth, king));
        (uint reserve0, uint reserve1,) = pair.getReserves();
        address token0 = pair.token0();
        (uint reserveIn, uint reserveOut) = token0 == weth ? (reserve0, reserve1) : (reserve1, reserve0);
        // avoid stack too deep error
        uint amountOut;
        {
            uint amountInWithFee = amountIn.mul(9975);
            uint numerator = amountInWithFee.mul(reserveOut);
            uint denominator = reserveIn.mul(10000).add(amountInWithFee);
            amountOut = numerator / denominator;
        }
        (uint amount0Out, uint amount1Out) = token0 == weth ? (uint(0), amountOut) : (amountOut, uint(0));
        pair.swap(amount0Out, amount1Out, to, new bytes(0));
    }

    function setBurnRatio(uint8 newRatio) public onlyOwner {
        require(newRatio >= 0 && newRatio <= 10, "invalid burn ratio");
        burnRatio = newRatio;
    }
}
