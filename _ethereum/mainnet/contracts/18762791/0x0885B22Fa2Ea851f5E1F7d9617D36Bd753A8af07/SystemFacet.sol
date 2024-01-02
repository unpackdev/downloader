// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./LibConstants.sol";
import "./Modifiers.sol";
import "./AppStorage.sol";
import "./LibAdmin.sol";
import "./LibHelpers.sol";
import "./LibObject.sol";
import "./LibEntity.sol";
import "./ReentrancyGuard.sol";

/**
 * @title System
 * @notice Use it to perform system level operations
 * @dev Use it to perform system level operations
 */
contract SystemFacet is Modifiers, ReentrancyGuard {
    /**
     * @notice Create an entity
     * @dev An entity can be created with a zero max capacity! This is in the event where an entity cannot write any policies.
     * @param _entityId Unique ID for the entity
     * @param _entityAdmin Unique ID of the entity administrator
     * @param _entityData remaining entity metadata
     * @param _dataHash hash of the offchain data
     */
    function createEntity(
        bytes32 _entityId,
        bytes32 _entityAdmin,
        Entity calldata _entityData,
        bytes32 _dataHash
    ) external assertPrivilege(LibAdmin._getSystemId(), LC.GROUP_SYSTEM_MANAGERS) {
        LibEntity._createEntity(_entityId, _entityAdmin, _entityData, _dataHash);
    }

    /**
     * @notice Convert a string type to a bytes32 type
     * @param _strIn a string
     * @return result Bytes32 representation of input string
     */
    function stringToBytes32(string memory _strIn) external pure returns (bytes32 result) {
        result = LibHelpers._stringToBytes32(_strIn);
    }

    /**
     * @dev Get whether given id is an object in the system.
     * @param _id object id.
     * @return true if it is an object, false otherwise
     */
    function isObject(bytes32 _id) external view returns (bool) {
        return LibObject._isObject(_id);
    }

    /**
     * @dev Get meta of given object.
     * @param _id object id.
     * @return parent object parent
     * @return dataHash object data hash
     * @return tokenSymbol object token symbol
     * @return tokenName object token name
     * @return tokenWrapper object token ERC20 wrapper address
     */
    function getObjectMeta(bytes32 _id) external view returns (bytes32 parent, bytes32 dataHash, string memory tokenSymbol, string memory tokenName, address tokenWrapper) {
        return LibObject._getObjectMeta(_id);
    }

    /**
     * @notice Wrap an object token as ERC20
     * @param _objectId ID of the tokenized object
     */
    function wrapToken(bytes32 _objectId) external nonReentrant assertPrivilege(LibAdmin._getSystemId(), LC.GROUP_SYSTEM_ADMINS) {
        LibObject._wrapToken(_objectId);
    }

    /**
     * @notice Returns the object's type
     * @dev An object's type is the most significant 12 bytes of its bytes32 ID
     * @param _objectId ID of the object
     */
    function getObjectType(bytes32 _objectId) external pure returns (bytes12) {
        return LibObject._getObjectType(_objectId);
    }

    /**
     * @notice Check to see if an object is of a given type
     * @param _objectId ID of the object
     * @param _objectType The object type to check against
     * @return true if the object is of the given type, false otherwise
     */
    function isObjectType(bytes32 _objectId, bytes12 _objectType) external pure returns (bool) {
        return LibObject._isObjectType(_objectId, _objectType);
    }
}
