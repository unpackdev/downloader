// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "./BaseSwap.sol";
import "./SafeERC20.sol";
import "./Address.sol";
import "./IERC20Ext.sol";
import "./IKyberDmmV2AggregationRouter.sol";
import "./BytesLib.sol";

contract KyberDmmV2 is BaseSwap {
    using SafeERC20 for IERC20Ext;
    using Address for address;
    using BytesLib for bytes;

    IKyberDmmV2AggregationRouter public router;

    event UpdatedAggregationRouter(IKyberDmmV2AggregationRouter router);

    constructor(address _admin, IKyberDmmV2AggregationRouter _router) BaseSwap(_admin) {
        router = _router;
    }

    function updateAggregationRouter(IKyberDmmV2AggregationRouter _router) external onlyAdmin {
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

    function getExpectedIn(GetExpectedInParams calldata params)
        external
        view
        override
        onlyProxyContract
        returns (uint256 srcAmount)
    {
        require(false, "getExpectedIn_notSupported");
    }

    /// @dev get expected return and conversion rate if using a Uni router
    function getExpectedReturnWithImpact(GetExpectedReturnParams calldata params)
        external
        view
        override
        onlyProxyContract
        returns (uint256 destAmount, uint256 priceImpact)
    {
        require(false, "getExpectedReturnWithImpact_notSupported");
    }

    function getExpectedInWithImpact(GetExpectedInParams calldata params)
        external
        view
        override
        onlyProxyContract
        returns (uint256 srcAmount, uint256 priceImpact)
    {
        require(false, "getExpectedInWithImpact_notSupported");
    }

    /// @dev swap token
    /// @notice
    /// DMM API will returns data neccessary to build tx
    /// tx's data will be passed by params.extraData
    function swap(SwapParams calldata params)
        external
        payable
        override
        onlyProxyContract
        returns (uint256 destAmount)
    {
        require(params.tradePath.length == 2, "kyberDmmV2_invalidTradepath");

        safeApproveAllowance(address(router), IERC20Ext(params.tradePath[0]));
        (address aggregationExecutorAddress, bytes memory executorData) = parseExtraArgs(
            params.extraArgs
        );
        bool etherIn = IERC20Ext(params.tradePath[0]) == ETH_TOKEN_ADDRESS;
        uint256 callValue = etherIn ? params.srcAmount : 0;
        uint256 flags = etherIn ? 0 : 4;

        return
            router.swap{value: callValue}(
                aggregationExecutorAddress,
                IKyberDmmV2AggregationRouter.SwapDescription({
                    srcToken: params.tradePath[0],
                    dstToken: params.tradePath[1],
                    srcReceiver: aggregationExecutorAddress,
                    dstReceiver: params.recipient,
                    amount: params.srcAmount,
                    minReturnAmount: params.minDestAmount,
                    flags: flags,
                    permit: ""
                }),
                executorData
            );
    }

    function parseExtraArgs(bytes calldata extraArgs)
        internal
        pure
        returns (address aggregationExecutor, bytes memory executorData)
    {
        require(extraArgs.length > 20, "invalid extraArgs");
        aggregationExecutor = extraArgs.toAddress(0);
        executorData = bytes(extraArgs[20:]);
    }
}
