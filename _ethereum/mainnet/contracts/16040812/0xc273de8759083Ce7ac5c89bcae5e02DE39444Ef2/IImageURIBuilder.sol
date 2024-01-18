// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./PredictFinanceOracleLibrary.sol";
import "./ConditionalTokenLibrary.sol";

interface IImageURIBuilder {
    function tokenTitle(
        PredictFinanceOracleLibrary.QuestionDetail memory _questionDetail,
        ConditionalTokenLibrary.Position memory _position,
        ConditionalTokenLibrary.Collection memory _collection,
        ConditionalTokenLibrary.Condition memory _condition,
        uint256 _positionId,
        uint256 _decimals
    ) external view returns (string memory);

    function imageURI(
        PredictFinanceOracleLibrary.QuestionDetail memory _questionDetail,
        ConditionalTokenLibrary.Position memory _position,
        ConditionalTokenLibrary.Collection memory _collection,
        ConditionalTokenLibrary.Condition memory _condition,
        uint256 _positionId,
        uint256 _decimals
    ) external view returns (string memory);
}
