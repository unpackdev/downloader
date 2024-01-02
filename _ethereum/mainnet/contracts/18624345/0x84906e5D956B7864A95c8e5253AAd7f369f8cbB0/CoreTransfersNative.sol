// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

import "./Context.sol";
import "./ICoreTransfersNativeV1.sol";

import "./DefinitiveAssets.sol";
import "./DefinitiveConstants.sol";
import "./DefinitiveErrors.sol";

abstract contract CoreTransfersNative is ICoreTransfersNativeV1, Context {
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

    function _depositNativeAndERC20(uint256[] calldata amounts, address[] calldata assetAddresses) internal virtual {
        uint256 assetAddressesLength = assetAddresses.length;
        if (amounts.length != assetAddressesLength) {
            revert InvalidInputs();
        }

        bool hasNativeAsset;
        uint256 nativeAssetIndex;

        for (uint256 i; i < assetAddressesLength; ) {
            if (assetAddresses[i] == DefinitiveConstants.NATIVE_ASSET_ADDRESS) {
                nativeAssetIndex = i;
                hasNativeAsset = true;
                unchecked {
                    ++i;
                }
                continue;
            }
            // ERC20 tokens
            IERC20(assetAddresses[i]).safeTransferFrom(_msgSender(), address(this), amounts[i]);
            unchecked {
                ++i;
            }
        }
        // Revert if NATIVE_ASSET_ADDRESS is not in assetAddresses and msg.value is not zero
        if (!hasNativeAsset && msg.value != 0) {
            revert InvalidMsgValue();
        }

        // Revert if depositing native asset and amount != msg.value
        if (hasNativeAsset && msg.value != amounts[nativeAssetIndex]) {
            revert InvalidMsgValue();
        }
    }
}
