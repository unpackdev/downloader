// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import "./ERC721.sol";
import "./ERC20.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";   
import "./IERC721DogelonMetadata.sol";
import "./ERC721DogelonMinter.sol";
//
 
contract ERC721Dogelon is IERC721Dogelon, ERC721, Ownable {
    address public minter;
    address public metadata;

    uint256 public tokenId = 1;

    uint256 public price = 9 ether / 1000; // 0.009
    uint256 public startTime = 0;
    uint256 public deadline;
    uint256 public maxSupply = 9000;
    uint256 public whitelistMintSpots = 3000;

    uint256 public whitelistMintingPeriod = 10800; // 3 hours
    bytes32 public whitelistMerkleRoot;
    mapping (address => uint256) public whitelistMintCounts;
    uint256 public whitelistMintCount;

    address public dogelonTokenAddress;
    address public tokenBurnAddress = 0x000000000000000000000000000000000000dEaD;
    uint256 public imageUpdateBasePrice = 50_000_000 ether; // 50m - price in ELON 
    uint256 public imageUpdateMultiplier = 10; // 10 / 100
    uint256 public imageUpdateDivisor = 100;

    // Mappings from imageHash to tokenId and vice versa
    mapping(uint256 => uint256) public imageHashTokenIds;
    mapping(uint256 => uint256) public tokenIdImageHashes;

    // mapping from a tokenId to the current update price
    mapping(uint256 => uint256) public imageUpdates;

    bool public imageUpdatesEnabled = false;

    event MetadataUpdate(uint256 _tokenId);
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

    constructor(
        string memory _name,
        string memory _symbol,
        address minterContract,
        address metadataContract,
        uint256 _maxSupply,
        uint256 _whitelistMintSpots,
        bytes32 _whitelistMerkleRoot,
        address _dogelonTokenAddress
    ) ERC721(_name, _symbol) {
        minter = minterContract;
        metadata = metadataContract;
        maxSupply = _maxSupply;
        whitelistMintSpots = _whitelistMintSpots;
        whitelistMerkleRoot = _whitelistMerkleRoot;
        dogelonTokenAddress = _dogelonTokenAddress;
    }

    function startMint() external onlyOwner {
        require(startTime == 0, "mint already started");
        require(deadline != 0, "deadline must be set");
        startTime = block.timestamp;
    }

    function setStartTime(uint256 _startTime) external onlyOwner {
        require(deadline != 0, "deadline must be set");
        startTime = _startTime;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setTokenBurnAddress(address _tokenBurnAddress) external onlyOwner {
        tokenBurnAddress = _tokenBurnAddress;
    }

    function setImageUpdatesEnabled(bool _imageUpdatesEnabled) external onlyOwner {
        imageUpdatesEnabled = _imageUpdatesEnabled;
    }

    function setImageUpdateBasePrice(uint256 _imageUpdateBasePrice) external onlyOwner {
        imageUpdateBasePrice = _imageUpdateBasePrice;
    }

    function setImageUpdateMultiplier(uint256 _imageUpdateMultiplier) external onlyOwner {
        imageUpdateMultiplier = _imageUpdateMultiplier;
    }

    function setImageUpdateDivisor(uint256 _imageUpdateDivisor) external onlyOwner {
        imageUpdateDivisor = _imageUpdateDivisor;
    }

    function setDeadline(uint256 _deadline) external onlyOwner {
        deadline = _deadline;
    }

    function setWhitelistMintSpots(uint256 _whitelistMintSpots) external onlyOwner {
        whitelistMintSpots = _whitelistMintSpots;
    }

    function setWhitelistMerkleRoot(bytes32 _whitelistMerkleRoot) external onlyOwner {
        whitelistMerkleRoot = _whitelistMerkleRoot;
    }

    function setWhitelistMintingPeriod(uint256 _whitelistMintingPeriod) external onlyOwner {
        whitelistMintingPeriod = _whitelistMintingPeriod;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    function mintingEnabled() public view returns (bool) {
        return tokenId <= maxSupply && deadline > block.timestamp && startTime > 0 && startTime < block.timestamp;       
    }

    function whitelistMintingEnabled() public view returns (bool) {
        return whitelistMintCount < whitelistMintSpots && deadline > block.timestamp && startTime + whitelistMintingPeriod > block.timestamp;
    }

    function setMinterContract(address minterContract) external onlyOwner {
        minter = minterContract;
    }

    function setMetadataContract(address metadataContract) external onlyOwner {
        metadata = metadataContract;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        _requireMinted(_tokenId);

        // send the tokenId and hash to the metadata contract for further processing
        uint256 hash = tokenIdImageHashes[_tokenId];
        string memory uri = IERC721DogelonMetadata(metadata).tokenURI(hash);
        return uri;
    }

    function mint(address to, uint256 imageHash, bytes32[] calldata merkleProof, uint256 whitelistQuantity) external payable {
        require(startTime > 0, "minting is not enabled");
        require(deadline > block.timestamp, "past the deadline to mint");
        require(msg.sender == minter, "must be minter");
        require(msg.value == price, "invalid amount of ether for price");
        
        if (merkleProof.length > 0) {
            require(startTime + whitelistMintingPeriod > block.timestamp, "whitelist minting no longer enabled");
            require(whitelistMintCount < whitelistMintSpots, "whitelist max supply reached");

            bytes32 node = keccak256(abi.encodePacked(to, whitelistQuantity));
            require(MerkleProof.verify(merkleProof, whitelistMerkleRoot, node), "invalid merkle proof");
            require(whitelistMintCounts[to] < whitelistQuantity, "already minted max whitelist quantity for this address");

            whitelistMintCounts[to] += 1;
            whitelistMintCount += 1;
        } else {
            // whitelist minting still enabled
            if (startTime + whitelistMintingPeriod > block.timestamp) {
                require(tokenId <= maxSupply - whitelistMintSpots, "max general supply reached");
            } else {
                require(tokenId <= maxSupply, "total max supply reached");
            }
        }

        // check imageHash doesn't already exist
        require(imageHashTokenIds[imageHash] == 0, "hash exists");

        // store imageHash <=> tokenId
        imageHashTokenIds[imageHash] = tokenId;
        tokenIdImageHashes[tokenId] = imageHash;

        _mint(to, tokenId++);
    }

    // mint for marketplace and explorer indexers to pick up metadata prior to launch
    function ownerMint(uint256 imageHash) external onlyOwner {
        require(tokenId == 1, "only once"); 

        // store imageHash <=> tokenId
        imageHashTokenIds[imageHash] = tokenId;
        tokenIdImageHashes[tokenId] = imageHash;

        _mint(msg.sender, tokenId++);
    }

    function updateImage(address userAddress, uint256 newImageHash, uint256 _tokenId) external {
        require(imageUpdatesEnabled || tokenId > maxSupply, "image updates are not enabled");
        require(msg.sender == minter, "must be minter");
        require(userAddress == ownerOf(_tokenId), "must be owner");

        // look up imageHash from tokenId
        uint256 oldImageHash = tokenIdImageHashes[_tokenId];
        require(oldImageHash != 0, "token doesn't exist");
        require(oldImageHash != newImageHash, "new image hash can't match old image hash");
        
        uint256 numUpdates = imageUpdates[_tokenId];
        uint256 imageUpdatePrice = imageUpdateBasePrice + ((imageUpdateBasePrice * numUpdates * imageUpdateMultiplier)  / imageUpdateDivisor);

        // burn dogelon
        IERC20(dogelonTokenAddress).transferFrom(userAddress, tokenBurnAddress, imageUpdatePrice);

        imageUpdates[_tokenId] = numUpdates + 1;

        // update imageHash <=> tokenId
        imageHashTokenIds[newImageHash] = _tokenId;
        tokenIdImageHashes[_tokenId] = newImageHash;

        // clean up old mapping
        delete imageHashTokenIds[oldImageHash];

        emit MetadataUpdate(_tokenId);
    }

    function burn(uint256 _tokenId) external {
        require(msg.sender == ownerOf(_tokenId), "must be owner");

        // look up imageHash from tokenId
        uint256 imageHash = tokenIdImageHashes[_tokenId];

        // clean up mappings
        delete imageHashTokenIds[imageHash];
        delete tokenIdImageHashes[_tokenId];
        delete imageUpdates[_tokenId];

        _burn(_tokenId);
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function updateMetadata(uint256 _tokenId) external onlyOwner {
        require(tokenIdImageHashes[_tokenId] > 0, "invalid tokenId");
        emit MetadataUpdate(_tokenId);
    }

    function batchUpdateMetadata(uint256 fromTokenId, uint256 toTokenId) external onlyOwner {
        require(fromTokenId <= toTokenId, "invalid range");
        emit BatchMetadataUpdate(fromTokenId, toTokenId);
    }

    function batchUpdateMetadata(uint256[] memory tokenIds) external onlyOwner {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            emit MetadataUpdate(tokenIds[i]);
        }
    }

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        // ERC-4906: EIP-721 Metadata Update Extension
        return interfaceId == bytes4(0x49064906) || super.supportsInterface(interfaceId);
    }

}
