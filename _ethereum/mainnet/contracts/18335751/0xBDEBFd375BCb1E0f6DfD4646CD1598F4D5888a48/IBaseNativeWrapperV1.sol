// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

interface IBaseNativeWrapperV1 {
    event NativeAssetWrap(address actor, uint256 amount, bool indexed wrappingToNative);

    function wrap(uint256 amount) external;

    function unwrap(uint256 amount) external;

    function unwrapAll() external;
}
