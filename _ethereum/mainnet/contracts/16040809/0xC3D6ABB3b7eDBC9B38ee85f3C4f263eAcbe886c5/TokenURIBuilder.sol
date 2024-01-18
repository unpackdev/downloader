// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Strings.sol";
import "./DateTime.sol";
import "./Base64.sol";
import "./ConditionalTokenLibrary.sol";
import "./PredictFinanceOracleLibrary.sol";
import "./IConditionalTokens.sol";
import "./SupportedTokenList.sol";
import "./ITokenURIBuilder.sol";

contract TokenURIBuilder is ITokenURIBuilder {
    IConditionalTokens public immutable conditionalTokens;
    SupportedTokenList public immutable supportedTokenList;

    constructor(IConditionalTokens _conditionalTokens, SupportedTokenList _supportedTokenList) {
        conditionalTokens = _conditionalTokens;
        supportedTokenList = _supportedTokenList;
    }

    function expandDecimals(uint256 _decimals) internal pure returns (string memory) {
        if (_decimals == 0) {
            return "1";
        }
        string memory zeros;
        for (uint256 i = 0; i < _decimals - 1; i++) {
            zeros = string(abi.encodePacked(zeros, "0"));
        }
        return string(abi.encodePacked("0.", zeros, "1"));
    }

    function populationCount(uint256 _n) internal pure returns (uint256 count) {
        for (count = 0; _n != 0; count++) {
            _n &= (_n - 1);
        }
    }

    function buildAttribute(
        string memory _traitType,
        string memory _value,
        string memory _displayType
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '{"display_type":"',
                    _displayType,
                    '","trait_type":"',
                    _traitType,
                    '","value":"',
                    _value,
                    '"}'
                )
            );
    }

    function buildAttribute(string memory _traitType, string memory _value)
        internal
        pure
        returns (string memory)
    {
        return string(abi.encodePacked('{"trait_type":"', _traitType, '","value":"', _value, '"}'));
    }

    function tokenURI(
        ConditionalTokenLibrary.Condition memory _condition,
        ConditionalTokenLibrary.Collection memory _collection,
        ConditionalTokenLibrary.Position memory _position,
        uint256 _positionId,
        uint256 _decimals
    ) external view returns (string memory json) {
        PredictFinanceOracleLibrary.QuestionDetail memory questionDetail = _condition
            .oracle
            .getQuestion(_condition.questionId);

        {
            json = string(
                abi.encodePacked(
                    '{"name":"',
                    questionDetail.title,
                    " - ",
                    _condition.oracle.tokenTitle(
                        _position,
                        _collection,
                        _condition,
                        _positionId,
                        _decimals
                    ),
                    "(",
                    expandDecimals(_decimals),
                    " ",
                    supportedTokenList.get(address(_position.collateralToken)),
                    ')","description":"',
                    questionDetail.description,
                    '","image":"'
                )
            );
        }

        {
            string memory indexSet = Strings.toString(_collection.indexSet);
            json = string(
                abi.encodePacked(
                    json,
                    _condition.oracle.imageURI(
                        _position,
                        _collection,
                        _condition,
                        _positionId,
                        _decimals
                    ),
                    '","attributes":[',
                    buildAttribute("oracle", Strings.toHexString(address(_condition.oracle))),
                    ",",
                    buildAttribute("indexSet", indexSet),
                    ","
                )
            );
        }

        {
            address collateralToken = address(_position.collateralToken);
            json = string(
                abi.encodePacked(
                    json,
                    buildAttribute("collateralToken", supportedTokenList.get(collateralToken)),
                    ",",
                    buildAttribute("deadline", Strings.toString(questionDetail.deadline), "date"),
                    ",",
                    buildAttribute(
                        "outcomesChosen",
                        Strings.toString(populationCount(_collection.indexSet))
                    ),
                    ",",
                    buildAttribute("totalOutcomes", Strings.toString(_condition.outcomeSlotCount)),
                    ",",
                    buildAttribute("decimalOffset", Strings.toString(_position.decimalOffset)),
                    ","
                )
            );
        }

        {
            json = string(
                abi.encodePacked(
                    json,
                    (bytes(questionDetail.categories[0]).length > 0)
                        ? string(
                            abi.encodePacked(
                                buildAttribute("category0", questionDetail.categories[0]),
                                ","
                            )
                        )
                        : "",
                    (bytes(questionDetail.categories[1]).length > 0)
                        ? string(
                            abi.encodePacked(
                                buildAttribute("category1", questionDetail.categories[1]),
                                ","
                            )
                        )
                        : "",
                    (bytes(questionDetail.categories[2]).length > 0)
                        ? string(
                            abi.encodePacked(
                                buildAttribute("category2", questionDetail.categories[2]),
                                ","
                            )
                        )
                        : ""
                )
            );
        }

        json = string(
            abi.encodePacked(
                json,
                buildAttribute(
                    "settled",
                    conditionalTokens.payoutDenominator(_collection.conditionId) == 0
                        ? "false"
                        : "true"
                ),
                ",",
                buildAttribute("version", "V1"),
                "]}"
            )
        );

        json = Base64.encode(bytes(json));

        json = string(abi.encodePacked("data:application/json;base64,", json));
    }
}
