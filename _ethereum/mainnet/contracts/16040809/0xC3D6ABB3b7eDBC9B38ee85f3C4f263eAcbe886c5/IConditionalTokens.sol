// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IOracle.sol";
import "./ITokenURIBuilder.sol";
import "./IERC1155.sol";
import "./ConditionalTokenLibrary.sol";

interface IConditionalTokens {
    function prepareCondition(bytes32 _questionId, uint256 _outcomeSlotCount) external;

    function reportPayouts(bytes32 _questionId, uint256[] calldata _payouts) external;

    function splitPosition(
        IERC20 _collateralToken,
        bytes32 _parentCollectionId,
        bytes32 _conditionId,
        uint256[] calldata _partition,
        uint256 _amount,
        uint8 _decimalOffset
    ) external;

    function splitPositionETH(
        bytes32 _conditionId,
        uint256[] calldata _partition,
        uint8 _decimalOffset
    ) external payable;

    function mergePositions(
        IERC20 _collateralToken,
        bytes32 _parentCollectionId,
        bytes32 _conditionId,
        uint256[] calldata _partition,
        uint256 _amount,
        uint8 _decimalOffset
    ) external;

    function mergePositionsETH(
        bytes32 _conditionId,
        uint256[] calldata _partition,
        uint256 _amount,
        uint8 _decimalOffset
    ) external payable;

    function redeemPositions(
        IERC20 _collateralToken,
        bytes32 _parentCollectionId,
        bytes32 _conditionId,
        uint256[] calldata _indexSets,
        uint256 _decimalOffset
    ) external;

    function redeemPositionsETH(
        bytes32 _conditionId,
        uint256[] calldata _indexSets,
        uint256 _decimalOffset
    ) external payable;

    function allowedOracle(address _oracle) external view returns (bool);

    function getOutcomeSlotCount(bytes32 _conditionId) external view returns (uint256);

    function getCondition(bytes32 _conditionId)
        external
        view
        returns (ConditionalTokenLibrary.Condition memory);

    function getCollection(bytes32 _collectionId)
        external
        view
        returns (ConditionalTokenLibrary.Collection memory);

    function getPosition(uint256 _positionId)
        external
        view
        returns (ConditionalTokenLibrary.Position memory);

    function payoutNumerators(bytes32 _conditionId, uint256) external view returns (uint256);

    function payoutDenominator(bytes32 _conditionId) external view returns (uint256);

    function decimals(uint256 _positionId) external view returns (uint256);

    function getConditionId(
        address _oracle,
        bytes32 _questionId,
        uint256 _outcomeSlotCount
    ) external pure returns (bytes32);

    function getCollectionId(
        bytes32 _parentCollectionId,
        bytes32 _conditionId,
        uint256 _indexSet
    ) external view returns (bytes32);

    function getPositionId(
        IERC20 _collateralToken,
        bytes32 _collectionId,
        uint256 _decimalOffset
    ) external pure returns (uint256);

    function setAllowedOracle(address _oracle, bool _isAllowed) external;

    function setRoyaltyReceiver(address _royaltyReceiver) external;

    function setTokenURIBuilder(ITokenURIBuilder _tokenURIBuilder) external;
}
