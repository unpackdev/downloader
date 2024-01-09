// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./console.sol";

import "./TransferHelper.sol";
import "./IERC20.sol";
import "./SafeMath.sol";

import "./ICompensationVault.sol";

contract ChangerSwapRouterV2 {
    using SafeMath for uint256;
    address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    event Swap(
        address indexed sender,
        address indexed token0,
        address indexed token1,
        uint256 amount0In,
        uint256 amount1Out
    );

    receive() external payable {}

    function swapWithCompensation(
        address handler,
        address token0,
        address token1,
        uint256 amount0In,
        uint256 minAmount1Out,
        address receiver,
        bytes calldata data,
        ICompensationVault.CompensationParams calldata compensationParams
    ) external payable returns (bool, uint256) {
        (bool success, uint256 amount1Out) = swap(handler, token0, token1, amount0In, minAmount1Out, receiver, data);
        require(success, "SEE"); // swap execution error
        ICompensationVault(compensationParams.vault).addCompensation(amount1Out, compensationParams);
        return (true, amount1Out);
    }

    function swap(
        address handler,
        address token0,
        address token1,
        uint256 amount0In,
        uint256 minAmount1Out,
        address receiver,
        bytes calldata data
    ) public payable returns (bool success, uint256 amount1Out) {
        if (token0 != address(0)) {
            TransferHelper.safeTransferFrom(token0, msg.sender, handler, amount0In);
        }

        (bool success_, bytes memory res) = handler.call{ value: msg.value }(data);
        res;

        assembly {
            if eq(success_, 0) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }

        uint256 balance = _getBalance(token1, address(this));
        require(balance >= minAmount1Out, "STE"); // slippage tolerance error
        _transfer(token1, receiver, balance);

        emit Swap(msg.sender, token0, token1, amount0In, balance);
        return (true, balance);
    }

    function _getBalance(address token, address account) internal view returns (uint256) {
        if (token == address(0)) return account.balance;
        return IERC20(token).balanceOf(account);
    }

    function _transfer(
        address token,
        address to,
        uint256 value
    ) internal {
        if (token == address(0)) return TransferHelper.safeTransferETH(to, value);
        return TransferHelper.safeTransfer(token, to, value);
    }
}
