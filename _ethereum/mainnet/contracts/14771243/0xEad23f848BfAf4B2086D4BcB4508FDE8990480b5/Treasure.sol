// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./ERC721A.sol";
import "./ReentrancyGuard.sol";
import "./PaymentSplitter.sol";
import "./Address.sol";
import "./Ownable.sol";
import "./TreasureMetadata.sol";
import "./ITreasure.sol";

/**
 * @title Treasure (for Warriors) minting contract
 * @author Maxwell J. Rux
 */
contract Treasure is
    ERC721A,
    Ownable,
    ReentrancyGuard,
    PaymentSplitter,
    TreasureMetadata,
    ITreasure
{
    uint256 private constant PRICE = 0.0420 ether;
    uint256 private constant MAX_SUPPLY = 10000;
    uint256 private constant MAX_MULTIMINT = 25;
    uint256 private constant MAX_RESERVE = 250;

    address[] private _payees = [
        0x4f65cDFfE6c48ad287f005AD14E78ff6433c8d67,
        0x49B621D1Cc662cE293779EC775573d0568a0c713,
        0x4427fCC55d41f5eD6989Fc7c6AC1542653192b05,
        0x3b20f287b08f39c21D695500E08268c87eCaeB37
    ];
    uint256[] private _shares = [20, 14, 33, 33];

    string private _contractURI;
    bool private _status = false;

    // number of NFTs in reserve that have already been minted
    uint256 private _reserved = 0;

    constructor(
        Item memory __head,
        Item memory __torso,
        Item memory __footwear,
        Item memory __bottoms,
        Item memory __weapon,
        Item memory __shield,
        Item memory __amulet,
        Item memory __possessive,
        Item memory __extra,
        Item memory __material,
        Item memory __tail
    )
        ERC721A("Treasure (for Warriors)", "T4W")
        PaymentSplitter(_payees, _shares)
        TreasureMetadata(
            __head,
            __torso,
            __footwear,
            __bottoms,
            __weapon,
            __shield,
            __amulet,
            __possessive,
            __extra,
            __material,
            __tail
        )
    {}

    function plunder(uint256 numMints) external payable override nonReentrant {
        require(_status, "Sale is paused");
        require(msg.value >= price() * numMints, "Not enough ether sent");
        require(
            totalSupply() + numMints <= MAX_SUPPLY,
            "New mint exceeds maximum supply"
        );
        require(
            totalSupply() + numMints <= MAX_SUPPLY - MAX_RESERVE + _reserved,
            "New mint exceeds maximum available supply"
        );
        require(numMints <= MAX_MULTIMINT, "Exceeds max mints per transaction");
        _mint(msg.sender, numMints);
    }

    function mintReserveToAddress(uint256 numMints, address recipient)
        external
        onlyOwner
    {
        require(
            totalSupply() + numMints <= MAX_SUPPLY,
            "New mint exceeds maximum supply"
        );
        require(
            _reserved + numMints <= MAX_RESERVE,
            "New mint exceeds reserve supply"
        );
        _reserved += numMints;
        _mint(recipient, numMints);
    }

    function mintReserve(uint256 numMints) external onlyOwner {
        require(
            totalSupply() + numMints <= MAX_SUPPLY,
            "New mint exceeds maximum supply"
        );
        require(
            _reserved + numMints <= MAX_RESERVE,
            "New mint exceeds reserve supply"
        );
        _reserved += numMints;
        _mint(msg.sender, numMints);
    }

    function setCanvasSize(uint256 newSize) external onlyOwner {
        require(!_canvasLocked, "Canvas size locked");
        require(newSize < type(uint16).max, "Value too large");
        _canvasSize = uint16(newSize);
    }

    function lockCanvasSize() external onlyOwner {
        _canvasLocked = true;
    }

    function flipSaleState() external onlyOwner {
        _status = !_status;
    }

    function setContractURI(string memory __contractURI) external onlyOwner {
        _contractURI = __contractURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function status() public view override returns (bool) {
        return _status;
    }

    function contractURI() public view override returns (string memory) {
        return _contractURI;
    }

    function reserved() public view override returns (uint256) {
        return _reserved;
    }

    function price() public pure override returns (uint256) {
        return PRICE;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Query for nonexistant token");
        return buildURI(tokenId);
    }
}
