// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// Local References
import "./IDynamicAttributes.sol";

// Error Codes
error NullTokenType();
error TokenAttributesDefinitionDoesNotExist();
error TokenTypeAlreadyCreated();
error TokenTypeCountExceeded();

/**
 * @title TokenMetadataManager
 * @author @NiftyMike | @NFTCulture
 * @dev This contract manages Non-Fungible Token Metadata fully on-chain and
 * in a generic fashion.
 *
 * All metadata is contained within a map called _tokenAttributesDefinitions.
 *
 * In its basic implementation, the TokenMetadataManager does not allow for
 * expansion of the token types. However, this could be added on by a subclass
 * of this contract.
 */
abstract contract TokenMetadataManager is IDynamicAttributesV1 {
    // Storage for Token Attribute Definitions
    mapping(uint256 => DynamicAttributesV1) private _tokenAttributesDefinitions;
    uint64[] private _tokenTypeIds;

    uint256 private immutable _maxNumberOfTypes;

    constructor(uint256 __maxNumberOfTypes) {
        _maxNumberOfTypes = __maxNumberOfTypes;

        _injectDefinitions(_getInitialDefinitions());
    }

    function _injectDefinitions(DynamicAttributesV1[] memory __tokenAttributesDefinition) internal virtual {
        uint256 idx;
        for (idx; idx < __tokenAttributesDefinition.length; ) {
            DynamicAttributesV1 memory current = __tokenAttributesDefinition[idx];
            _createTokenType(current);

            unchecked {
                ++idx;
            }
        }
    }

    function _getInitialDefinitions() internal virtual returns (DynamicAttributesV1[] memory);

    function getTokenAttributesDefinition(uint256 tokenType) external view returns (DynamicAttributesV1 memory) {
        return _getTokenAttributesDefinition(tokenType);
    }

    function _getTokenAttributesDefinition(uint256 tokenType) internal view returns (DynamicAttributesV1 memory) {
        return _tokenAttributesDefinitions[tokenType];
    }

    function getTokenTypeIds() external view returns (uint64[] memory) {
        return _getTokenTypeIds();
    }

    function _getTokenTypeIds() internal view returns (uint64[] memory) {
        return _tokenTypeIds;
    }

    function _createTokenType(DynamicAttributesV1 memory tokenAttributes) internal {
        uint256 tokenType = tokenAttributes.tokenType;

        if (tokenType == 0) revert NullTokenType();
        if (_tokenAttributesDefinitions[tokenType].tokenType > 0) revert TokenTypeAlreadyCreated();
        if (_maxNumberOfTypes > 0 && _tokenTypeIds.length + 1 > _maxNumberOfTypes) revert TokenTypeCountExceeded();

        _tokenAttributesDefinitions[tokenType] = tokenAttributes;
        _tokenTypeIds.push(uint64(tokenType));
    }

    function _updateTokenType(DynamicAttributesV1 memory tokenAttributes) internal {
        if (_tokenAttributesDefinitions[tokenAttributes.tokenType].tokenType == 0)
            revert TokenAttributesDefinitionDoesNotExist();

        _tokenAttributesDefinitions[tokenAttributes.tokenType] = tokenAttributes;
    }
}
