// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

import "./BaseNativeWrapper.sol";
import "./IWETH9.sol";

abstract contract WETH9NativeWrapper is BaseNativeWrapper {
    constructor(BaseNativeWrapperConfig memory config) BaseNativeWrapper(config) {}

    function _wrap(uint256 amount) internal override {
        // slither-disable-next-line arbitrary-send-eth
        IWETH9(WRAPPED_NATIVE_ASSET_ADDRESS).deposit{ value: amount }();
    }

    function _unwrap(uint256 amount) internal override {
        IWETH9(WRAPPED_NATIVE_ASSET_ADDRESS).withdraw(amount);
    }
}
