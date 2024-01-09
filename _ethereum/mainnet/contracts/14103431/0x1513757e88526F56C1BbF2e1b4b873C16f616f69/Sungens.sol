// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./ERC721.sol";

import "./Ownable.sol";
import "./MerkleProof.sol";


/**
 *    :--------        .---: :%88%-  .---:.+%%%*-----.:----------. *888#   ----.  .--------.
 *  -888%HHHHH==%%%%-  *888+ *88888: *888=+8888HHHHHH:*H8888HHHHH..88888H .8888  %888HHHHHH 
 *  %888+:.    :8888. .8888..8888888-8888 :888% HHHHH--+888%----. =888888*+888* =888%-:.    
 *  *%8888888= -888H  =888H =888*%888888* *888= 8888-+H8888HHHHH: %888*8888888: =H8888888H  
 *      .H888- H888-  %888- %888::888888: 8888. 8888. .888%      -888% *88888%      .=888H  
 *.%%%%%%888H  %888%%%888* :888%  +8888* =8888%%888H  -8888%%%%= H888=  %888%: *%%%%%888%:  
 *
 *  9369 radical optimists visiting from a solarpunk future—where tech, community and nature
 *  save the planet. Drawn by artist Dylan Palermo.
 *
 *  In a radically optimistic world, who will you choose to be?
 */

contract Sungens is
    ERC721,
    Ownable
{
    // Utilize OpenZep utility functions
    using Strings for uint256;

    // Private BaseURI that is held for switching to our randomized metadata
    string private _tokenBaseURI = "";
    string private _placeholderURI = "ipfs://QmTcXCPdabsMey7ja8bASHWa9A8gYnUiQ7ZVCVDr2tNYxS";
    string public provenanceHash = "4beaf0d97a9b0dd4a300e18175074cd2f7c8957c11dd9e3215b6103d9dbed5d0";

    uint256 public offset = 0;
    uint256 public isRevealed = 0;

    uint256 public constant     PRICE_BATCH2 = .03 ether;
    uint256 public constant     PRICE_BATCH3 = .06 ether;
    uint256 public constant     PRICE_PUBLIC = .09 ether;

    uint32 public constant      MAX_SUPPLY = 9369;

    // for the whitelist
    uint8 public constant       MAX_BATCH1       = 1;
    uint8 public constant       MAX_BATCH2       = 2;
    uint8 public constant       MAX_BATCH3       = 3;
    uint8 public constant       MAX_PUBLIC       = 3;

    uint8 public isBatchLive    = 0;
    bool public isPublicSale    = false;
    bool public isPaused        = false;

    // to hold the balances
    mapping(address => uint256) public balancesBatch1;
    mapping(address => uint256) public balancesBatch2;
    mapping(address => uint256) public balancesBatch3;
    mapping(address => uint256) public balancesPublic;

    // a mapping to keep track of each batch
    bytes32 public whitelistBatch1;
    bytes32 public whitelistBatch2;
    bytes32 public whitelistBatch3;

    constructor() ERC721("Sungens", "SUN") { }

    /**
    *   Modifiers to check out minting conditions
    */
    modifier checkIsPublicSale()
    {
        require(isPublicSale, "Public sale is not open");
        _;
    }

    modifier checkAllowedBatchSale(uint8 batch)
    {
        require(batch < 4, "Cannot set batch > 3");
        _;
    }

    modifier checkIsBatchSale(uint256 batch)
    {
        require(isBatchLive != 0 && batch <= isBatchLive, "Sale not open for batch");
        _;
    }

    modifier isInWhitelist(bytes32 root, bytes32[] calldata merkleProof)
    {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(merkleProof, root, leaf),
            "Invalid whitelist verification"
        );
        _;
    }

    modifier doesNotExceedMaxSupply(uint256 numberOfTokens)
    {
        require(
            _tokenIdCount + numberOfTokens < MAX_SUPPLY,
            "Not enough Sungens exist"
        );
        _;
    }

    modifier isCorrectValue(uint256 numberOfTokens, uint256 price)
    {
        require(
            msg.value >= price * numberOfTokens,
            "Not enough ETH"
        );
        _;
    }

    modifier checkIsPaused()
    {
        require(!isPaused, "Sale is paused");
        _;
    }

    modifier offsetIsSet()
    {
        require(offset != 0, "Cannot run sale until offset is set");
        _;
    }

    /**
     *  Minting functions for both public and private mint
     *
     *  We do a few gas-saving tricks here.
     *  We pull variables into memory then save them later.
     *
     *  We check and set the balance immediately as well. No reason to wait.
     *
     *  It is nice not worrying about concurrency issues...
     */
    function mintBatch1(bytes32[] calldata merkleProof)
        external 
        payable
        checkIsPaused
        checkIsBatchSale(1)
        isInWhitelist(whitelistBatch1, merkleProof)
        doesNotExceedMaxSupply(1)
    {
        address sender = msg.sender;
        uint256 balance = balancesBatch1[sender];
        require(
            balance < MAX_BATCH1,
            "Too many Sungens"
        );

        uint256 tokenIdCount = _tokenIdCount;
        balancesBatch1[sender] = 1;

        _mint(sender, (tokenIdCount + offset) % MAX_SUPPLY);
        _tokenIdCount = tokenIdCount + 1;
    }

    function mintBatch2(uint256 numberOfTokens, bytes32[] calldata merkleProof)
        external
        payable
        checkIsPaused
        checkIsBatchSale(2)
        isInWhitelist(whitelistBatch2, merkleProof)
        isCorrectValue(numberOfTokens, PRICE_BATCH2)
        doesNotExceedMaxSupply(numberOfTokens)
    {
        address sender = msg.sender;
        uint256 balance = balancesBatch2[sender];
        require(
            numberOfTokens <= MAX_BATCH2 && balance + numberOfTokens <= MAX_BATCH2,
            "Too many Sungens"
        );

        uint256 tokenIdCount = _tokenIdCount;
        balancesBatch2[sender] = balance + numberOfTokens;

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _mint(sender, (tokenIdCount + offset + i) % MAX_SUPPLY);
        }
        _tokenIdCount = tokenIdCount + numberOfTokens;
    }

    function mintBatch3(uint256 numberOfTokens, bytes32[] calldata merkleProof)
        external
        payable
        checkIsPaused
        checkIsBatchSale(3)
        isInWhitelist(whitelistBatch3, merkleProof)
        isCorrectValue(numberOfTokens, PRICE_BATCH3)
        doesNotExceedMaxSupply(numberOfTokens)
    {
        address sender = msg.sender;
        uint256 balance = balancesBatch3[sender];
        require(
            numberOfTokens <= MAX_BATCH3 && balance + numberOfTokens <= MAX_BATCH3,
            "Too many Sungens"
        );

        uint256 tokenIdCount = _tokenIdCount;
        balancesBatch3[sender] = balance + numberOfTokens;

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _mint(sender, (tokenIdCount + offset + i) % MAX_SUPPLY);
        }
        _tokenIdCount = tokenIdCount + numberOfTokens;
    }

    function mintPublic(uint256 numberOfTokens)
        external
        payable
        checkIsPaused
        checkIsPublicSale
        isCorrectValue(numberOfTokens, PRICE_PUBLIC)
        doesNotExceedMaxSupply(numberOfTokens)
    {
        address sender = msg.sender;
        uint256 balance = balancesPublic[sender];
        require(
            numberOfTokens <= MAX_PUBLIC && balance + numberOfTokens <= MAX_PUBLIC,
            "Too many Sungens"
        );

        uint256 tokenIdCount = _tokenIdCount;
        balancesPublic[sender] = balance + numberOfTokens;

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(sender, (tokenIdCount + offset + i) % MAX_SUPPLY);
        }
        _tokenIdCount = tokenIdCount + numberOfTokens;
    }

    function airdrop(address[] calldata addresses)
        external 
        onlyOwner
        offsetIsSet
        doesNotExceedMaxSupply(addresses.length)
    {
        uint256 tokenIdCount = _tokenIdCount;
        uint256 numberOfTokens = addresses.length;

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _mint(addresses[i], (tokenIdCount + offset + i) % MAX_SUPPLY);
        }
        _tokenIdCount = tokenIdCount + numberOfTokens;
    }

    /**
     *  Functions for handling Base URI pieces
     */
    function _baseURI()
        internal
        override
        view
        returns (string memory)
    {
        return _tokenBaseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        uint256 _isRevealedStart = offset % MAX_SUPPLY;
        uint256 _isRevealedEnd = (offset + isRevealed) % MAX_SUPPLY;

        // this means we looped back around, so we reverse our direction of if statement
        bool loopedBack = _isRevealedEnd < _isRevealedStart;

        if (isRevealed == 0) {
            return _placeholderURI;
        }

        // >= is for an off-by-one error, the bane of a programmer's existence
        if (!loopedBack && (tokenId < _isRevealedStart || tokenId >= _isRevealedEnd)) {
            return _placeholderURI;
        }

        // if we looped back, our end is at the front and our start is at the end, so don't
        // reveal anything in between
        if (loopedBack && (tokenId < _isRevealedStart && tokenId >= _isRevealedEnd)) {
            return _placeholderURI;
        }

        string memory baseURI = _tokenBaseURI;
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, "/", tokenId.toString(), ".json"))
            : "";
    }

    /**
     *  To store data directly on the blockchain, we can use the params.
     *  This may or may not happen, but if it does, we have the code
     */
    function writeImage(uint256 _tokenId, string memory _image, string memory _hash)
        external 
        onlyOwner
    { }

    /**
     *   Admin functions for owners only.
     */
    function setProvenanceHash(string memory _provenanceHash)
        external
        onlyOwner
    {
        provenanceHash = _provenanceHash;
    }

    function setReveal(uint256 reveal)
       external
       onlyOwner
    {
        isRevealed = reveal;
    }

    function setPublicSale(bool _isPublicSale)
        external
        onlyOwner
        offsetIsSet
    {
        isPublicSale = _isPublicSale;
    }

    function setBatchSale(uint8 batch)
        external
        onlyOwner
        checkAllowedBatchSale(batch)
        offsetIsSet
    {
        isBatchLive = batch;
    }

    function setPause(bool pause)
        external
        onlyOwner
    {
        isPaused = pause;
    }

    function setBaseURI(string memory baseURI)
        external
        onlyOwner
    {
        _tokenBaseURI = baseURI;
    }

    function setPlaceholderURI(string memory baseURI)
        external
        onlyOwner
    {
        _placeholderURI = baseURI;
    }

    function setWhitelistBatch1(bytes32 _whitelistRoot)
        external
        onlyOwner
    {
        whitelistBatch1 = _whitelistRoot;
    }

    function setWhitelistBatch2(bytes32 _whitelistRoot)
        external
        onlyOwner
    {
        whitelistBatch2 = _whitelistRoot;
    }

    function setWhitelistBatch3(bytes32 _whitelistRoot)
        external
        onlyOwner
    {
        whitelistBatch3 = _whitelistRoot;
    }

    function withdraw()
        public 
        onlyOwner
    {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function burn(uint256 tokenId)
        external
        onlyOwner
    {
        _burn(tokenId);
    }

    function setOffset(uint256 _offset)
        external       
        onlyOwner
    {
        offset = _offset;
    }

    /**
     * Please note, this will not include airdropped tokens
     * This can be used in the contract if necessary, but it is not accurate.
     * However, it is cheap.
     */
    function balanceOfCheap(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        
        return (balancesBatch1[owner]
            + balancesBatch2[owner]
            + balancesBatch3[owner]
            + balancesPublic[owner]
        );
    }

    /**
     * The balanceOf function is expensive, but because it is a view, we can call this off-chain.
     * That means we can be more accurate. Calling this in the contract will run out of gas.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");

        uint count = 0;
        uint tokenIdCount = _tokenIdCount;

        for( uint i = 0; i < tokenIdCount; ++i ){
            uint index = (offset + i) % MAX_SUPPLY;
            
            if( owner == _owners[index] ) {
                ++count;
            }
        }

        delete tokenIdCount;
        return count;
    }
}
