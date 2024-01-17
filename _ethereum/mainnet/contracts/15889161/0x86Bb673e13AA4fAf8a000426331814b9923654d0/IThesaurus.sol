// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IThesaurus {
    function addWord(
        uint8 _type,
        uint256 _weight,
        string memory _content
    ) external;

    function totalWordsAmount() external view returns (uint256);

    function randomWords(uint256)
        external
        view
        returns (
            string memory _verb,
            string memory _adj,
            string memory _noun
        );

    function VERB_TYPE() external pure returns (uint8);

    function ADJ_TYPE() external pure returns (uint8);

    function NOUN_TYPE() external pure returns (uint8);
}
