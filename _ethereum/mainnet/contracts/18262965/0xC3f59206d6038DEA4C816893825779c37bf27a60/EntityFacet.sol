// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./AppStorage.sol";
import "./Modifiers.sol";
import "./LibEntity.sol";
import "./LibObject.sol";
import "./LibAdmin.sol";
import "./LibConstants.sol";
import "./ReentrancyGuard.sol";
import "./IEntityFacet.sol";
import "./LibEIP712.sol";
import "./LibFeeRouter.sol";

/**
 * @title Entities
 * @notice Used to handle policies and token sales
 * @dev Mainly used for token sale and policies
 */
contract EntityFacet is IEntityFacet, Modifiers, ReentrancyGuard {
    modifier assertSimplePolicyEnabled(bytes32 _entityId) {
        require(LibEntity._getEntityInfo(_entityId).simplePolicyEnabled, "simple policy creation disabled");
        _;
    }

    function domainSeparatorV4() external view returns (bytes32) {
        return LibEIP712._domainSeparatorV4();
    }

    function hashTypedDataV4(bytes32 structHash) external view returns (bytes32) {
        return LibEIP712._hashTypedDataV4(structHash);
    }

    /**
     * @notice Create a Simple Policy
     * @param _policyId id of the policy
     * @param _entityId id of the entity
     * @param _stakeholders Struct of roles, entity IDs and signatures for the policy
     * @param _simplePolicy policy to create
     * @param _dataHash hash of the offchain data
     */
    function createSimplePolicy(
        bytes32 _policyId,
        bytes32 _entityId,
        Stakeholders calldata _stakeholders,
        SimplePolicy calldata _simplePolicy,
        bytes32 _dataHash
    ) external assertPrivilege(LibAdmin._getSystemId(), LC.GROUP_SYSTEM_UNDERWRITERS) assertSimplePolicyEnabled(_entityId) {
        LibEntity._createSimplePolicy(_policyId, _entityId, _stakeholders, _simplePolicy, _dataHash);
    }

    /**
     * @notice Enable an entity to be tokenized
     * @param _objectId ID of the entity
     * @param _symbol The symbol assigned to the entity token
     * @param _name The name assigned to the entity token
     */
    function enableEntityTokenization(
        bytes32 _objectId,
        string memory _symbol,
        string memory _name
    ) external assertPrivilege(LibAdmin._getSystemId(), LC.GROUP_SYSTEM_MANAGERS) {
        LibObject._enableObjectTokenization(_objectId, _symbol, _name);
    }

    /**
     * @notice Update entity token name and symbol
     * @param _entityId ID of the entity
     * @param _symbol New entity token symbol
     * @param _name New entity token name
     */
    function updateEntityTokenInfo(
        bytes32 _entityId,
        string memory _symbol,
        string memory _name
    ) external assertPrivilege(LibAdmin._getSystemId(), LC.GROUP_SYSTEM_MANAGERS) {
        LibObject._updateTokenInfo(_entityId, _symbol, _name);
    }

    /**
     * @notice Start token sale of `_amount` tokens for total price of `_totalPrice`
     * @dev Entity tokens are minted when the sale is started
     * @param _entityId ID of the entity
     * @param _amount amount of entity tokens to put on sale
     * @param _totalPrice total price of the tokens
     */
    function startTokenSale(
        bytes32 _entityId,
        uint256 _amount,
        uint256 _totalPrice
    ) external notLocked(msg.sig) nonReentrant assertPrivilege(_entityId, LC.GROUP_START_TOKEN_SALE) {
        LibEntity._startTokenSale(_entityId, _amount, _totalPrice);
    }

    /**
     * @notice Check if an entity token is wrapped as ERC20
     * @param _entityId ID of the entity
     * @return true if it is, false otherwise
     */
    function isTokenWrapped(bytes32 _entityId) external view returns (bool) {
        return LibObject._isObjectTokenWrapped(_entityId);
    }

    /**
     * @notice Update entity metadata
     * @param _entityId ID of the entity
     * @param _updateEntity metadata of the entity that can be updated
     */
    function updateEntity(bytes32 _entityId, Entity calldata _updateEntity) external assertPrivilege(LibAdmin._getSystemId(), LC.GROUP_SYSTEM_MANAGERS) {
        LibEntity._updateEntity(_entityId, _updateEntity);
    }

    /**
     * @notice Get the data for entity with ID: `_entityId`
     * @dev Get the Entity data for a given entityId
     * @param _entityId ID of the entity
     */
    function getEntityInfo(bytes32 _entityId) external view returns (Entity memory) {
        return LibEntity._getEntityInfo(_entityId);
    }

    /**
     * @notice Get the fee schedule
     * @param _entityId ID of the entity
     * @param _feeScheduleType fee schedule type
     * @return FeeSchedule of given type for the entity
     */
    function getFeeSchedule(bytes32 _entityId, uint256 _feeScheduleType) external view returns (FeeSchedule memory) {
        return LibFeeRouter._getFeeSchedule(_entityId, _feeScheduleType);
    }
}
