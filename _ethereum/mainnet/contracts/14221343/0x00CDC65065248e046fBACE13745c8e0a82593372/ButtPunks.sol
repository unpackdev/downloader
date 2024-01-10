// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./PaymentSplitter.sol";

contract ButtPunks is ERC721A, Ownable, PaymentSplitter {
    using SafeMath for uint256;

    string public constant PROVENANCE =
        "a40233bd0f418ee109ee63b79cfdb230346e3bdab3a630f993c43b688e6beb79";
    address[] private PAY_LIST = [
        0xD1aDe89F8826d122F0a3Ab953Bc293E144042539,
        0x4a4F584cA801192D459aFDF93BE3aE2C627FF8a2,
        0x67E4C81A94506727a4bd57826EB5EE974cfC1AD8
    ];
    uint256[] private PAY_SHARES = [45, 45, 10];
    uint256 public constant TOKEN_PRICE = 0.01 ether;
    uint128 public constant MAX_SUPPLY = 6969;
    uint128 public constant MAX_PURCHASE = 20;
    uint128 public constant RESERVED_TOKENS = 69;
    uint128 public saleStatus = 0; // 0 = off, 1 = presale, 2 = public sale
    string private baseTokenUri;
    mapping(address => uint256) public presaleList;

    constructor(string memory initialBaseTokenUri)
        ERC721A("ButtPunks", "BUTTS")
        PaymentSplitter(PAY_LIST, PAY_SHARES)
    {
        baseTokenUri = initialBaseTokenUri;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function presaleMint(uint256 numberOfTokens) public payable callerIsUser {
        require(
            presaleList[msg.sender] > 0,
            "Wallet not eligible for pre-sale mint"
        );
        require(
            saleStatus > 0,
            "Pre-sale must be active in order to mint a token"
        );
        require(
            numberOfTokens <= MAX_PURCHASE,
            "Each wallet can only mint 20 tokens at a time"
        );
        require(
            totalSupply().add(numberOfTokens) <= MAX_SUPPLY,
            "Purchase would exceed max supply of tokens"
        );
        uint256 totalCost = TOKEN_PRICE.mul(numberOfTokens);
        require(totalCost <= msg.value, "Ether value sent is too low");

        _safeMint(msg.sender, numberOfTokens);
        presaleList[msg.sender]--;

        // Send eth back if over-paid
        if (msg.value > totalCost) {
            payable(msg.sender).transfer(msg.value - totalCost);
        }
    }

    function publicSaleMint(uint256 numberOfTokens)
        public
        payable
        callerIsUser
    {
        require(
            saleStatus > 1,
            "Public sale must be active in order to mint a token"
        );
        require(
            numberOfTokens <= MAX_PURCHASE,
            "Each wallet can only mint 20 tokens at a time"
        );
        require(
            totalSupply().add(numberOfTokens) <= MAX_SUPPLY,
            "Purchase would exceed max supply of tokens"
        );
        uint256 totalCost = TOKEN_PRICE.mul(numberOfTokens);
        require(totalCost <= msg.value, "Ether value sent is too low");

        _safeMint(msg.sender, numberOfTokens);

        // Send eth back if over-paid
        if (msg.value > totalCost) {
            payable(msg.sender).transfer(msg.value - totalCost);
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenUri;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        baseTokenUri = baseURI;
    }

    function setSaleStatus(uint128 newSaleStatus) external onlyOwner {
        saleStatus = newSaleStatus;
    }

    function seedPresaleList(
        address[] memory addressList,
        uint256[] memory numSlots
    ) external onlyOwner {
        require(
            addressList.length == numSlots.length,
            "addressList does not match numSlots length"
        );
        for (uint256 i = 0; i < addressList.length; i++) {
            presaleList[addressList[i]] = numSlots[i];
        }
    }

    // for giveaways, marketing, etc
    function devMint(uint256 numberOfTokens) external onlyOwner {
        require(
            totalSupply().add(numberOfTokens) <= RESERVED_TOKENS,
            "Minting would exceed reserved tokens quantity"
        );
        _safeMint(msg.sender, numberOfTokens);
    }
}
