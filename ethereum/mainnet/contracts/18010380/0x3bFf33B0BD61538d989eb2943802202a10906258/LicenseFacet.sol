// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "./OwnableInternal.sol";
import "./AccessControlInternal.sol";
import "./ERC721BaseInternal.sol";
import "./LicenseStorage.sol";
import "./ConstantsLib.sol";
import "./Counters.sol";

contract LicenseFacet is OwnableInternal, AccessControlInternal, ERC721BaseInternal {
    /**
     * @notice Thrown if the provided token ID does not exist
     */
    error TokenDoesNotExist(uint256);

    /**
     * @notice Thrown if the caller is not a Keepers license operator
     */
    error OperatorCannotBeZeroAddress();

    /**
     * @notice Thrown if the caller is not a Keepers license operator
     */
    error NotLicenseOperator(address);

    event LicenseRevokedSet(uint256 indexed tokenId, bool indexed isRevoked);

    using Counters for Counters.Counter;

    /*//////////////////////////////////////////////////////////////
                COMMERCIAL RIGHTS (LICENSE) FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function revokeCommercialRightsOperator(address operator) external onlyOwner {
        if (operator == address(0)) {
            revert OperatorCannotBeZeroAddress();
        }
        _revokeRole(ConstantsLib.KEEPERS_LICENSE_OPERATOR, operator);
    }

    function hasValidLicense(uint256 tokenId) external view returns (bool) {
        LicenseStorage.Layout storage l = LicenseStorage.layout();
        if (!_exists(tokenId)) {
            revert TokenDoesNotExist(tokenId);
        }
        return !l.licenseRevoked[tokenId];
    }

    function setLicenseRevoked(uint256 tokenId, bool isRevoked) external {
        LicenseStorage.Layout storage l = LicenseStorage.layout();
        if (!_hasRole(ConstantsLib.KEEPERS_LICENSE_OPERATOR, msg.sender)) {
            revert NotLicenseOperator(msg.sender);
        }
        if (!_exists(tokenId)) {
            revert TokenDoesNotExist(tokenId);
        }

        l.licenseRevoked[tokenId] = isRevoked;
        emit LicenseRevokedSet(tokenId, isRevoked);
    }

    function setLicenseOperator(address operator) external onlyOwner {
        if (operator == address(0)) {
            revert OperatorCannotBeZeroAddress();
        }
        _grantRole(ConstantsLib.KEEPERS_LICENSE_OPERATOR, operator);
    }
}
