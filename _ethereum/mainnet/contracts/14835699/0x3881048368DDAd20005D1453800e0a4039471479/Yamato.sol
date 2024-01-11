// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";

error BeforeMint();
error MintReachedMaxSupply();
error MintReachedWhitelistMaxSupply();
error MintReachedSaleSupply();
error MintReachedWhitelistSaleSupply();
error MintValueIsMissing();

contract Yamato is ERC721A('Yamato', 'YMT'), Ownable {
    enum Phase {
        BeforeMint,
        WLMint,
        PublicMint
    }
    address public constant withdrawAddress = 0xD4711934f5ee90b2519be63f0D6b662831E88eaF;
    uint256 public constant maxSupply = 11111;

    mapping(address => uint256) public whitelist;
    mapping(address => uint256) public whitelistMinted;
    mapping(address => uint256) public minted;

    uint256 public whitelistMaxSupply = 3111;
    uint256 public mintCost = 0.025 ether;
    uint256 public witelistMintCost = 0.008 ether;
    uint256 public saleSupply = 11111;
    Phase public phase = Phase.BeforeMint;

    string public baseURI = 'ipfs://QmTg6TuqKowuWjA5M91cbkq9ENKiQNsrNjoobXtJQWojNE/';
    string public metadataExtentions = '.json';

    constructor() {
        _safeMint(withdrawAddress, 1111);
    }

    function mint(uint256 quantity) external payable {
        if (phase != Phase.PublicMint) revert BeforeMint();
        if (totalSupply() + quantity > maxSupply) revert MintReachedMaxSupply();
        if (minted[_msgSender()] + quantity > saleSupply) revert MintReachedSaleSupply();
        if (msg.sender != owner())
            if (msg.value < mintCost * quantity) revert MintValueIsMissing();
        minted[_msgSender()] += quantity;
        _safeMint(msg.sender, quantity);
    }

    function whitelistMint(uint256 quantity) external payable {
        if (phase != Phase.WLMint) revert BeforeMint();
        if (totalSupply() + quantity > whitelistMaxSupply) revert MintReachedWhitelistMaxSupply();
        if (whitelistMinted[_msgSender()] + quantity > whitelist[_msgSender()]) revert MintReachedWhitelistSaleSupply();
        if (msg.sender != owner())
            if (msg.value < witelistMintCost * quantity) revert MintValueIsMissing();
        whitelistMinted[_msgSender()] += quantity;
        _safeMint(msg.sender, quantity);
    }

    function withdraw() public onlyOwner {
        (bool os, ) = payable(withdrawAddress).call{value: address(this).balance}('');
        require(os);
    }

    function setMintCost(uint256 _newCost) public onlyOwner {
        mintCost = _newCost;
    }

    function setWitelistMintCost(uint256 _newCost) public onlyOwner {
        witelistMintCost = _newCost;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setWhitelist(address[] memory addresses, uint256[] memory saleSupplies) public onlyOwner {
        require(addresses.length == saleSupplies.length);
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelist[addresses[i]] = saleSupplies[i];
        }
    }

    function setPhase(Phase _newPhase) public onlyOwner {
        phase = _newPhase;
    }

    function setSaleSupply(uint256 _newSaleSupply) public onlyOwner {
        saleSupply = _newSaleSupply;
    }

    function setWhitelistMaxSupply(uint256 _newWhitelistMaxSupply) public onlyOwner {
        whitelistMaxSupply = _newWhitelistMaxSupply;
    }

    function setMetadataExtentions(string memory _newMetadataExtentions) public onlyOwner {
        metadataExtentions = _newMetadataExtentions;
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(ERC721A.tokenURI(tokenId), metadataExtentions));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}
