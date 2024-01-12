// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;
pragma abicoder v1;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./TokenLibrary.sol";

interface CurveV2PoolExtended {
    // solhint-disable func-name-mixedcase
    // solhint-disable var-name-mixedcase
    function exchange(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 min_dy,
        bool use_eth
    ) external payable;
}

interface CurveV2Pool {
    // solhint-disable func-name-mixedcase
    // solhint-disable var-name-mixedcase
    function exchange(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 min_dy
    ) external;
}

abstract contract CurveV2Executor {
    using SafeERC20 for IERC20;
    using TokenLibrary for IERC20;

    function swapCurveV2(
        uint256 amountSpecified,
        address pool,
        address payable recipient,
        IERC20 sourceToken,
        IERC20 targetToken,
        uint256 i,
        uint256 j,
        bool hasEthArg
    ) external payable {
        if (msg.value == 0) {
            sourceToken.safeApprove(address(pool), amountSpecified);
        }
        if (hasEthArg) {
            CurveV2PoolExtended(pool).exchange{value:msg.value}(i, j, amountSpecified, 1, msg.value > 0 || TokenLibrary.isEth(targetToken));
        } else {
            CurveV2Pool(pool).exchange(i, j, amountSpecified, 1);
        }
        if (recipient != address(this)) {
            targetToken.universalTransfer(recipient, targetToken.universalBalanceOf(address(this)));
        }
    }
}
