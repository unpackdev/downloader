// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

/// @author: manifold.xyz


import "./AdminControlUpgradeable.sol";
import "./ASHRateEngineCore.sol";

contract ASHRateEngineUpgradeable is ASHRateEngineCore, AdminControlUpgradeable {

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ASHRateEngineCore, AdminControlUpgradeable) returns (bool) {
        return ASHRateEngineCore.supportsInterface(interfaceId) || AdminControlUpgradeable.supportsInterface(interfaceId);
    }

    /**
     * Initializer
     */
    function initialize() public initializer {
        __Ownable_init();
    }

    /**
     * @dev See {IASHRateEngineCore-updateEnabled}.
     */
    function updateEnabled(bool enabled) external override adminRequired {
        _updateEnabled(enabled);
    }

    /**
     * @dev See {IASHRateEngineCore-updateRateClass}.
     */
    function updateRateClass(address[] calldata contracts, uint8[] calldata rateClasses) external override adminRequired {
        _updateRateClass(contracts, rateClasses);
    }

    /**
     * @dev See {IASHRateEngineCore-updateRateClass}.
     */
    function updateRateClass(address[] calldata contracts, uint256[] calldata tokenIds, uint8[] calldata rateClasses) external override adminRequired {
        _updateRateClass(contracts, tokenIds, rateClasses);
    }

}