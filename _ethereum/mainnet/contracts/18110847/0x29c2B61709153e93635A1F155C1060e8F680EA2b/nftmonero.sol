// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./EIP712.sol";
import "./Counters.sol";
import "./Strings.sol";

contract Martians is  ERC721Enumerable, Ownable, EIP712 {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIdCounter;
    uint256 maxSupply = 1000;
    bool public publicMintOpen = false;
    bool public allowListMintOpen = false;
    string private _contractBaseURI;
    bytes32 private _secret;

    constructor() ERC721("Monero Martians", "FEFMLMKU1984") EIP712("monero_martians", "1") {
        _contractBaseURI = "ipfs://bafybeifzbz5znq4m3qhgxcjchoz4jwho56at3xin5vq3ndbjc2sybpjhue";
        _secret = keccak256(abi.encodePacked(block.timestamp));
    }


    uint256 public constant royaltyPercentage = 5;


    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {

        receiver = ownerOf(_tokenId);

        royaltyAmount = (_salePrice * royaltyPercentage) / 100;
    }

    function mintReserveSupply(uint256 numTokens) external onlyOwner {
        require(numTokens <= maxSupply / 10, "Exceeds reserve supply");
        require(_tokenIdCounter.current() + numTokens <= maxSupply, "Exceeds max supply");

        for (uint256 i = 0; i < numTokens; i++) {
            internalMint(owner());
        }
    }

    function getBaseURI() internal view returns (string memory) {
        return _contractBaseURI;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        _contractBaseURI = newBaseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = getBaseURI();
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, "/", tokenId.toString(), '.json'))
            : '';
    }

    mapping(address => uint256) private _allowList;

    function setAllowances(address[] memory holders, uint256[] memory allowances) external onlyOwner {
        require(holders.length == allowances.length, "Mismatched input lengths");
        for (uint256 i = 0; i < holders.length; i++) {
            _allowList[holders[i]] = allowances[i];
        }
    }

    function allowListMint(uint256 numTokens) public {
        require(allowListMintOpen, "Allowlist Mint Closed");
        require(_allowList[msg.sender] >= numTokens, "No allowance for this address");
        require(_tokenIdCounter.current() + numTokens <= maxSupply, "Exceeds max supply");

        for (uint256 i = 0; i < numTokens; i++) {
            internalMint(msg.sender);
            _allowList[msg.sender]--;
        }
    }

    function editMintWindows(bool _publicMintOpen, bool _allowListMintOpen) external onlyOwner {
        publicMintOpen = _publicMintOpen;
        allowListMintOpen = _allowListMintOpen;
    }

    function withdraw(address _addr) external onlyOwner {
        uint256 balance = address(this).balance;
        payable(_addr).transfer(balance);
    }

    function publicMint(uint256 numTokens) public payable {
        require(publicMintOpen, "Public Mint Closed");
        require(numTokens > 0, "Must mint at least one token");
        require(_tokenIdCounter.current() + numTokens <= maxSupply, "Exceeds max supply");
        require(msg.value >= 0.01 ether * numTokens, "Insufficient funds");

        for (uint256 i = 0; i < numTokens; i++) {
            internalMint(msg.sender);
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _afterTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721)
    {
        super._afterTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

function internalMint(address to) private {
    require(_tokenIdCounter.current() < maxSupply, "Sold out!");

    _tokenIdCounter.increment();
    uint256 rawId = _tokenIdCounter.current();
    uint256 tokenId = uint256(keccak256(abi.encodePacked(_secret, rawId))) % maxSupply + 1;

    _mint(to, tokenId); 
}
}