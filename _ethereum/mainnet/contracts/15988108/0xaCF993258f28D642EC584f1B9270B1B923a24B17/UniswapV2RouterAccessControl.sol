// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AddressAccessControl.sol";
import "./BaseCoboSafeModuleAcl.sol";

contract UniswapV2RouterAccessControl is BaseCoboSafeModuleAcl, AddressAccessControl {

    constructor(
        address _safeAddress,
        address _safeModule,
        address[] memory tokens
    ) {
        _setSafeAddressAndSafeModule(_safeAddress, _safeModule);
        _addAddresses(tokens);
    }

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external view onlySelf {
        onlySafeAddress(to);
        _checkAddress(tokenA);
        _checkAddress(tokenB);
    }

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external view onlySelf {
        onlySafeAddress(to);
        _checkAddress(token);
    }

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external view onlySelf {
        onlySafeAddress(to);
    }

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external view onlySelf {
        onlySafeAddress(to);
    }

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external view onlySelf {
        onlySafeAddress(to);
    }

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external view onlySelf {
        onlySafeAddress(to);
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external view onlySelf {
        onlySafeAddress(to);
        _checkAllAddresses(path);
    }

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external view onlySelf {
        onlySafeAddress(to);
        _checkAllAddresses(path);
    }

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external view onlySelf {
        onlySafeAddress(to);
        _checkAllAddresses(path);
    }

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external view onlySelf {
        onlySafeAddress(to);
        _checkAllAddresses(path);
    }

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external view onlySelf {
        onlySafeAddress(to);
        _checkAllAddresses(path);
    }

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external view onlySelf {
        onlySafeAddress(to);
        _checkAllAddresses(path);
    }

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external view onlySelf {
        onlySafeAddress(to);
    }

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external view onlySelf {
        onlySafeAddress(to);
    }

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external view onlySelf {
        onlySafeAddress(to);
        _checkAllAddresses(path);
    }

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external view onlySelf {
        onlySafeAddress(to);
        _checkAllAddresses(path);
    }

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external view onlySelf {
        onlySafeAddress(to);
        _checkAllAddresses(path);
    }
}
