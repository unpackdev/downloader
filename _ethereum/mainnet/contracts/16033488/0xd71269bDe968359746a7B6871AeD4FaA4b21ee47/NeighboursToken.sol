// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Address.sol";

/// @title NeighboursToken Contract
/// @author Neighbours team
/// @notice We are The Neighbours - a squad of diverse, yet like-minded cosmic hobos. We express our skills in fantastic paintings and convert them into NFT collectibles. Join us now to discover more!
contract NeighboursToken is ERC721, Ownable {
    /// @notice Openzeppelin type bindings
    using Address for address payable;
    using Strings for uint256;
    using Counters for Counters.Counter;

    /// Vars

    /// @notice Start ID for unique Neighbours
    uint constant UNIQUE_IMAGE_ID_START = 10000;

    /// @notice Tokens counter
    Counters.Counter private _tokenIdCounter;

    /// @notice Unique tokens counter
    Counters.Counter private _uniqueImageIdCounter;

    /// @notice Default metadata IPFS CID
    string private _defaultMetaCID;

    /// @notice TokenId -> Metadata IPFS CID mapping
    mapping(uint => string) private _tokenCIDs;

    /// @notice ImageId -> TokenId mapping
    mapping(uint => uint) private _imageTokens;

    /// @notice TokenId -> Is painting ordered for token mapping
    mapping(uint => bool) private _tokenPaintingOrdered;

    /// @notice Mint allowing flag
    bool private _mintAllowed = false;

    /// @notice Current images pool for minting
    uint[] private _imagesToMint;

    /// @notice Current images pool for minting length
    uint private _imagesToMintLength;

    /// @notice Mint price
    uint private _mintPrice;

    /// @notice Mint unique price
    uint private _mintUniquePrice;

    /// @notice Order painting price
    uint private _paintingPrice;

    /// @notice COO address
    address private _COO;

    /// Events

    /// @notice Emits when mint price set
    /// @param mintPrice Price for mint in WEI
    event MintPriceSet(uint mintPrice);

    /// @notice Emits when mint unique price set
    /// @param mintUniquePrice Price for unique mint in WEI
    event MintUniquePriceSet(uint mintUniquePrice);

    /// @notice Emits when order painting price set
    /// @param paintingPrice Price for order painting in WEI
    event PaintingPriceSet(uint paintingPrice);

    /// @notice Emits when mint allowance set
    /// @param allowed Mint allowance
    event MintAllowanceSet(bool allowed);

    /// @notice Emits when image ids to mint set
    /// @param _images Image ids to mint array
    event ImagesToMintSet(uint[] _images);

    /// @notice Emits when new token bought
    /// @param from Caller address
    /// @param to New token owner address
    /// @param tokenId New token id
    /// @param imageId Image id on the basis of which the token was bought
    /// @param price Token price in WEI
    event TokenBought(address from, address to, uint tokenId, uint imageId, uint price);

    /// @notice Emits when new unique token bought
    /// @param from Caller address
    /// @param to New token owner address
    /// @param tokenId New token id
    /// @param imageId Image id on the basis of which the unique token was bought
    /// @param price Token price in WEI
    event TokenUniqueBought(address from, address to, uint tokenId, uint imageId, uint price);

    /// @notice Emits when new unique token bought
    /// @param to Token owner address
    /// @param tokenId Token id
    /// @param price Painting price in WEI
    event TokenPaintingOrdered(address to, uint tokenId, uint price);

    /// @notice Emits when token metadata CID set
    /// @param tokenId Token id
    /// @param metaCID Metadata IPFS CID
    event TokenMetaCIDSet(uint tokenId, string metaCID);

    /// @notice Emits when token metadata CID set
    /// @param operator Caller address
    /// @param to Destination wallet address
    /// @param amount Withdrawn amount in WEI
    event EthersWithdrawn(address indexed operator, address indexed to, uint amount);

    /// Function modifiers

    /// @notice Prevent call function if minting not allowed
    modifier ifMintAllowed() {
        require(_mintAllowed, "NeighboursToken: minting is not allowed");
        _;
    }

    /// @notice Prevent call function from any wallets except COO or owner
    modifier onlyCOO() {
        require(
            (owner() == _msgSender()) ||
            (_COO == _msgSender()), "NeighboursToken: not enough privileges to call method");
        _;
    }

    /// @notice Contract constructor
    constructor() ERC721("NeighboursToken", "NGT") {}

    /// @notice Get COO wallet address
    /// @return COO wallet address
    function COO() external view returns (address) {
        return _COO;
    }

    /// @notice Set COO wallet address
    /// @param _coo COO wallet address
    function setCOO(address _coo) external onlyOwner {
        _COO = _coo;
    }

    /// @notice Get mint allowance
    /// @return Mint allowance flag
    function mintAllowed() external view returns (bool) {
        return _mintAllowed;
    }

    /// @notice Set mint allowance
    /// @param _mintAllowedParam Mint allowance flag
    function setMintAllowed(bool _mintAllowedParam) external onlyOwner {
        _mintAllowed = _mintAllowedParam;
        emit MintAllowanceSet(_mintAllowed);
    }

    /// @notice Get mint price
    /// @return Mint price in WEI
    function mintPrice() external view returns (uint) {
        return _mintPrice;
    }

    /// @notice Set mint price
    /// @param _mintPriceParam Mint price in WEI
    function setMintPrice(uint _mintPriceParam) external onlyOwner {
        _mintPrice = _mintPriceParam;
        emit MintPriceSet(_mintPrice);
    }

    /// @notice Get mint unique price
    /// @return Mint unique price in WEI
    function mintUniquePrice() external view returns (uint) {
        return _mintUniquePrice;
    }

    /// @notice Set mint unique price
    /// @param _mintUniquePriceParam Mint unique price in WEI
    function setMintUniquePrice(uint _mintUniquePriceParam) external onlyOwner {
        _mintUniquePrice = _mintUniquePriceParam;
        emit MintUniquePriceSet(_mintUniquePrice);
    }

    /// @notice Get painting ordering price
    /// @return Painting ordering price in WEI
    function paintingPrice() external view returns (uint) {
        return _paintingPrice;
    }

    /// @notice Set painting ordering price
    /// @param _paintingPriceParam Painting ordering price in WEI
    function setPaintingPrice(uint _paintingPriceParam) external onlyOwner {
        _paintingPrice = _paintingPriceParam;
        emit PaintingPriceSet(_paintingPrice);
    }

    /// @notice Get default metadata CID for new tokens
    /// @return Metadata IPFS CID
    function defaultMetaCID() view external returns (string memory) {
        return _defaultMetaCID;
    }

    /// @notice Set default metadata CID for new tokens
    /// @param defaultMetaCIDParam Metadata IPFS CID
    function setDefaultMetaCID(string memory defaultMetaCIDParam) external onlyCOO {
        _defaultMetaCID = defaultMetaCIDParam;
    }

    /// @notice Get current image ids for minting
    /// @return Image ids array
    function imagesToMint() external view returns (uint[] memory) {
        return _imagesToMint;
    }

    /// @notice Set current images pool for minting
    /// @param _images Image ids array
    function setImagesToMint(uint[] calldata _images) external onlyOwner {
        _imagesToMint = _images;
        _imagesToMintLength = _imagesToMint.length;
        emit ImagesToMintSet(_images);
    }

    /// @notice Internal minting helper
    /// @param to Token owner address
    /// @param imageId Image id
    /// @return New token id
    function _mintNewToken(address to, uint imageId) internal returns (uint) {
        require(_imageTokens[imageId] == 0, "NeighboursToken: image already taken");

        _tokenIdCounter.increment();
        uint tokenId = _tokenIdCounter.current();
        _safeMint(to, tokenId);
        _imageTokens[imageId] = tokenId;

        return tokenId;
    }

    /// @notice Mint gift token
    /// @param to Token owner address
    /// @param imageId Image id
    function giftMint(address to, uint imageId) external onlyOwner {
        uint tokenId = _mintNewToken(to, imageId);
        _reserveImage(imageId);

        emit TokenBought(_msgSender(), to, tokenId, imageId, 0);
    }

    /// @notice Mint token
    /// @param to Token owner address
    /// @param imageId Image id
    function mint(address to, uint imageId) external payable ifMintAllowed {
        require(msg.value >= _mintPrice, "NeighboursToken: not enough value");
        require(_reserveImage(imageId), "NeighboursToken: this image minting not allowed");

        uint tokenId = _mintNewToken(to, imageId);

        emit TokenBought(_msgSender(), to, tokenId, imageId, msg.value);
    }

    /// @notice Mint unique token
    /// @param to Token owner address
    function mintUnique(address to) external payable ifMintAllowed {
        require(msg.value >= _mintUniquePrice, "NeighboursToken: not enough value");

        _uniqueImageIdCounter.increment();
        uint imageId = _uniqueImageIdCounter.current() + UNIQUE_IMAGE_ID_START;
        uint tokenId = _mintNewToken(to, imageId);

        emit  TokenUniqueBought(_msgSender(), to, tokenId, imageId, msg.value);
    }

    /// @notice Order original painting for token
    /// @param tokenId Token id
    function orderPainting(uint tokenId) external payable ifMintAllowed {
        require(ownerOf(tokenId) == _msgSender(), "NeighboursToken: not owner");
        require(msg.value >= _paintingPrice, "NeighboursToken: not enough value");

        _tokenPaintingOrdered[tokenId] = true;

        emit TokenPaintingOrdered(_msgSender(), tokenId, msg.value);
    }

    /// @notice Get whether the original was ordered for a token
    /// @param tokenId Token id
    /// @return Is the original was ordered for a token
    function tokenPaintingOrdered(uint tokenId) external view returns (bool) {
        return _tokenPaintingOrdered[tokenId];
    }

    /// @notice Internal helper for image reserving
    /// @param imageId Image id
    /// @return Success flag
    function _reserveImage(uint imageId) internal returns (bool) {
        for (uint i = 0; i < _imagesToMintLength; i++) {
            if (_imagesToMint[i] == imageId) {
                _imagesToMint[i] = _imagesToMint[_imagesToMintLength - 1];
                _imagesToMint[_imagesToMintLength - 1] = 0;
                _imagesToMintLength--;
                return true;
            }
        }
        return false;
    }

    /// @notice Set token metadata IPFS CID
    /// @param tokenId Token id
    /// @param metaCID Metadata IPFS CID
    function setTokenMetaCID(uint tokenId, string calldata metaCID) external onlyCOO {
        require(_exists(tokenId), "NeighboursToken: tokenId doesn't exists");
        _tokenCIDs[tokenId] = metaCID;
        emit TokenMetaCIDSet(tokenId, metaCID);
    }

    /// @notice Get token metadata IPFS URI
    /// @param tokenId Token id
    /// @return metadata IPFS URI
    function tokenURI(uint tokenId) public view override returns (string memory) {
        string memory cid = _tokenCIDs[tokenId];
        return string(abi.encodePacked("ipfs://", (bytes(cid).length > 0) ? cid : _defaultMetaCID));
    }

    /// @notice Withdraw ethers from contract
    /// @param amount Amount in WEI
    /// @param to Destination wallet address
    function withdrawEthers(uint amount, address payable to) external onlyOwner {
        to.sendValue(amount);
        emit EthersWithdrawn(_msgSender(), to, amount);
    }
}
