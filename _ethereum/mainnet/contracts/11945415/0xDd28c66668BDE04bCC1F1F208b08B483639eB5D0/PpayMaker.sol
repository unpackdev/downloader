// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";

import "./IPlasmaswapERC20.sol";
import "./IPlasmaswapPair.sol";
import "./IPlasmaswapFactory.sol";

contract PpayMaker {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IPlasmaswapFactory public factory;
    address public ppay;
    address public weth;
    address public staking;
    address public governance;
    address public operations;

    uint256 public stakingPercents = 40;
    uint256 public governancePercents = 45;
    uint256 public operationsPercents = 15;

    constructor(
        IPlasmaswapFactory _factory,
        address _ppay,
        address _weth,
        address _staking,
        address _governance,
        address _operations
    ) public {
        factory = _factory;
        ppay = _ppay;
        weth = _weth;
        staking = _staking;
        governance = _governance;
        operations = _operations;
    }

    function convert(address token0, address token1) public {
        // At least we try to make front-running harder to do.
        require(msg.sender == tx.origin, "do not convert from contract");
        IPlasmaswapPair pair = IPlasmaswapPair(factory.getPair(token0, token1));
        pair.transfer(address(pair), pair.balanceOf(address(this)));
        (uint256 amount0, uint256 amount1) = pair.burn(address(this));
        uint256 wethAmount =
            _toWETH(token0, amount0) + _toWETH(token1, amount1);
        _to_PPAY(wethAmount);
    }

    function _safeTransferCommissions(address token, uint256 amountIn)
        internal
    {
        _safeTransfer(token, staking, (amountIn * stakingPercents) / 100);
        _safeTransfer(token, governance, (amountIn * governancePercents) / 100);
        _safeTransfer(token, operations, (amountIn * operationsPercents) / 100);
    }

    function _toWETH(address token, uint256 amountIn)
        internal
        returns (uint256)
    {
        if (token == ppay) {
            _safeTransferCommissions(ppay, amountIn);
            return 0;
        }
        if (token == weth) {
            _safeTransfer(token, factory.getPair(weth, ppay), amountIn);
            return amountIn;
        }
        IPlasmaswapPair pair = IPlasmaswapPair(factory.getPair(token, weth));
        if (address(pair) == address(0)) {
            return 0;
        }
        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        address token0 = pair.token0();
        (uint256 reserveIn, uint256 reserveOut) =
            token0 == token ? (reserve0, reserve1) : (reserve1, reserve0);
        uint256 amountInWithFee = amountIn.mul(997);
        uint256 amountOut =
            amountInWithFee.mul(reserveOut) /
                reserveIn.mul(1000).add(amountInWithFee);
        (uint256 amount0Out, uint256 amount1Out) =
            token0 == token ? (uint256(0), amountOut) : (amountOut, uint256(0));
        _safeTransfer(token, address(pair), amountIn);
        pair.swap(
            amount0Out,
            amount1Out,
            factory.getPair(weth, ppay),
            new bytes(0)
        );
        return amountOut;
    }

    function _to_PPAY(uint256 amountIn) internal {
        IPlasmaswapPair pair = IPlasmaswapPair(factory.getPair(weth, ppay));
        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        address token0 = pair.token0();
        (uint256 reserveIn, uint256 reserveOut) =
            token0 == weth ? (reserve0, reserve1) : (reserve1, reserve0);
        uint256 amountInWithFee = amountIn.mul(997);
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
        uint256 amountOut = numerator / denominator;
        (uint256 amount0Out, uint256 amount1Out) =
            token0 == weth ? (uint256(0), amountOut) : (amountOut, uint256(0));
        pair.swap(amount0Out, amount1Out, address(this), new bytes(0));
        _safeTransferCommissions(ppay, IERC20(ppay).balanceOf(address(this)));
    }

    function _safeTransfer(
        address token,
        address to,
        uint256 amount
    ) internal {
        IERC20(token).safeTransfer(to, amount);
    }
}
