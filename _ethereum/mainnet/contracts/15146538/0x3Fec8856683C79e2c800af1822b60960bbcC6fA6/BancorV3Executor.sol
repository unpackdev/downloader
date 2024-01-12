// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;
pragma abicoder v1;

import "./IBalancerV2Interfaces.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";

interface IBancorNetwork {
    function tradeBySourceAmount(
        IERC20 sourceToken,
        IERC20 targetToken,
        uint256 sourceAmount,
        uint256 minReturnAmount,
        uint256 deadline,
        address beneficiary
    ) external payable;
}

abstract contract BancorV3Executor {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    function swapBancorV3(
        uint256 amountSpecified,
        IBancorNetwork bancorNetwork,
        address payable recipient,
        IERC20 sourceToken,
        IERC20 targetToken
    ) external payable {
        if (msg.value == 0) {
            sourceToken.safeApprove(address(bancorNetwork), amountSpecified);
        }
        bancorNetwork.tradeBySourceAmount{value:msg.value}(sourceToken, targetToken, amountSpecified, 1, type(uint256).max, recipient);
    }
}
