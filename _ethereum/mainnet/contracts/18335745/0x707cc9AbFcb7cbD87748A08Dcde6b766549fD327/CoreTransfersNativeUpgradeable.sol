// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

import "./ContextUpgradeable.sol";
import "./ICoreTransfersNativeV1.sol";

import "./DefinitiveAssets.sol";
import "./DefinitiveConstants.sol";
import "./DefinitiveErrors.sol";

/// @notice Copied from CoreTransfersNative/v1/CoreTransfersNative.sol
abstract contract CoreTransfersNativeUpgradeable is ICoreTransfersNativeV1, ContextUpgradeable {
    using DefinitiveAssets for IERC20;

    /**
     * @notice Allows contract to receive native assets
     */
    receive() external payable virtual {}

    /**
     * @notice This function is executed if none of the other functions
     * match the call data.  `bytes calldata` will contain the full data sent
     * to the contract (equal to msg.data) and can return data in output.
     * The returned data will not be ABI-encoded, and will be returned without
     * modifications (not even padding).
     * https://docs.soliditylang.org/en/v0.8.17/contracts.html#fallback-function
     */
    fallback(bytes calldata) external payable virtual returns (bytes memory) {}

    function __CoreTransfersNative_init() internal onlyInitializing {
        __Context_init();
        __CoreTransfersNative_init_unchained();
    }

    function __CoreTransfersNative_init_unchained() internal onlyInitializing {}

    function _depositNativeAndERC20(DefinitiveConstants.Assets memory depositAssets) internal virtual {
        uint256 assetAddressesLength = depositAssets.addresses.length;
        if (depositAssets.amounts.length != assetAddressesLength) {
            revert InvalidInputs();
        }

        uint256 nativeAssetIndex = type(uint256).max;

        for (uint256 i; i < assetAddressesLength; ) {
            if (depositAssets.addresses[i] == DefinitiveConstants.NATIVE_ASSET_ADDRESS) {
                nativeAssetIndex = i;
                unchecked {
                    ++i;
                }
                continue;
            }
            // ERC20 tokens
            IERC20(depositAssets.addresses[i]).safeTransferFrom(_msgSender(), address(this), depositAssets.amounts[i]);
            unchecked {
                ++i;
            }
        }
        // Revert if NATIVE_ASSET_ADDRESS is not in assetAddresses and msg.value is not zero
        if (nativeAssetIndex == type(uint256).max && msg.value != 0) {
            revert InvalidMsgValue();
        }

        // Revert if depositing native asset and amount != msg.value
        if (nativeAssetIndex != type(uint256).max && msg.value != depositAssets.amounts[nativeAssetIndex]) {
            revert InvalidMsgValue();
        }
    }
}
