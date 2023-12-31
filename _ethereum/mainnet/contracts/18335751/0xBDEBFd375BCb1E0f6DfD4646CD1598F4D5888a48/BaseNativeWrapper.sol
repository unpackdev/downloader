// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

import "./BaseAccessControl.sol";
import "./IBaseNativeWrapperV1.sol";
import "./ReentrancyGuard.sol";

import "./DefinitiveAssets.sol";

struct BaseNativeWrapperConfig {
    address payable wrappedNativeAssetAddress;
}

abstract contract BaseNativeWrapper is IBaseNativeWrapperV1, BaseAccessControl, ReentrancyGuard {
    using DefinitiveAssets for IERC20;

    address payable public immutable WRAPPED_NATIVE_ASSET_ADDRESS;

    constructor(BaseNativeWrapperConfig memory baseNativeWrapperConfig) {
        WRAPPED_NATIVE_ASSET_ADDRESS = baseNativeWrapperConfig.wrappedNativeAssetAddress;
    }

    /**
     * @notice Publicly accessible method to wrap native assets
     * @param amount Amount of native assets to wrap
     */
    function wrap(uint256 amount) public onlyWhitelisted nonReentrant {
        _wrap(amount);
        emit NativeAssetWrap(_msgSender(), amount, true /* wrappingToNative */);
    }

    /**
     * @notice Publicly accessible method to unwrap native assets
     * @param amount Amount of tokenized assets to unwrap
     */
    function unwrap(uint256 amount) public onlyWhitelisted nonReentrant {
        _unwrap(amount);
        emit NativeAssetWrap(_msgSender(), amount, false /* wrappingToNative */);
    }

    /**
     * @notice Publicly accessible method to unwrap full balance of native assets
     * @dev Method is not marked as `nonReentrant` since it is a wrapper around `unwrap`
     */
    function unwrapAll() external onlyWhitelisted {
        return unwrap(DefinitiveAssets.getBalance(WRAPPED_NATIVE_ASSET_ADDRESS));
    }

    /**
     * @notice Internal method to wrap native assets
     * @dev Override this method with native asset wrapping implementation
     */
    function _wrap(uint256 amount) internal virtual;

    /**
     * @notice Internal method to unwrap native assets
     * @dev Override this method with native asset unwrapping implementation
     */
    function _unwrap(uint256 amount) internal virtual;
}
