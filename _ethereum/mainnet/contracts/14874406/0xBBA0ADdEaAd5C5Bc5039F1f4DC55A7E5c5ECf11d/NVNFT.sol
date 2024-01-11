// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract NVNFT is ERC721, Ownable {
    constructor() ERC721("NVNFT", "NVNFT") { _nextTokenId.increment(); }

    uint256 public constant MAX_SUPPLY = 8888;
    uint256 public constant TOTAL_PRESALE_SUPPLY = 400;

    uint256 public constant MAX_PRESALE_MINT_PER_TX = 2;
    uint256 public constant MAX_PUBLIC_MINT_PER_TX = 10;
    uint256 public constant MAX_PER_WALLET = 10;

    uint256 public _publicSalePrice = 0.016 ether;

    mapping(address => uint256) public addressMintBalance;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenSupply;
    Counters.Counter private _nextTokenId;

    bool public isPresaleActive = false;
    bool public isPublicSaleActive = false;

    string private _baseURIextended;

    function setIsPresaleActive(bool _isPresaleActive) external onlyOwner {
        isPresaleActive = _isPresaleActive;
    }

    function setIsPublicSaleActive(bool _isPublicSaleActive)
        external
        onlyOwner
    {
        isPublicSaleActive = _isPublicSaleActive;
    }

    function presaleMint(uint256 numberOfTokens) public payable {
        uint256 currentTotalSupply = _tokenSupply.current();
        require(isPresaleActive, "Presale is not active.");

        require(
            currentTotalSupply + numberOfTokens <= TOTAL_PRESALE_SUPPLY,
            "This purchase will exceed max possible number of tokens."
        );

        require(
            addressMintBalance[msg.sender] + numberOfTokens <= MAX_PER_WALLET,
            "This purchase will exceed max possible number of tokens per wallet."
        );

        require(
            numberOfTokens <= MAX_PRESALE_MINT_PER_TX,
            "No sufficient available tokens to purchase."
        );
        
        if (TOTAL_PRESALE_SUPPLY - currentTotalSupply < numberOfTokens) {
            numberOfTokens = TOTAL_PRESALE_SUPPLY - currentTotalSupply;
        }

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _tokenSupply.increment();
            _safeMint(msg.sender, _tokenSupply.current());
        }

        addressMintBalance[msg.sender] += numberOfTokens;
    }

    function publicSaleMint(uint256 numberOfTokens) public payable {
        uint256 currentTotalSupply = _tokenSupply.current();
        require(isPublicSaleActive, "Public sale is not active.");

        require(
            currentTotalSupply + numberOfTokens <= MAX_SUPPLY,
            "This purchase will exceed max possible number of tokens."
        );
        
        require(
            addressMintBalance[msg.sender] + numberOfTokens <= MAX_PER_WALLET,
            "This purchase will exceed max possible number of tokens per wallet."
        );

        require(
            numberOfTokens <= MAX_PUBLIC_MINT_PER_TX,
            "No sufficient available tokens to purchase."
        );

        require(
            _publicSalePrice * numberOfTokens <= msg.value,
            "Ether value sent is not correct/enough."
        );


        if (MAX_SUPPLY - currentTotalSupply < numberOfTokens) {
            numberOfTokens = MAX_SUPPLY - currentTotalSupply;
        }

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _tokenSupply.increment();
            _safeMint(msg.sender, _tokenSupply.current());
        }

        addressMintBalance[msg.sender] += numberOfTokens;
    }

    function totalTokensMinted() public view returns (uint256) {
        return _tokenSupply.current();
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function setPublicSalePrice(uint256 _newPrice) public onlyOwner {
        _publicSalePrice = _newPrice;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}
