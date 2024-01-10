// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./ERC721Burnable.sol";
import "./Counters.sol";
import "./MerkleProof.sol";

/// @custom:security-contact security@thenftysetup.com
contract TheNFTySetupErc721 is ERC721, ERC721Enumerable, Pausable, Ownable, ERC721Burnable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _reservedIdCounter;
    uint8  public _reservedTokens;
    uint32 public MAX_SUPPLY;
    uint32 public VIPSALE_START;
    uint64 public VIPSALE_MINT_PRICE;
    uint8  public VIPSALE_MINT_LIMIT;
    uint32 public PRESALE_START;
    uint64 public PRESALE_MINT_PRICE;
    uint8  public PRESALE_MINT_LIMIT;
    uint32 public MINT_START;
    uint64 public MINT_PRICE;
    uint8  public MINT_LIMIT;
    address payable public PAYMENT_ADDRESS;
    bytes32 public VIPSALE_MERKLEROOT;
    bytes32 public PRESALE_MERKLEROOT;
    bool public COLLECTION_HIDDEN;
    string public COLLECTION_BASE_URI;
    string public CONTRACT_METADATA_URI;

    constructor(address payable paymentAddress, uint32 vipsaleStart, uint32 presaleStart, uint32 mintStart) ERC721("Metamouse Clubhouse", "METACLUBHOUSE") {
        _reservedTokens = 150;
        for (uint16 i = 0; i < _reservedTokens; i++) {
            _tokenIdCounter.increment();
        }
        MAX_SUPPLY = 8_527;
        VIPSALE_START = vipsaleStart;
        VIPSALE_MINT_PRICE = 0.04 ether;
        VIPSALE_MINT_LIMIT = 10;
        PRESALE_START = presaleStart;
        PRESALE_MINT_PRICE = 0.07 ether;
        PRESALE_MINT_LIMIT = 5;
        MINT_START = mintStart;
        MINT_PRICE = 0.1 ether;
        MINT_LIMIT = 5;
        PAYMENT_ADDRESS = paymentAddress;
        COLLECTION_HIDDEN = true;
        COLLECTION_BASE_URI = "https://gateway.pinata.cloud/ipfs/QmYCEu4SmSzquWMxeHgbfSBDPbh5VqykDSbaQdPmUnKJxT/0.json";
        CONTRACT_METADATA_URI = "https://gateway.pinata.cloud/ipfs/QmYetoNz7yryVQVHtodHqUYFaNrvWdTDTvwfPVJxsmmvu4";
    }

    function _baseURI() internal view override returns (string memory) {
        return COLLECTION_BASE_URI;
    }

    function contractURI() public view returns (string memory) {
        return CONTRACT_METADATA_URI;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setMerkleRoots(bytes32 vip, bytes32 presale)
        public
        onlyOwner
    {
        VIPSALE_MERKLEROOT = vip;
        PRESALE_MERKLEROOT = presale;
    }

    function mint(bytes32[] calldata _merkleProof, uint256 _mintQuantity)
        public
        payable
        whenNotPaused
    {
        require(_mintQuantity > 0, "Quantity cannot be 0");
        require(tx.origin == msg.sender, "Contracts are not allowed to mint this collection");
        if (block.timestamp >= MINT_START) {
            // Public sale
            require(msg.value >= MINT_PRICE * _mintQuantity, "Insufficient funds submitted");
            require(_mintQuantity <= MINT_LIMIT, "Quantity exceeds MINT_LIMIT");
        } else if (block.timestamp >= PRESALE_START) {
            // Presale
            require(msg.value >= PRESALE_MINT_PRICE * _mintQuantity, "Insufficient funds submitted");
            require(_mintQuantity <= PRESALE_MINT_LIMIT, "Quantity exceeds PRESALE_MINT_LIMIT");
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            require(MerkleProof.verify(_merkleProof, PRESALE_MERKLEROOT, leaf), "Whitelist is required to mint at this time");
        } else if (block.timestamp >= VIPSALE_START) {
            // VIP Sale
            require(msg.value >= VIPSALE_MINT_PRICE * _mintQuantity, "Insufficient funds submitted");
            require(_mintQuantity <= VIPSALE_MINT_LIMIT, "Quantity exceeds PRESALE_MINT_LIMIT");
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            require(MerkleProof.verify(_merkleProof, VIPSALE_MERKLEROOT, leaf), "VIP is required to mint at this time");
        } else {
            revert("Sale is not active");
        }
        uint256 tokenId = _tokenIdCounter.current();
        require(tokenId + _mintQuantity < MAX_SUPPLY, "Collection reached MAX_SUPPLY");

        // All gates passed, transfer funds & mint token
        PAYMENT_ADDRESS.transfer(msg.value);
        for (uint256 i = tokenId; i < tokenId + _mintQuantity; i++) {
            _safeMint(msg.sender, i);
            _tokenIdCounter.increment();
        }
    }

    function mintReserved(address[] memory addresses, uint8[] memory quantities)
        public
        whenNotPaused
        onlyOwner
    {
        require(addresses.length == quantities.length, "Array lengths must match");
        uint8 sum = 0;
        for (uint8 i = 0; i < quantities.length; i++)
        {
            sum = sum + quantities[i];
        }
        require(sum <= _reservedTokens - _reservedIdCounter.current(), "Quantities exceed reservation");
        
        for (uint8 i = 0; i < addresses.length; i++) {
            for (uint8 x = 0; x < quantities[i]; x++) {
                _safeMint(addresses[i], _reservedIdCounter.current());
                _reservedIdCounter.increment();
            }
        }
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        if (COLLECTION_HIDDEN) {
            return COLLECTION_BASE_URI;
        }
        return string(abi.encodePacked(_baseURI(), tokenId.toString(), ".json"));
    }

    function revealCollection(string memory collectionUri, string memory contractUri) public onlyOwner {
        COLLECTION_HIDDEN = false;
        COLLECTION_BASE_URI = collectionUri;
        CONTRACT_METADATA_URI = contractUri;
    }
    
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setDates(uint32 _vipsaleStart, uint32 _presaleStart, uint32 _mintStart)
        public
        onlyOwner
    {
        VIPSALE_START = _vipsaleStart;
        PRESALE_START = _presaleStart;
        MINT_START = _mintStart;
    }
}
