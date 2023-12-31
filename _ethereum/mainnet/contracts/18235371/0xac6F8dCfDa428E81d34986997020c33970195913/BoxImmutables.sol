// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

contract BoxImmutables {
    address internal immutable STARGATE_ROUTER;
    address internal immutable UNISWAP_ROUTER;
    address internal immutable WRAPPED_NATIVE;
    address internal immutable SG_ETH;
    address internal immutable EXECUTOR;

    constructor(
        address _executor,
        address _stargateRouter,
        address _uniswapRouter,
        address _wrappedNative,
        address _sgEth
    ) {
        EXECUTOR = _executor;
        WRAPPED_NATIVE = _wrappedNative;
        SG_ETH = _sgEth;
        STARGATE_ROUTER = _stargateRouter;
        UNISWAP_ROUTER = _uniswapRouter;
    }
}
