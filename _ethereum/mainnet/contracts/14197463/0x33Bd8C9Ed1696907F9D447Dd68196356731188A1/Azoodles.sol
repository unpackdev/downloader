// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";

contract Azoodles is ERC721A, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private tokenCounter;

    address private OSProxyRegistry             = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;
    bool private isOpenSeaProxyActive           = true;
    bytes32 public root;

    bool public isActive                        = false;
    uint256 public maxSupply                    = 6969;
    uint256 public MaxPerTx_pub                 = 10;
    uint256 public publicPrice                  = 0.02 ether;
    
    bool public isFreeActive                    = false;
    uint256 public MaxFree                      = 0;
    uint256 public MaxPerTx_free                = 0;
    
    bool public isPreActive                     = false;
    uint256 public MaxPre                       = 969;
    uint256 public MaxPerTx_pre                 = 5;
    uint256 public prePrice                     = 0.02 ether;

    mapping(address => bool) public projectProxy;
    mapping(address => bool) public whitelistedAddresses;
    
    // Sanity Modifiers
    modifier publicSaleActive() {
        require(isActive, "Public sale is not active.");
        _;
    }

    modifier FreeSaleActive() {
        require(isFreeActive, "Free sale is not active.");
        _;
    }

    modifier PreSaleActive() {
        require(isPreActive, "Presale is not active.");
        _;
    }
    
    modifier maxMintsPerTX(uint256 numberOfTokens) {
        require(numberOfTokens <= MaxPerTx_pub, "This exceeds the number of tokens per transaction.");
        _;
    }

    modifier maxMintsPerFreeTX(uint256 numberOfTokens) {
        require(numberOfTokens <= MaxPerTx_free, "This exceeds the maximum number of tokens per transaction during the free mint.");
        _;
    }

    modifier maxMintsPerPreTX(uint256 numberOfTokens) {
        require(numberOfTokens <= MaxPerTx_pre, "This exceeds the maximum number of tokens per transaction during the presale.");
        _;
    }

    modifier NFTsAvailable(uint256 numberOfTokens) {
        require(totalSupply() + numberOfTokens < maxSupply, "Transaction would exceed total token supply.");
        _;
    }

    modifier freeMintsAvailable(uint256 numberOfTokens) {
        require(totalSupply() + numberOfTokens <= MaxFree, "No more free tokens available.");
        _;
    }

    modifier preMintsAvailable(uint256 numberOfTokens) {
        require(totalSupply() + numberOfTokens <= MaxPre, "No more presale tokens available.");
        _;
    }

    modifier isAddressWLed(address _address) {
        require(whitelistedAddresses[_address], "This wallet is not whitelisted." );
        _;
    }

    modifier isCorrectPayment(uint256 price, uint256 numberOfTokens) {
        if(totalSupply() > MaxFree){
        require((price * numberOfTokens) == msg.value, "Incorrect ETH value sent.");
        }
        _;
    }   

    constructor()
        ERC721A("Azoodles", "AZOOD")
    {}

    // Mint Function
    function Mint(uint256 numberOfTokens)
        external
        payable
        nonReentrant
        isCorrectPayment(publicPrice, numberOfTokens)
        publicSaleActive
        NFTsAvailable(numberOfTokens)
        maxMintsPerTX(numberOfTokens)
    {
        _safeMint(msg.sender, numberOfTokens);
    }

    // Free mint Function
    function FreeMint(uint256 numberOfTokens)
        external
        nonReentrant
        FreeSaleActive
        NFTsAvailable(numberOfTokens)
        maxMintsPerFreeTX(numberOfTokens)
        freeMintsAvailable(numberOfTokens)
    {
        _safeMint(msg.sender, numberOfTokens);
    }

    // Premint Function
    function PreMint(uint256 numberOfTokens)
        external
        payable
        nonReentrant
        PreSaleActive
        isCorrectPayment(prePrice, numberOfTokens)
        NFTsAvailable(numberOfTokens)
        maxMintsPerPreTX(numberOfTokens)
        preMintsAvailable(numberOfTokens)
        isAddressWLed(msg.sender)
    {
        _safeMint(msg.sender, numberOfTokens);
    }

    // Owner mint Function
    function OwnerMint(uint256 numberOfTokens)
        external
        onlyOwner
        NFTsAvailable(numberOfTokens)
    {
        _safeMint(msg.sender, numberOfTokens);
    }

    // Owner function to mint for someone else
    function OwnerMintForOthers(uint256 numberOfTokens, address mintReceiver)
        external
        onlyOwner
        NFTsAvailable(numberOfTokens)
    {
        _safeMint(mintReceiver, numberOfTokens);
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

    // Function to set public sale to active
    function setIsActive(bool _isActive)
        external
        onlyOwner
    {
        isActive = _isActive;
    }

    // Function to set free sale to active
    function setFreeMintActive(bool _isFreeActive)
        external
        onlyOwner
    {
        isFreeActive = _isFreeActive;
    }

    // Function to set presale to active
    function setPreMintActive(bool _isPreActive)
        external
        onlyOwner
    {
        isPreActive = _isPreActive;
    }

    // Function to change total number of free mints
    function setNumFreeMints(uint256 _numFreeMints)
        external
        onlyOwner
    {
        MaxFree = _numFreeMints;
    }

    // Function to change total number of pre mints
    function setNumPreMints(uint256 _numPreMints)
        external
        onlyOwner
    {
        MaxPre = _numPreMints;
    }

    // Function to change public mint price
    function setPublicPrice(uint256 _mintPrice)
        external
        onlyOwner
    {
        publicPrice = _mintPrice;
    }

     // Function to change premint price
    function setPrePrice(uint256 _preMintPrice)
        external
        onlyOwner
    {
        prePrice = _preMintPrice;
    }

    // Function to change number of tokens per txn in public sale
    function setTokenPerTxPublic(uint256 _MaxPerTx_pub)
        external
        onlyOwner
    {
        MaxPerTx_pub = _MaxPerTx_pub;
    }

    // Function to change number of tokens per txn in free sale
    function setTokenPerTxFree(uint256 _MaxPerTx_free)
        external
        onlyOwner
    {
        MaxPerTx_free = _MaxPerTx_free;
    }

    // Function to change number of tokens per txn in Presale
    function setTokenPerTxPre(uint256 _MaxPerTx_pre)
        external
        onlyOwner
    {
        MaxPerTx_pre = _MaxPerTx_pre;
    }

    // Functions to set/revoke whitelisted addresses
    function grantWL(address _WLaddress) public onlyOwner {
    whitelistedAddresses[_WLaddress] = true;
    }

    function revokeWL(address _WLaddress) public onlyOwner {
    whitelistedAddresses[_WLaddress] = false;
    }

    function grantWLBatch(address[] memory _WLaddress) public onlyOwner {
    for (uint256 i = 0; i < _WLaddress.length; i++) {
      whitelistedAddresses[_WLaddress[i]] = true;
        }
    }

    // function to verify if an address is WLed
    function verifyUser(address _address) public view returns(bool) {
    bool isWhitelisted = whitelistedAddresses[_address];
    return isWhitelisted;
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