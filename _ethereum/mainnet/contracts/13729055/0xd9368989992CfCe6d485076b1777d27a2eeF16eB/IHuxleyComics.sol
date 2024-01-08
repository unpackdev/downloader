// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./IERC721.sol";
 
interface IHuxleyComics is IERC721 {
    struct Issue {
        uint256 price;
        uint256 goldSupplyLeft;
        uint256 firstEditionSupplyLeft;
        uint256 holographicSupplyLeft;
        uint256 serialNumberToMintGold;
        uint256 serialNumberToMintFirstEdition;
        uint256 serialNumberToMintHolographic;
        uint256 maxPayableMintBatch;
        string uri;
        bool exist;
    }

    struct Token {
        uint256 serialNumber;
        uint256 issueNumber;
        TokenType tokenType;
    }

    enum TokenType {FirstEdition, Gold, Holographic}

    function safeMint(address _to) external returns (uint256);

    function getCurrentIssue() external returns (uint256 _currentIssue);
    function getCurrentPrice() external returns (uint256 _currentPrice);
    function getCurrentMaxPayableMintBatch() external returns (uint256 _currentMaxPayableMintBatch);

    function createNewIssue(
        uint256 _price,
        uint256 _goldSupply,
        uint256 _firstEditionSupply,
        uint256 _holographicSupply,
        uint256 _startSerialNumberGold,
        uint256 _startSerialNumberFirstEdition,
        uint256 _startSerialNumberHolographic,
        uint256 _maxPaybleMintBatch,
        string memory _uri
    ) external;

    function getIssue(uint256 _issueNumber) external returns (Issue memory _issue);

    function getToken(uint256 _tokenId) external returns (Token memory _token);

    function setTokenDetails(uint256 _tokenId, TokenType _tokenType) external;

    function setBaseURI(uint256 _issueNumber, string memory _uri) external;

    function setCanBurn(bool _canBurn) external;
}
