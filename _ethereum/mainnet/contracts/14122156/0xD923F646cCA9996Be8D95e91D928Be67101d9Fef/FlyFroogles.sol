// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./IERC721Metadata.sol";
import "./IERC721Enumerable.sol";
import "./ERC721A.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./Counters.sol";
import "./ReentrancyGuard.sol";
import "./Context.sol";
import "./Strings.sol";
import "./ERC165.sol";

contract FlyFroogles is ERC721A, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private tokenCounter;

    address private OSProxyRegistry             = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;
    bool private isOpenSeaProxyActive           = true;

    uint256 public MaxPerTx_pub                 = 20;
    uint256 public maxSupply                    = 10001;

    uint256 public constant NFTPrice            = 0.0099 ether;
    uint256 public MaxFree                      = 1001;
    uint256 public MaxPerTx_free                = 3;
    bool public isPublicSaleActive              = false;
    mapping(address => bool) public projectProxy;

    
    // Sanity Modifiers
    modifier publicSaleActive() {
        require(isPublicSaleActive, "Public sale is not active.");
        _;
    }

    modifier maxMintsPerTX(uint256 numberOfTokens) {
        require(numberOfTokens <= MaxPerTx_pub, "Exceeds number of tokens per transaction.");
        _;
    }

    modifier maxMintsPerFreeTX(uint256 numberOfTokens) {
        require(numberOfTokens <= MaxPerTx_free, "During the free minting period, there is a maximum of 3 tokens per transaction.");
        _;
    }

    modifier canMintNFTs(uint256 numberOfTokens) {
        require(totalSupply() + numberOfTokens < maxSupply, "Transaction would exceed total token supply.");
        _;
    }

    modifier freeMintsAvailable() {
        require(totalSupply() < MaxFree, "No more free tokens available.");
        _;
    }

    modifier isCorrectPayment(uint256 price, uint256 numberOfTokens) {
        if(totalSupply() > MaxFree){
        require((price * numberOfTokens) == msg.value, "Incorrect ETH value sent.");
        }
        _;
    }

    constructor()
        ERC721A("FlyFroogles", "FLYFROOGLES")
    {}

    // Mint Function
    function Mint(uint256 numberOfTokens)
        external
        payable
        nonReentrant
        isCorrectPayment(NFTPrice, numberOfTokens)
        publicSaleActive
        canMintNFTs(numberOfTokens)
        maxMintsPerTX(numberOfTokens)
    {
        _safeMint(msg.sender, numberOfTokens);
    }

    // Free Mint Function
    function FreeMint(uint256 numberOfTokens)
        external
        nonReentrant
        publicSaleActive
        canMintNFTs(numberOfTokens)
        maxMintsPerFreeTX(numberOfTokens)
        freeMintsAvailable()
    {
        _safeMint(msg.sender, numberOfTokens);
    }

    // Owner Mint Function
    function GiveawayMint(uint256 numberOfTokens)
        external
        onlyOwner
        canMintNFTs(numberOfTokens)
        maxMintsPerFreeTX(numberOfTokens)
    {
        _safeMint(msg.sender, numberOfTokens);
    }

    // BaseURI Setup | referencing ERC721A contract
    string private _baseTokenURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    // Withdraw funciton
    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    // Function to disable gasless listings for security in case OpenSea ever shuts down or is compromised
    function setIsOpenSeaProxyActive(bool _isOpenSeaProxyActive)
        external
        onlyOwner
    {
        isOpenSeaProxyActive = _isOpenSeaProxyActive;
    }

    function setIsPublicSaleActive(bool _isPublicSaleActive)
        external
        onlyOwner
    {
        isPublicSaleActive = _isPublicSaleActive;
    }

    function setNumFreeMints(uint256 _numfreemints)
        external
        onlyOwner
    {
        MaxFree = _numfreemints;
    }

    function setTokenPerTxPublic(uint256 _MaxPerTx_pub)
        external
        onlyOwner
    {
        MaxPerTx_pub = _MaxPerTx_pub;
    }

    function setTokenPerTxFree(uint256 _MaxPerTx_free)
        external
        onlyOwner
    {
        MaxPerTx_free = _MaxPerTx_free;
    }

    // Supporting Funcitons
    function nextTokenId() private returns (uint256) {
        tokenCounter.increment();
        return tokenCounter.current();
    }

    function isApprovedForAll(address _owner, address operator) public view override returns (bool) {
        require(isOpenSeaProxyActive, "OpenSea Proxy Registry is not active.");
        OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(OSProxyRegistry);
        if (address(proxyRegistry.proxies(_owner)) == operator || projectProxy[operator]) return true;
        return super.isApprovedForAll(_owner, operator);
    }
}

contract OwnableDelegateProxy { }
contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}