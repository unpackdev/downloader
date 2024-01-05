// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "./CTokens.sol";
import "./CUniswap.sol";
import "./IUniswapV2Router02.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";

function _transferEthOrToken(
    address payable _to,
    address _paymentToken,
    uint256 _amt
) {
    if (_paymentToken == ETH) {
        (bool success, ) = _to.call{value: _amt}("");
        require(success, "_transfer: fail");
    } else {
        SafeERC20.safeTransfer(IERC20(_paymentToken), _to, _amt);
    }
}

function _swapTokenToEthTransfer(
    address _gelato,
    address _creditToken,
    uint256 _feeAmount,
    uint256 _swapRate
) {
    address[] memory path = new address[](2);
    path[0] = _creditToken;
    path[1] = IUniswapV2Router02(UNISWAPV2_ROUTER02).WETH();
    SafeERC20.safeIncreaseAllowance(
        IERC20(_creditToken),
        UNISWAPV2_ROUTER02,
        _feeAmount
    );
    IUniswapV2Router02(UNISWAPV2_ROUTER02).swapExactTokensForETH(
        _feeAmount, // amountIn
        _swapRate, // amountOutMin
        path, // path
        _gelato, // receiver
        // solhint-disable-next-line not-rely-on-time
        block.timestamp // deadline
    );
}

function _getBalance(address _token, address _account)
    view
    returns (uint256 balance)
{
    return
        _token == ETH ? _account.balance : IERC20(_token).balanceOf(_account);
}
