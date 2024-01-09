// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./ERC721URIStorage.sol";
import "./Counters.sol";
import "./PullPayment.sol";
import "./Ownable.sol";
import "./Strings.sol";


contract Sweetheartz is ERC721URIStorage, PullPayment, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    Counters.Counter private _freeTokensCounter;

    // Mapping from owner address to tokenId
    mapping(address => uint256) private _latestTokenIdToOwner;

    // Mapping from owner address to free token
    mapping(address => bool) private _freeTokenIdToOwner;

    /// @dev Base token URI used as a prefix by tokenURI().
    string public baseTokenURI;

    // Constants
    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant MAX_FREE_TOKENS = 100;
    uint256 private MINT_PRICE = 0.014 ether;

    // Events
    event PermanentURI(string _value, uint256 indexed _id);

    constructor() public ERC721("Sweetheartz", "SH") {
        baseTokenURI = "";
    }

    function setMintPrice(uint256 price) public onlyOwner {
        MINT_PRICE = price;
    }

    function getMintPrice() public view returns (uint256) {
        return MINT_PRICE;
    }

    function getLatestOwnerTokenId() public view returns (uint256) {
        return _latestTokenIdToOwner[msg.sender];
    }

    function _mintToken(address recipient) private returns (uint256) {
        uint256 tokenId = _tokenIds.current();
        require(tokenId < MAX_SUPPLY, "Max supply reached");

        _latestTokenIdToOwner[msg.sender] = tokenId;

        _tokenIds.increment();
        _safeMint(recipient, tokenId);
        _setTokenURI(tokenId, string(abi.encodePacked(Strings.toString(tokenId), ".json")));
        return tokenId;
    }

    modifier freeToken() {
        uint256 freeTokensCounter = _freeTokensCounter.current();
        require(freeTokensCounter < MAX_FREE_TOKENS, "Free tokens reached to their limit");
        require(_freeTokenIdToOwner[msg.sender] == false, "Free token is already minted for this user");
        _;
    }

    function canMintFreeToken() public view returns (bool) {
        return _freeTokensCounter.current() < MAX_FREE_TOKENS && _freeTokenIdToOwner[msg.sender] == false;
    }

    function mintFree(address recipient) public freeToken
    {
        _mintToken(recipient);
        _freeTokensCounter.increment();
        _freeTokenIdToOwner[msg.sender] = true;
    }

    function mint(address recipient) public onlyOwner
    {
        _mintToken(recipient);
    }

    function mintTo(address recipient) public payable {
        require(msg.value == MINT_PRICE, "Transaction value did not equal the mint price");

        _mintToken(recipient);
        _asyncTransfer(owner(), msg.value);
    }

    function freeze(uint256 tokenId) public onlyOwner {
        emit PermanentURI(tokenURI(tokenId), tokenId);
    }

    function withdrawPayments() public onlyOwner {
        super.withdrawPayments(payable(owner()));
    }

    function payments() public view onlyOwner returns (uint256) {
        return super.payments(owner());
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIds.current();
    }

    function totalFreeSupply() public view returns (uint256) {
        return _freeTokensCounter.current();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseTokenURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function getBaseTokenURI() public view onlyOwner returns (string memory) {
        return _baseURI();
    }
}