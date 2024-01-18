// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IOracle.sol";
import "./IEACAggregator.sol";
import "./IConditionalTokens.sol";
import "./IImageURIBuilder.sol";
import "./PredictFinanceOracleLibrary.sol";
import "./SupportedTokenList.sol";

contract PredictFinanceOfficialOracle is IOracle, Ownable {
    IConditionalTokens public immutable ct;
    IImageURIBuilder public imageURIBuilder;
    string public name;

    bool public isUnlimitedIndexSet;
    mapping(bytes32 => PredictFinanceOracleLibrary.QuestionDetail) public questionDetails;

    // conditionId -> ERC20 -> decimalOffset
    mapping(bytes32 => mapping(IERC20 => mapping(uint256 => bool)))
        public supportedCollateralTokens;

    constructor(address _ct, string memory _name) {
        ct = IConditionalTokens(_ct);
        name = _name;
    }

    function populationCount(uint256 _n) internal pure returns (uint256 count) {
        for (count = 0; _n != 0; count++) {
            _n &= (_n - 1);
        }
    }

    function checkIndexSet(uint256[] memory _partition, uint256 _outcomeSlotCount)
        internal
        view
        returns (bool)
    {
        if (_partition.length == _outcomeSlotCount) {
            return true;
        }
        if (!isUnlimitedIndexSet) {
            if (_partition.length > 2) {
                return false;
            }
            uint256 popCount = populationCount(_partition[0]);
            return (popCount == 1) || (popCount == _outcomeSlotCount - 1);
        }
        return true;
    }

    function getQuestion(bytes32 _questionId)
        public
        view
        returns (PredictFinanceOracleLibrary.QuestionDetail memory)
    {
        return questionDetails[_questionId];
    }

    function createCondition(
        bytes32 _questionId,
        string memory _title,
        string memory _description,
        bytes32[] memory _outcomes,
        string[3] memory _categories,
        uint128 _deadline
    ) public onlyOwner {
        require(
            questionDetails[_questionId].deadline == 0,
            "PredictFinanceOfficialOracle::QuestionId Already Existed"
        );
        require(_deadline > block.timestamp, "PredictFinanceOfficialOracle::Invalid Deadline");

        PredictFinanceOracleLibrary.QuestionDetail
            memory QuestionDetail = PredictFinanceOracleLibrary.QuestionDetail({
                title: _title,
                description: _description,
                outcomes: _outcomes,
                data: new bytes32[](0),
                payouts: new uint256[](0),
                categories: _categories,
                dataType: PredictFinanceOracleLibrary.DataType.STRING,
                outcomesType: PredictFinanceOracleLibrary.DataType.STRING,
                deadline: _deadline,
                resolved: false
            });

        ct.prepareCondition(_questionId, _outcomes.length);

        questionDetails[_questionId] = QuestionDetail;

        emit QuestionCreated(
            _questionId,
            _title,
            QuestionDetail.description,
            QuestionDetail.data,
            QuestionDetail.outcomes,
            QuestionDetail.deadline
        );
    }

    function resolve(bytes32 _questionId, uint256[] memory _payouts) public onlyOwner {
        PredictFinanceOracleLibrary.QuestionDetail storage questionDetail = questionDetails[
            _questionId
        ];

        questionDetail.resolved = true;
        questionDetail.payouts = _payouts;

        ct.reportPayouts(_questionId, _payouts);
    }

    function tokenTitle(
        ConditionalTokenLibrary.Position memory _position,
        ConditionalTokenLibrary.Collection memory _collection,
        ConditionalTokenLibrary.Condition memory _condition,
        uint256 _positionId,
        uint256 _decimals
    ) public view returns (string memory) {
        return
            imageURIBuilder.tokenTitle(
                questionDetails[_condition.questionId],
                _position,
                _collection,
                _condition,
                _positionId,
                _decimals
            );
    }

    function imageURI(
        ConditionalTokenLibrary.Position memory _position,
        ConditionalTokenLibrary.Collection memory _collection,
        ConditionalTokenLibrary.Condition memory _condition,
        uint256 _positionId,
        uint256 _decimals
    ) public view returns (string memory) {
        return
            imageURIBuilder.imageURI(
                questionDetails[_condition.questionId],
                _position,
                _collection,
                _condition,
                _positionId,
                _decimals
            );
    }

    function canSplit(
        IERC20 _collateralToken,
        bytes32 _parentCollectionId,
        bytes32 _conditionId,
        uint256[] calldata _partition,
        uint8 _decimalOffset
    ) external view returns (bool) {
        ConditionalTokenLibrary.Condition memory condition = ct.getCondition(_conditionId);
        return
            questionDetails[condition.questionId].deadline > block.timestamp &&
            supportedCollateralTokens[condition.questionId][_collateralToken][_decimalOffset] &&
            checkIndexSet(_partition, condition.outcomeSlotCount) &&
            _parentCollectionId == bytes32(0);
    }

    function canMerge(
        IERC20,
        bytes32,
        bytes32 _conditionId,
        uint256[] calldata _partition,
        uint8
    ) external view returns (bool) {
        ConditionalTokenLibrary.Condition memory condition = ct.getCondition(_conditionId);
        return
            isUnlimitedIndexSet ||
            (_partition.length == 2 &&
                _partition[0] + _partition[1] == 2**condition.outcomeSlotCount - 1) ||
            (_partition.length == condition.outcomeSlotCount); // Further check will be handled in mergePositions
    }

    function canConvertDecimalOffset(
        IERC20 _collateralToken,
        bytes32,
        bytes32 _conditionId,
        uint256,
        uint8,
        uint8 _toDecimalOffset
    ) external view returns (bool) {
        ConditionalTokenLibrary.Condition memory condition = ct.getCondition(_conditionId);
        return supportedCollateralTokens[condition.questionId][_collateralToken][_toDecimalOffset];
    }

    function setImageURIBuilder(IImageURIBuilder _newImageURIBuilder) external onlyOwner {
        imageURIBuilder = _newImageURIBuilder;
    }

    function setSupportedCollateralToken(
        bytes32 _questionId,
        IERC20 _token,
        uint256 _decimalOffset,
        bool _enabled
    ) external onlyOwner {
        supportedCollateralTokens[_questionId][_token][_decimalOffset] = _enabled;
    }

    function setUnlimitedIndexSet(bool _enabled) external onlyOwner {
        isUnlimitedIndexSet = _enabled;
    }
}
