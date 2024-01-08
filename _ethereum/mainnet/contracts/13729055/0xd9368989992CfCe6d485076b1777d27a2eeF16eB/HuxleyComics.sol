// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./IHuxleyComics.sol";

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";

contract HuxleyComics is ERC721Enumerable, IHuxleyComics, ReentrancyGuard, Ownable {
    using Strings for uint256;

    // address of the HuxleyComicsOps contract that can mint tokens
    address public minter;

    // control if tokens can be burned or not. Default is false
    bool public canBurn;

    // Last token id minted
    uint256 public tokenId;

    //Issue being minted
    uint256 private currentIssue;

    //Price of token to be minted
    uint256 private currentPrice;

    //Max amount of tokens that can be mined from current issue
    uint256 private currentMaxPayableMintBatch;

    // mapping of Issues - issue number -> Isssue
    mapping(uint256 => Issue) private issues;

    // mapping of redemptions - tokenId -> true/false
    mapping(uint256 => bool) public redemptions;

    // mapping of Tokens - tokenId -> Token
    mapping(uint256 => Token) private tokens;

    /**
     * @dev Modifier that checks that address is minter. Reverts
     * if sender is not the minter
     */
    modifier onlyMinter() {
        require(msg.sender == minter, "HT: Only minter");
        _;
    }

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token.
     */
    constructor() ERC721("HUXLEY Comics", "HUXLEY") {}

    /**
     * @dev Safely mints a token. Increments 'tokenId' by 1 and calls super._safeMint()
     *
     * @param to Address that will be the owner of the token
     */
    function safeMint(address to) external override onlyMinter() nonReentrant returns (uint256 _tokenId) {
        tokenId++;
        super._safeMint(to, tokenId);
        return tokenId;
    }

    /**
     * @dev Burns a token. Can only be called by token Owner
     *
     * @param _tokenId Token that will be burned
     */
    function burn(uint256 _tokenId) external {
        require(canBurn, "HT: is not burnable");
        require(ownerOf(_tokenId) == msg.sender, "HT: Not owner");
        super._burn(_tokenId);
    }

    /**
     * @dev It creates a new Issue. Only 'minter' can call this function.
     *
     * @param _price Price for each token to be minted in wei
     * @param _goldSupply Total supply of Gold token
     * @param _firstEditionSupply Total supply of First Edition token
     * @param _holographicSupply Total supply of Holographic token
     * @param _startSerialNumberGold Initial serial number for Gold token
     * @param _startSerialNumberFirstEdition Initial serial number for First Edition token
     * @param _startSerialNumberHolographic Initial serial number for Holographic token
     * @param _maxPayableMintBatch Max amount of tokens that can be minted when calling batch functions (should not be greater than 100 so it won't run out of gas)
     * @param _uri Uri for the tokens of the issue
     */
    function createNewIssue(
        uint256 _price,
        uint256 _goldSupply,
        uint256 _firstEditionSupply,
        uint256 _holographicSupply,
        uint256 _startSerialNumberGold,
        uint256 _startSerialNumberFirstEdition,
        uint256 _startSerialNumberHolographic,
        uint256 _maxPayableMintBatch,
        string memory _uri
    ) external override onlyMinter {
        currentIssue = currentIssue + 1;
        currentPrice = _price;
        currentMaxPayableMintBatch = _maxPayableMintBatch;

        Issue storage issue = issues[currentIssue];

        issue.price = _price;
        issue.goldSupplyLeft = _goldSupply;
        issue.firstEditionSupplyLeft = _firstEditionSupply;
        issue.holographicSupplyLeft = _holographicSupply;
        issue.serialNumberToMintGold = _startSerialNumberGold;
        issue.serialNumberToMintFirstEdition = _startSerialNumberFirstEdition;
        issue.serialNumberToMintHolographic = _startSerialNumberHolographic;
        issue.maxPayableMintBatch = _maxPayableMintBatch;
        issue.uri = _uri;
        issue.exist = true;
    }

    /**
     * @dev Returns whether `issueNumber` exists.
     *
     * Issue can be created via {createNewIssue}.
     *
     */
    function _issueExists(uint256 _issueNumber) internal view virtual returns (bool) {
        return issues[_issueNumber].exist ? true : false;
    }

    /**
     * @dev It sets details for the token. It sets the issue number, serial number and token type.
     *     It also updates supply left of the token.
     *
     * Emits a {IssueCreated} event.
     *
     * @param _tokenId tokenID
     * @param _tokenType tokenType
     */
    function setTokenDetails(uint256 _tokenId, TokenType _tokenType) external override onlyMinter {
        Token storage token = tokens[_tokenId];
        token.issueNumber = currentIssue;

        Issue storage issue = issues[currentIssue];
        // can mint Gold, FirstEdition and Holographic
        if (_tokenType == TokenType.Gold) {
            uint256 goldSupplyLeft = issue.goldSupplyLeft;
            require(goldSupplyLeft > 0, "HT: no gold");

            issue.goldSupplyLeft = goldSupplyLeft - 1;
            uint256 serialNumberGold = issue.serialNumberToMintGold;
            issue.serialNumberToMintGold = serialNumberGold + 1; //next mint

            token.tokenType = TokenType.Gold;
            token.serialNumber = serialNumberGold;
        } else if (_tokenType == TokenType.FirstEdition) {
            uint256 firstEditionSupplyLeft = issue.firstEditionSupplyLeft;
            require(firstEditionSupplyLeft > 0, "HT: no firstEdition");

            issue.firstEditionSupplyLeft = firstEditionSupplyLeft - 1;
            uint256 serialNumberFirstEdition = issue.serialNumberToMintFirstEdition;
            issue.serialNumberToMintFirstEdition = serialNumberFirstEdition + 1; //next mint

            token.tokenType = TokenType.FirstEdition;
            token.serialNumber = serialNumberFirstEdition;
        } else if (_tokenType == TokenType.Holographic) {
            uint256 holographicSupplyLeft = issue.holographicSupplyLeft;
            require(holographicSupplyLeft > 0, "HT: no holographic");

            issue.holographicSupplyLeft = holographicSupplyLeft - 1;
            uint256 serialNumberHolographic = issue.serialNumberToMintHolographic;
            issue.serialNumberToMintHolographic = serialNumberHolographic + 1; //next mint

            token.tokenType = TokenType.Holographic;
            token.serialNumber = serialNumberHolographic;
        } else {
            revert();
        }
    }

    /// @dev Returns URI for the token. Each Issue number has a base uri.
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "UT: invalid token");

        Token memory token = tokens[_tokenId];
        uint256 issueNumber = token.issueNumber;
        require(issueNumber > 0, "HT: invalid issue");

        Issue memory issue = issues[issueNumber];
        string memory baseURI = issue.uri;

        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, _tokenId.toString()))
                : "";
    }

    /**
     * @dev Sets URI for an Issue.
     *
     * Issue can be created via {createNewIssue} by the Minter.
     *
     */
    function setBaseURI(uint256 _issueNumber, string memory _uri) external override onlyMinter {
        require(_issueExists(_issueNumber), "UT: invalid issue");

        Issue storage issue = issues[_issueNumber];
        issue.uri = _uri;
    }

    /// @dev Returns Issue that can be minted.
    function getCurrentIssue() external view override returns (uint256 _currentIssue) {
        return currentIssue;
    }

    /// @dev Returns Price of token that can be minted.
    function getCurrentPrice() external view override returns (uint256 _currentPrice) {
        return currentPrice;
    }

    /// @dev Returns Max Amount of First Edition tokens an address can pay to mint.
    function getCurrentMaxPayableMintBatch() external view override returns (uint256 _currentMaxaPaybleMintBatch) {
        return currentMaxPayableMintBatch;
    }

    /**
     * @dev Returns details of an Issue: 'price', 'goldSupplyLeft', 'firstEditionSupplyLeft,
     *   'holographicSupplyLeft', 'serialNumberToMintGold', 'serialNumberToMintFirstEdition',
     *   'serialNumberToMintHolographic', 'MaxPayableMintBatch', 'uri' and 'exist'.
     *
     */
    function getIssue(uint256 _issueNumber) external view override returns (Issue memory _issue) {
        return issues[_issueNumber];
    }

    /// @dev Returns token details: 'serialNumber', 'issueNumber' and 'TokenType'
    function getToken(uint256 _tokenId) external view override returns (Token memory _token) {
        return tokens[_tokenId];
    }

    /// @dev User can redeem a copy
    function redeemCopy(uint256 _tokenId) external {
        require(ownerOf(_tokenId) == msg.sender, "HT: Not owner");
        require(redemptions[_tokenId] == false, "HT: already redeemed");

        redemptions[_tokenId] = true;
    }

    // Setup functions
    /// @dev Sets new minter address. Only Owner can call this function.
    function updateMinter(address _minter) external onlyOwner {
        minter = _minter;
    }

    /// @dev Sets if it is allowed to burn tokens. Default is 'false'. Only Minter can call this function.
    function setCanBurn(bool _canBurn) external override onlyMinter {
        canBurn = _canBurn;
    }
    // End setup functions
}
