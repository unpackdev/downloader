// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Counters.sol";
import "./SafeMath.sol";

contract RowdyKids is ERC721, ERC721Enumerable, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    enum State {
        PrivateSale,
        PreSale,
        PublicSale,
        EndSale,
        None
    }

    State public state;

    string internal baseURI;
    string public provenance;
    uint256 public startingIndexBlock;
    uint256 public startingIndex;

    Counters.Counter private _tokenIdCounter;
    uint256[3] public mintPrice = [ 0.07 ether, 0.08 ether, 0.09 ether ];
    uint256 public maxTokenSupply = 10000;
    uint256 public constant MAX_MINTS_PRESALE = 8000;
    uint256 public constant MAX_MINTS_PRIVATE = 1000;
    uint256 public constant MAX_MINTS_PER_WALLET_PRIVATE = 1;
    uint256 public constant MAX_MINTS_PER_WALLET_PRESALE = 3;
    uint256 public constant MAX_MINTS_PER_TX = 10;

    uint256[3] public saleStartTime;
    uint256[3] public saleEndTime;
    mapping (address => bool)[2] private _presaleAllowList;
    mapping (address => uint256)[2] private _presaleMinted;
    
    constructor() ERC721("RowdyKids", "RKT") {
        state = State.None;
        maxTokenSupply = 10000;
    }

    function setMaxTokenSupply(uint256 _maxTokenSupply) public onlyOwner {
        maxTokenSupply = _maxTokenSupply;
    }
    
    function getMaxTokenSupply() public view returns (uint256) {
        return maxTokenSupply;
    }

    function setMintPrices(uint256[] calldata prices) public onlyOwner {
        for(uint i = 0; i < prices.length; ++i) {
            mintPrice[i] = prices[i];
        }
    }

    function getMintPrices() public view returns (uint256[] memory) {
        uint256[] memory prices = new uint256[](3);
        for (uint i = 0; i < 3; i++) {
            prices[i] = mintPrice[i];
        }
        return prices;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721) returns (string memory) {
        return super.tokenURI(tokenId);
    }
    
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._afterTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * Set the starting index for the collection.
     */
    function setStartingIndex() public onlyOwner {
        require(startingIndex == 0, "Starting index is already set");
        require(startingIndexBlock != 0, "Starting index block must be set");

        startingIndex = uint(blockhash(startingIndexBlock)) % maxTokenSupply;
        // Just a sanity case in the worst case if this function is called late (EVM only stores last 256 block hashes).
        if (block.number - startingIndexBlock > 255) {
            startingIndex = uint(blockhash(block.number - 1)) % maxTokenSupply;
        }
        
        // Prevent default sequence.
        if (startingIndex == 0) {
            startingIndex = 1;
        }
    }

    /**
     * Set the starting index block for the collection. Usually, this will be set after the first sale mint.
     */
    function emergencySetStartingIndexBlock() public onlyOwner {
        require(startingIndex == 0, "Starting index is already set");

        startingIndexBlock = block.number;
    }

    /*     
    * Set provenance once it's calculated
    */
    function setProvenanceHash(string memory _provenanceHash) public onlyOwner {
        provenance = _provenanceHash;
    }

    function addPresaleAddresses(uint index, address[] calldata addresses) public onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _presaleAllowList[index][addresses[i]] = true;
        }
    }

    function isInPresaleAllowList(uint index, address presaleAddress) public view returns (bool) {
        return _presaleAllowList[index][presaleAddress];
    }

    function setSaleTimes(uint256 index, uint256 _startTime, uint256 _endTime) public onlyOwner {
        saleStartTime[index] = _startTime;
        saleEndTime[index] = _endTime;
    }

    function getSaleTimes(uint256 index) public view returns (uint256, uint256) {
        return (saleStartTime[index], saleEndTime[index]);
    }

    function setSaleState(uint256 index) public onlyOwner {
        state = State(index);
    }

    function getSaleState() public view returns (State) {
        return state;
    }

    /*
    * internal function for private & pre sale
    */
    function _internalMint(State _state, uint _numberOfTokens, uint _maxMintWallet, uint _maxMints) private {

        uint8 idx = uint8(_state);
        require(state == _state, "NOT_SALE_STATE");
        require(_presaleAllowList[idx][_msgSender()] == true, "NOT_IN_WHITELIST");
        require(_presaleMinted[idx][_msgSender()] + _numberOfTokens <= _maxMintWallet, "MAX_MINT/WALLET_EXCEEDS");
        require(totalSupply() + _numberOfTokens <= _maxMints, "SOLDOUT");
        require(mintPrice[idx] * _numberOfTokens == msg.value, "PRICE_ISNT_CORRECT");
        require(block.timestamp >= saleStartTime[idx] && block.timestamp <= saleEndTime[idx], "NOT_SALE_TIME");
        _presaleMinted[idx][msg.sender] += _numberOfTokens;

        for(uint256 i = 0; i < _numberOfTokens; i++) {
            uint256 mintIndex = _tokenIdCounter.current() + 1;
            if (mintIndex <= maxTokenSupply) {
                _safeMint(msg.sender, mintIndex);
                _tokenIdCounter.increment();
            }
        }
    }

    /*
    * Private Sale Mint RowdyKids NFTs
    */
    function privateSaleMint() public payable nonReentrant {
        _internalMint(State.PrivateSale, 1, MAX_MINTS_PER_WALLET_PRIVATE, MAX_MINTS_PRIVATE);

        // If we haven't set the starting index, set the starting index block.
        if (startingIndexBlock == 0) {
            startingIndexBlock = block.number;
        }
    }

    /*
    * Pre-sale Mint RowdyKids NFTs
    */
    function presaleMint(uint256 _numberOfTokens) public payable nonReentrant {
        _internalMint(State.PreSale, _numberOfTokens, MAX_MINTS_PER_WALLET_PRESALE, MAX_MINTS_PRESALE);
    }


    /*
    * Public Sale Mint RowdyKids NFTs
    */
    function publicMint(uint _numberOfTokens) public payable nonReentrant {

        require(state == State.PublicSale, "NOT_SALE_STATE");
        require(_numberOfTokens <= MAX_MINTS_PER_TX, "MAX_MINT/TX_EXCEEDS");
        require(totalSupply() + _numberOfTokens <= maxTokenSupply, "SOLDOUT");
        require(mintPrice[2] * _numberOfTokens == msg.value, "PRICE_ISNT_CORRECT");
        require(block.timestamp >= saleStartTime[2], "NOT_SALE_TIME");

        for(uint256 i = 0; i < _numberOfTokens; i++) {
            uint256 mintIndex = _tokenIdCounter.current() + 1;
            if (mintIndex <= maxTokenSupply) {
                _safeMint(msg.sender, mintIndex);
                _tokenIdCounter.increment();
            }
        }
    }

    /*
    * Mint reserved NFTs for giveaways, dev, etc.
    */
    function reserveMint(uint256 reservedAmount) public onlyOwner nonReentrant {
        require(totalSupply() + reservedAmount <= maxTokenSupply);
        
        uint256 mintIndex = _tokenIdCounter.current() + 1;
        for (uint256 i = 0; i < reservedAmount; i++) {
            _safeMint(msg.sender, mintIndex + i);
            _tokenIdCounter.increment();
        }
    }

    function withdrawAll() public onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(_msgSender()), balance);
    }
}