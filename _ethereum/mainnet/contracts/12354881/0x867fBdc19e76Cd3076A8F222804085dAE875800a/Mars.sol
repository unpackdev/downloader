// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

import "./Mars26.sol";
import "./MarsStorage.sol";

/**
 * @title Mars contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract Mars is Ownable, ERC721Enumerable {
    using SafeMath for uint256;

    bytes32 private _provenanceHash;

    uint256 internal _maxSupply;

    uint256 private _nameChangePrice;

    uint256 private _saleStartTimestamp;
    uint256 private _revealTimestamp;
    uint256[6] private _priceIntervalSupplyLimits;

    uint256 private _startingIndexBlock;
    uint256 internal _startingIndex;

    mapping (uint256 => string) private _tokenNames;
    mapping (string => bool) private _reservedNames;
    mapping (uint256 => bool) private _mintedBeforeReveal;

    Mars26 private _m26;
    MarsStorage private _storage;

    event NameChange (uint256 indexed maskIndex, string newName);

    /**
     * @dev Sets immutable values of contract.
     */
    constructor (
        bytes32 provenanceHash_,
        address m26Address_,
        uint256 nameChangePrice_,
        uint256 saleStartTimestamp_,
        uint256 revealTimestamp_,
        uint256 maxSupply_,
        uint256[6] memory priceIntervalSupplyLimits_
    ) ERC721("Mars", "MARS") {
        _provenanceHash = provenanceHash_;
        
        _m26 = Mars26(m26Address_);
        _nameChangePrice = nameChangePrice_;
        
        _saleStartTimestamp = saleStartTimestamp_;
        _revealTimestamp = revealTimestamp_;

        for (uint i = 1; i < priceIntervalSupplyLimits_.length; i++) {
            require(
                priceIntervalSupplyLimits_[i - 1] < priceIntervalSupplyLimits_[i],
                "Price intervale supply limit need to ascending"
            );
        }

        _priceIntervalSupplyLimits = priceIntervalSupplyLimits_;

        _maxSupply = maxSupply_;

        _storage = new MarsStorage(maxSupply_);
    }

    /**
     * @dev Returns provenance hash digest set during initialization of contract.
     * 
     * The provenance hash is derived by concatenating all existing IPFS CIDs (v0)
     * of the Mars NFTs and hashing the concatenated string using SHA2-256.
     * Note that the CIDs were concatenated and hashed in their base58 representation.
     */
    function provenanceHash() public view returns (bytes32) {
        return _provenanceHash;
    }

    /**
     * @dev Returns address of Mars26 ERC-20 token contract.
     */
    function m26Address() public view returns (address) {
        return address(_m26);
    }

    /**
     * @dev Returns address of connected storage contract.
     */
    function storageAddress() public view returns (address) {
        return address(_storage);
    }

    /**
     * @dev Returns max number of NFTs that can be minted.
     */
    function maxSupply() public view returns (uint256) {
        return _maxSupply;
    }

    /**
     * @dev Returns the MNCT price for changing the name of a token.
     */
    function nameChangePrice() public view returns (uint256) {
        return _nameChangePrice;
    }

    /**
     * @dev Returns the start timestamp of the initial sale.
     */
    function saleStartTimestamp() public view returns (uint256) {
        return _saleStartTimestamp;
    }

    /**
     * @dev Returns the reveal timestamp after which the token ids will be assigned.
     */
    function revealTimestamp() public view returns (uint256) {
        return _revealTimestamp;
    }

    /**
     * @dev Returns the set upper supply limits which determine the NFT price during sale.
     */
    function priceIntervalSupplyLimits() public view returns (uint256[6] memory) {
        return _priceIntervalSupplyLimits;
    }

    /**
     * @dev Returns the randomized starting index to assign and reveal token ids to
     * intial sequence of NFTs.
     */
    function startingIndex() public view returns (uint256) {
        return _startingIndex;
    }

    /**
     * @dev Returns the randomized starting index block which is used to derive
     * {_startingIndex} from.
     */
    function startingIndexBlock() public view returns (uint256) {
        return _startingIndexBlock;
    }

    /**
     * @dev See {MarsStorage.initialSequenceTokenCID}
     */
    function initialSequenceTokenCID(uint256 initialSequenceIndex) public view returns (string memory) {
        return _storage.initialSequenceTokenCID(initialSequenceIndex);
    }

    /**
     * @dev Returns if {nameString} has been reserved.
     */
    function isNameReserved(string memory nameString) public view returns (bool) {
        return _reservedNames[_toLower(nameString)];
    }

    /**
     * @dev Returns reverved name for given token id.
     */
     function tokenNames(uint256 tokenId) public view returns (string memory) {
         return _tokenNames[tokenId];
     }

    /**
     * @dev Returns the set token URI, i.e. IPFS v0 CID, of {tokenId}.
     * Prefixed with ipfs://
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");
        require(_startingIndex > 0, "Tokens have not been assigned yet");

        uint256 initialSequenceIndex = _toInitialSequenceIndex(tokenId);
        return tokenURIOfInitialSequenceIndex(initialSequenceIndex);
    }

    /**
     * @dev Returns the set token URI, i.e. IPFS v0 CID, of {initialSequenceIndex}.
     * Prefixed with ipfs://
     */
    function tokenURIOfInitialSequenceIndex(uint256 initialSequenceIndex) public view returns (string memory) {
        require(_startingIndex > 0, "Tokens have not been assigned yet");

        string memory tokenCID = initialSequenceTokenCID(initialSequenceIndex);
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return tokenCID;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(tokenCID).length > 0) {
            return string(abi.encodePacked(base, tokenCID));
        }

        return base;
    }

    /**
     * @dev Returns if the NFT has been minted before reveal phase.
     */
    function isMintedBeforeReveal(uint256 index) public view returns (bool) {
        return _mintedBeforeReveal[index];
    }

    /**
     * @dev Gets current NFT price based on already minted tokens.
     */
    function getNFTPrice() public view returns (uint256) {
        uint currentSupply = totalSupply();

        if (currentSupply < _priceIntervalSupplyLimits[0]) {
           return 0.05 ether; 
        } else if (currentSupply < _priceIntervalSupplyLimits[1]) {
           return 0.1 ether; 
        } else if (currentSupply < _priceIntervalSupplyLimits[2]) {
           return 0.2 ether; 
        } else if (currentSupply < _priceIntervalSupplyLimits[3]) {
           return 0.4 ether; 
        } else if (currentSupply < _priceIntervalSupplyLimits[4]) {
            return 1 ether;
        } else if (currentSupply < _priceIntervalSupplyLimits[5]) {
            return 3 ether;
        } else {
            return 26 ether;
        }
    }

    /**
     * @dev Mints Mars NFTs
     */
    function mintNFT(uint256 numberOfNfts) public payable {
        require(block.timestamp >= _saleStartTimestamp, "Sale has not started");
        require(totalSupply() < _maxSupply, "Sale has already ended");
        require(numberOfNfts > 0, "Cannot buy 0 NFTs");
        require(numberOfNfts <= 20, "You may not buy more than 20 NFTs at once");
        require(totalSupply().add(numberOfNfts) <= _maxSupply, "Exceeds max number of NFTs in existence");
        require(getNFTPrice().mul(numberOfNfts) == msg.value, "Ether value sent is not correct");

        for (uint i = 0; i < numberOfNfts; i++) {
            uint mintIndex = totalSupply();
            
            require(mintIndex < _maxSupply, "Exceeds max number of NFTs in existence");

            if (block.timestamp < _revealTimestamp) {
                _mintedBeforeReveal[mintIndex] = true;
            }
            _safeMint(msg.sender, mintIndex);
        }

        // Source of randomness. Theoretical miner withhold manipulation possible but should be sufficient in a pragmatic sense 
        if (_startingIndexBlock == 0 && (totalSupply() == _maxSupply || block.timestamp >= _revealTimestamp)) {
            _startingIndexBlock = block.number;
        }
    }

    /**
     * @dev Finalize starting index
     */
    function finalizeStartingIndex() public {
        require(_startingIndex == 0, "Starting index is already set");
        require(_startingIndexBlock != 0, "Starting index block must be set");
        
        _startingIndex = uint(blockhash(_startingIndexBlock)) % _maxSupply;
        // Just a sanity case in the worst case if this function is called late (EVM only stores last 256 block hashes)
        if (block.number.sub(_startingIndexBlock) > 255) {
            _startingIndex = uint(blockhash(block.number - 1)) % _maxSupply;
        }
        // Prevent default sequence
        if (_startingIndex == 0) {
            _startingIndex = _startingIndex.add(1);
        }
    }

    /**
     * @dev Changes the name for Mars tile tokenId
     */
    function changeName(uint256 tokenId, string memory newName) public {
        address owner = ownerOf(tokenId);

        require(_msgSender() == owner, "ERC721: caller is not the owner");
        require(_validateName(newName) == true, "Not a valid new name");
        require(sha256(bytes(newName)) != sha256(bytes(_tokenNames[tokenId])), "New name is same as the current one");
        require(isNameReserved(newName) == false, "Name already reserved");

        _m26.transferFrom(msg.sender, address(this), _nameChangePrice);
        // If already named, dereserve old name
        if (bytes(_tokenNames[tokenId]).length > 0) {
            _toggleReserveName(_tokenNames[tokenId], false);
        }
        _toggleReserveName(newName, true);
        _tokenNames[tokenId] = newName;
        _m26.burn(_nameChangePrice);
        emit NameChange(tokenId, newName);
    }

    /**
     * @dev Withdraw ether from this contract (Callable by owner)
     */
    function withdraw() onlyOwner public {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    /**
     * @dev See {MarsStorage.setInitialSequenceTokenHashes}
     */
    function setInitialSequenceTokenHashes(bytes32[] memory tokenHashes) onlyOwner public {
        _storage.setInitialSequenceTokenHashes(tokenHashes);
    }

    /**
     * @dev See {MarsStorage.setInitialSequenceTokenHashesAtIndex}
     */
    function setInitialSequenceTokenHashesAtIndex(
        uint256 startIndex,
        bytes32[] memory tokenHashes
    ) public onlyOwner {
        _storage.setInitialSequenceTokenHashesAtIndex(startIndex, tokenHashes);
    }

    /**
     * @dev Check if the name string is valid (Alphanumeric and spaces without leading or trailing space)
     */
    function _validateName(string memory str) private pure returns (bool){
        bytes memory b = bytes(str);
        if (b.length < 1) return false;
        if (b.length > 50) return false; // Cannot be longer than 25 characters
        if (b[0] == 0x20) return false; // Leading space
        if (b[b.length - 1] == 0x20) return false; // Trailing space

        bytes1 lastChar = b[0];

        for (uint i; i < b.length; i++) {
            bytes1 char = b[i];

            if (char == 0x20 && lastChar == 0x20) return false; // Cannot contain continous spaces

            if (
                !(char >= 0x30 && char <= 0x39) && //9-0
                !(char >= 0x41 && char <= 0x5A) && //A-Z
                !(char >= 0x61 && char <= 0x7A) && //a-z
                !(char == 0x20) //space
            )
                return false;

            lastChar = char;
        }

        return true;
    }

    /**
     * @dev Converts the string to lowercase
     */
    function _toLower(string memory str) private pure returns (string memory){
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint i = 0; i < bStr.length; i++) {
            // Uppercase character
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }

    /**
     * @dev Reserves the name if isReserve is set to true, de-reserves if set to false
     */
    function _toggleReserveName(string memory str, bool isReserve) internal {
        _reservedNames[_toLower(str)] = isReserve;
    }

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://";
    }

    function _toInitialSequenceIndex(uint256 tokenId) internal view returns (uint256) {
        return (tokenId + _startingIndex) % _maxSupply;
    }
}