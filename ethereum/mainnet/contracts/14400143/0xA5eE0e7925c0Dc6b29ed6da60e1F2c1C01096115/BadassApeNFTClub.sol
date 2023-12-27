// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./Strings.sol";
import "./ERC721A.sol";

contract BadassApeNFTClub is Ownable, ERC721A, ReentrancyGuard {
    using Strings for uint256;

    bool public saleIsActive = false;
    bool public preSalesIsActive = false;

    string private _nonRevealedURI;
    string private _baseURIextended;

    uint256 public constant MAX_SUPPLY = 8888;
    uint256 public constant MAX_PUBLIC_MINT = 5;
    uint256 public constant PRICE_PER_TOKEN_SALES = 0.15 ether;
    uint256 public constant PRICE_PER_TOKEN_PRE_SALES = 0.10 ether;
    
    bool private revealed = false;

    bytes32 public merkleRoot = 0x4187cfabef52442e6a7cf5c041d3bb146aa490821d157ce0a832ce4d711bb73e;

    mapping(address => uint256) private _allowList;
    mapping(address => uint256) private _allowListMerkleTree;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    constructor(
        string memory name,
        string memory symbol,
        string memory nonRevealedURI
    ) ERC721A(name, symbol) {
        _nonRevealedURI = nonRevealedURI;
    }

    function setPreSalesActive(bool _isPreSalesActive) external onlyOwner {
        preSalesIsActive = _isPreSalesActive;
    }

    function setReveal(bool _revealState) external onlyOwner {
        revealed = _revealState;
    }

    function setMerkleTree(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setAllowList(address[] calldata addresses, uint8 numAllowedToMint) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _allowList[addresses[i]] = numAllowedToMint;
        }
    }

    function numAvailableToMint(address addr) external view returns (uint256) {
        return _allowList[addr];
    }

    function mintAllowList(uint256 numberOfTokens, bytes32[] calldata _merkleProof, uint listType) external payable callerIsUser{
        require(preSalesIsActive, "Allow list is not active");
        require(totalSupply() + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max tokens");
        
        require(listType == 0 || listType == 1, "Invalid list type");

        if(listType == 0) {
            require(numberOfTokens + _allowListMerkleTree[msg.sender] <= 3, "Exceeded max available to purchase");
            
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Invalid proof");
            _allowListMerkleTree[msg.sender] += numberOfTokens;
        }

        if(listType == 1) {
            require(numberOfTokens <= _allowList[msg.sender], "Exceeded max available to purchase");
            _allowList[msg.sender] -= numberOfTokens;
        }
        
        _safeMint(msg.sender, numberOfTokens);
        refundIfOver(PRICE_PER_TOKEN_PRE_SALES * numberOfTokens);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function reserve(uint256 numberOfTokens) external onlyOwner {
        require(totalSupply() + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max tokens");
        _safeMint(msg.sender, numberOfTokens);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        if(revealed == false) {
            return bytes(_nonRevealedURI).length != 0 ? string(abi.encodePacked(_nonRevealedURI, tokenId.toString())) : '';
        }

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : '';
    }

    function setSaleState(bool newState) external onlyOwner {
        saleIsActive = newState;
    }

    function mint(uint256 numberOfTokens) external payable callerIsUser {
        require(numberOfTokens >= 1, "You must mint at least one token");
        require(saleIsActive, "Sale must be active to mint tokens");
        require(numberOfTokens <= MAX_PUBLIC_MINT, "Exceeded max token purchase");
        require(totalSupply() + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max tokens");

        _safeMint(msg.sender, numberOfTokens);
        refundIfOver(PRICE_PER_TOKEN_SALES * numberOfTokens);
    }

    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "Ether value sent is not correct");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}