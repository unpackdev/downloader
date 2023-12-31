// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "./BosonConstants.sol";
import "./DiamondLib.sol";
import "./IERC165.sol";
import "./IERC165Extended.sol";
import "./EIP712Lib.sol";

/**
 * @title ERC165Facet
 *
 * @notice Implements the ERC165 specification
 */
contract ERC165Facet is IERC165, IERC165Extended {
    /**
     * @notice Implements ERC-165 interface detection standard.
     *
     * @param _interfaceId - the sighash of the given interface
     * @return true if interface represented by sighash is supported
     */
    function supportsInterface(bytes4 _interfaceId) external view returns (bool) {
        // Get the DiamondStorage struct
        return DiamondLib.supportsInterface(_interfaceId);
    }

    /**
     * @notice Adds a supported interface to the Diamond.
     *
     * @param _interfaceId - the interface to add
     */
    function addSupportedInterface(bytes4 _interfaceId) external override {
        // Get the diamond storage slot
        DiamondLib.DiamondStorage storage ds = DiamondLib.diamondStorage();

        // Ensure the caller has the UPGRADER role
        require(ds.accessController.hasRole(UPGRADER, EIP712Lib.msgSender()), "Caller must have UPGRADER role");

        DiamondLib.addSupportedInterface(_interfaceId);
    }

    /**
     * @notice Removes a supported interface from the Diamond.
     *
     * @param _interfaceId - the interface to remove
     */
    function removeSupportedInterface(bytes4 _interfaceId) external override {
        // Get the diamond storage slot
        DiamondLib.DiamondStorage storage ds = DiamondLib.diamondStorage();

        // Ensure the caller has the UPGRADER role
        require(ds.accessController.hasRole(UPGRADER, EIP712Lib.msgSender()), "Caller must have UPGRADER role");

        DiamondLib.removeSupportedInterface(_interfaceId);
    }
}
