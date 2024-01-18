// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./ConditionalTokenLibrary.sol";
import "./PredictFinanceOracleLibrary.sol";

interface IOracle {
    event QuestionCreated(
        bytes32 questionId,
        string title,
        string description,
        bytes32[] data,
        bytes32[] outcomes,
        uint128 deadline
    );

    function name() external view returns (string memory);

    function getQuestion(bytes32 _questionId)
        external
        view
        returns (PredictFinanceOracleLibrary.QuestionDetail memory);

    function tokenTitle(
        ConditionalTokenLibrary.Position memory _position,
        ConditionalTokenLibrary.Collection memory _collection,
        ConditionalTokenLibrary.Condition memory _condition,
        uint256 _positionId,
        uint256 _decimals
    ) external view returns (string memory);

    function imageURI(
        ConditionalTokenLibrary.Position memory _position,
        ConditionalTokenLibrary.Collection memory _collection,
        ConditionalTokenLibrary.Condition memory _condition,
        uint256 _positionId,
        uint256 _decimals
    ) external view returns (string memory);

    function canSplit(
        IERC20 _collateralToken,
        bytes32 _parentCollectionId,
        bytes32 _conditionId,
        uint256[] calldata _partition,
        uint8 _decimalOffset
    ) external view returns (bool);

    function canMerge(
        IERC20 _collateralToken,
        bytes32 _parentCollectionId,
        bytes32 _conditionId,
        uint256[] calldata _partition,
        uint8 _decimalOffset
    ) external view returns (bool);

    function canConvertDecimalOffset(
        IERC20 _collateralToken,
        bytes32 _parentCollectionId,
        bytes32 _conditionId,
        uint256 _indexSet,
        uint8 _fromDecimalOffset,
        uint8 _toDecimalOffset
    ) external view returns (bool);
}
