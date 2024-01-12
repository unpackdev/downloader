// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;
pragma abicoder v1;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Errors.sol";

interface IMStable {
    function mint(
        address _input,
        uint256 _inputQuantity,
        uint256 _minOutputQuantity,
        address _recipient
    ) external returns (uint256 mintOutput);

    function swap(
        address _input,
        address _output,
        uint256 _inputQuantity,
        uint256 _minOutputQuantity,
        address _recipient
    ) external returns (uint256 swapOutput);

    function redeem(
        address _output,
        uint256 _mAssetQuantity,
        uint256 _minOutputQuantity,
        address _recipient
    ) external returns (uint256 outputQuantity);
}

enum SwapType {
    Mint,
    Redeem,
    Swap
}

abstract contract MStableExecutor {
    using SafeERC20 for IERC20;

    function swapMStable(
        uint256 fromAmount,
        IMStable pool,
        address recipient,
        IERC20 sourceToken,
        IERC20 targetToken,
        SwapType swapType
    ) external {
        sourceToken.safeApprove(address(pool), fromAmount);

        if (swapType == SwapType.Mint) {
            IMStable(pool).mint(address(sourceToken), fromAmount, 1, recipient);
        } else if (swapType == SwapType.Redeem) {
            IMStable(pool).redeem(address(targetToken), fromAmount, 1, recipient);
        } else if (swapType == SwapType.Swap) {
            IMStable(pool).swap(address(sourceToken), address(targetToken), fromAmount, 1, recipient);
        } else {
            revert MStableInvalidSwapType(uint256(swapType));
        }
    }
}
