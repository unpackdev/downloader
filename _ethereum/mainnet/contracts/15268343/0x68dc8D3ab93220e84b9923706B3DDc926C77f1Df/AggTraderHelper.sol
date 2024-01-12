// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./IERC1155.sol";
import "./HelperOwnable.sol";
import "./LibHelperFeatureStorage.sol";


contract AggTraderHelper is HelperOwnable {

    event FeatureFunctionUpdated(bytes4 indexed selector, address oldFeature, address newFeature);

    function registerFeature(address feature, bytes4[] calldata methodIDs) external onlyOwner {
        unchecked {
            LibHelperFeatureStorage.Storage storage stor = LibHelperFeatureStorage.getStorage();
            for (uint256 i = 0; i < methodIDs.length; ++i) {
                bytes4 selector = methodIDs[i];
                address oldFeature = stor.impls[selector];
                stor.impls[selector] = feature;
                emit FeatureFunctionUpdated(selector, oldFeature, feature);
            }
        }
    }

    function registerFeatures(address[] calldata features, bytes4[][] calldata methodIDs) external onlyOwner {
        require(features.length == methodIDs.length, "registerFeatures: mismatched inputs.");
        unchecked {
            LibHelperFeatureStorage.Storage storage stor = LibHelperFeatureStorage.getStorage();
            for (uint256 i = 0; i < methodIDs.length; ++i) {
                // register feature
                address feature = features[i];
                bytes4[] calldata featureMethodIDs = methodIDs[i];
                for (uint256 j = 0; j < featureMethodIDs.length; ++j) {
                    bytes4 selector = featureMethodIDs[j];
                    address oldFeature = stor.impls[selector];
                    stor.impls[selector] = feature;
                    emit FeatureFunctionUpdated(selector, oldFeature, feature);
                }
            }
        }
    }

    function getFeature(bytes4 methodID) external view returns (address feature) {
        return LibHelperFeatureStorage.getStorage().impls[methodID];
    }

    /// @dev Fallback for just receiving ether.
    receive() external payable {}

    /// @dev Forwards calls to the appropriate implementation contract.
    fallback() external payable {
        bytes memory data = msg.data;
        bytes4 selector;
        assembly {
            selector := mload(add(data, 32))
            // Solidity does not require us to clean the trailing bytes.
            // We do it anyway
            selector := and(selector, 0xFFFFFFFF00000000000000000000000000000000000000000000000000000000)
        }

        address feature = LibHelperFeatureStorage.getStorage().impls[selector];
        require(feature != address(0), "Not implemented method.");

        (bool success, ) = feature.delegatecall(data);
        if (success) {
            assembly {
                returndatacopy(0, 0, returndatasize())
                return(0, returndatasize())
            }
        } else {
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }

    function rescueETH(address recipient) external onlyOwner {
        if (address(this).balance > 0) {
            (bool success,) = payable(recipient).call{value: address(this).balance}("");
            require(success, "_transferEth/TRANSFER_FAILED");
        }
    }
}
