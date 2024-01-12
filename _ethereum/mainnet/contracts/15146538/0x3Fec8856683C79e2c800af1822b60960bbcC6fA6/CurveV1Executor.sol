// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;
pragma abicoder v1;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./TokenLibrary.sol";
import "./Errors.sol";

interface CurveV1Pool {
    // solhint-disable func-name-mixedcase
    // solhint-disable var-name-mixedcase
    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external payable;

    // solhint-disable func-name-mixedcase
    // solhint-disable var-name-mixedcase
    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external payable;
}

abstract contract CurveV1Executor {
    using SafeERC20 for IERC20;
    using TokenLibrary for IERC20;

    function swapCurveV1(
        uint256 amountSpecified,
        CurveV1Pool pool,
        address payable recipient,
        IERC20 sourceToken,
        IERC20 targetToken,
        int128 i,
        int128 j
    ) external payable {
        if (msg.value == 0) {
            sourceToken.safeApprove(address(pool), amountSpecified);
        }
        pool.exchange{value:msg.value}(i, j, amountSpecified, 1);
        if (recipient != address(this)) {
            // TODO: remove transfers from here
            targetToken.universalTransfer(recipient, targetToken.universalBalanceOf(address(this)));
        }
    }

    function swapCurveV1Underlying(
        uint256 amountSpecified,
        CurveV1Pool pool,
        address payable recipient,
        IERC20 sourceToken,
        IERC20 targetToken,
        int128 i,
        int128 j
    ) external payable {
        if (msg.value == 0) {
            sourceToken.safeApprove(address(pool), amountSpecified);
        }
        pool.exchange_underlying{value:msg.value}(i, j, amountSpecified, 1);
        if (recipient != address(this)) {
            // TODO: remove transfers from here
            targetToken.universalTransfer(recipient, targetToken.universalBalanceOf(address(this)));
        }
    }
}
