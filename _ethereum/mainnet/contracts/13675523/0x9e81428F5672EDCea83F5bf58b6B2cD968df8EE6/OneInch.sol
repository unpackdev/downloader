// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "./BaseSwap.sol";
import "./SafeERC20.sol";
import "./Address.sol";
import "./IERC20Ext.sol";
import "./IAggregationRouter.sol";

contract OneInch is BaseSwap {
    using SafeERC20 for IERC20Ext;
    using Address for address;

    IAggregationRouter public router;

    event UpdatedAggregationRouter(IAggregationRouter router);

    constructor(address _admin, IAggregationRouter _router) BaseSwap(_admin) {
        router = _router;
    }

    function updateAggregationRouter(IAggregationRouter _router) external onlyAdmin {
        router = _router;
        emit UpdatedAggregationRouter(router);
    }

    /// @dev get expected return and conversion rate if using a Uni router
    function getExpectedReturn(GetExpectedReturnParams calldata params)
        external
        view
        override
        onlyProxyContract
        returns (uint256 destAmount)
    {
        require(false, "getExpectedReturn_notSupported");
    }

    function getExpectedReturnWithImpact(GetExpectedReturnParams calldata params)
        external
        view
        override
        onlyProxyContract
        returns (uint256 destAmount, uint256 priceImpact)
    {
        require(false, "getExpectedReturn_notSupported");
    }

    function getExpectedIn(GetExpectedInParams calldata params)
        external
        view
        override
        onlyProxyContract
        returns (uint256 srcAmount)
    {
        require(false, "getExpectedIn_notSupported");
    }

    function getExpectedInWithImpact(GetExpectedInParams calldata params)
        external
        view
        override
        onlyProxyContract
        returns (uint256 srcAmount, uint256 priceImpact)
    {
        require(false, "getExpectedIn_notSupported");
    }

    /// @dev swap token
    /// @notice
    /// 1inch API will returns data neccessary to build tx
    /// tx's data will be passed by params.extraData
    function swap(SwapParams calldata params)
        external
        payable
        override
        onlyProxyContract
        returns (uint256 destAmount)
    {
        require(params.tradePath.length == 2, "oneInch_invalidTradepath");

        safeApproveAllowance(address(router), IERC20Ext(params.tradePath[0]));

        bytes4 methodId = params.extraArgs[0] |
            (bytes4(params.extraArgs[1]) >> 8) |
            (bytes4(params.extraArgs[2]) >> 16) |
            (bytes4(params.extraArgs[3]) >> 24);
        if (methodId == IAggregationRouter.unoswap.selector) {
            return doUnoswap(params);
        }
        if (methodId == IAggregationRouter.swap.selector) {
            return doSwap(params);
        }

        require(false, "oneInch_invalidExtraArgs");
    }

    function doUnoswap(SwapParams calldata params) private returns (uint256 destAmount) {
        address srcToken;
        uint256 callValue;
        if (params.tradePath[0] == address(ETH_TOKEN_ADDRESS)) {
            srcToken = address(0);
            callValue = params.srcAmount;
        } else {
            srcToken = params.tradePath[0];
            callValue = 0;
        }
        bytes32[] memory data;
        (, , , data) = abi.decode(params.extraArgs[4:], (address, uint256, uint256, bytes32[]));

        destAmount = router.unoswap{value: callValue}(
            srcToken,
            params.srcAmount,
            params.minDestAmount,
            data
        );

        if (params.tradePath[1] == address(ETH_TOKEN_ADDRESS)) {
            (bool success, ) = params.recipient.call{value: destAmount}("");
        } else {
            IERC20Ext(params.tradePath[1]).safeTransfer(params.recipient, destAmount);
        }
    }

    /// @dev called when 1inch API returns method AggregationRouter.swap
    /// @notice AggregationRouter.swap method used a custom calldata.
    /// Since we don't know what included in that calldata, backend must take into account fee
    /// when calling 1inch API
    function doSwap(SwapParams calldata params) private returns (uint256 destAmount) {
        uint256 callValue;
        if (params.tradePath[0] == address(ETH_TOKEN_ADDRESS)) {
            callValue = params.srcAmount;
        } else {
            callValue = 0;
        }

        address aggregationExecutor;
        IAggregationRouter.SwapDescription memory desc;
        bytes memory data;

        (aggregationExecutor, desc, data) = abi.decode(
            params.extraArgs[4:],
            (address, IAggregationRouter.SwapDescription, bytes)
        );

        (destAmount, ) = router.swap{value: callValue}(
            aggregationExecutor,
            IAggregationRouter.SwapDescription({
                srcToken: params.tradePath[0],
                dstToken: params.tradePath[1],
                srcReceiver: desc.srcReceiver,
                dstReceiver: params.recipient,
                amount: params.srcAmount,
                minReturnAmount: params.minDestAmount,
                flags: desc.flags,
                permit: desc.permit
            }),
            data
        );
    }
}
