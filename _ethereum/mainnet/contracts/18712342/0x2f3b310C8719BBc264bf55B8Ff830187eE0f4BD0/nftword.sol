// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "./ERC721A.sol";
import "./ERC4907A.sol";
import "./Base64.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./IERC20.sol";

/**
 * @title NFTWord Collection
 * @author https://netword.ai
 */
contract NFTWord is ERC721A, ERC4907A, Ownable, ReentrancyGuard {
    
    // =============================================================
    //                            ERRORS
    // =============================================================

    /**
     * The quantity of tokens minted Exceeds max supply.
     */
    error MintingExceedsMaxSupply();

    /**
     * The token metadata and its URI are frozen and cannot change.
     */
    error MetadataIsFrozen();

    /**
     * Cannot change metadata when freezing is reqeusted.
     */
    error FreezingIsRequested();
    
    /**
     * The airdrop is not performed because the recipient has more tokens than the permitted amount.
     */
    error RecipientNotEligibleForAirdrop();
    
    // =============================================================
    //                            EVENTS
    // =============================================================

    event MetadataUpdate(uint256 _tokenId);
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

    event Airdrop(address indexed _from, address indexed _to, uint256 indexed _Id);

    // The metadata is set to be on-chained and awaits the owner's approval.
    event FrozenRequest(uint256 _tokenId);

    // The freeze operation was rejected because the metadata was not valid.
    event FreezingRejected(uint256 _tokenId);

    // =============================================================
    //                            STRUCTS
    // =============================================================
    struct Metadata {
        uint256 tokenId;
        uint256 word;
        uint256 lang;
        uint256 color;
        uint256 length;
        uint256 extra;
        uint256 opt;
        bool frozen;
        bytes image;
    }

    struct MappedMetadata {
        uint256 packedMetadata;
        bytes imgBody;
    }

    struct TokensOfOwnerStatus {
        uint256 tokenId;
        bool isOnChain;
        bool isFrozen;
        bool frozenRequest;
    }

    struct CollectionMetadata {
        string name;
        string description;
        bytes image;
        string externalLink;
    }

    // =============================================================
    //                          CONSTANTS
    // =============================================================

    uint256 private constant _BITMASK_TOKEN_ID = (1 << 15) - 1;
    uint256 private constant _BITPOS_WORD = 15;
    uint256 private constant _BITMASK_WORD = (1 << 60) - 1;
    uint256 private constant _BITPOS_LANGUAGE = 75;
    uint256 private constant _BITMASK_LANGUAGE = (1 << 60) - 1;
    uint256 private constant _BITPOS_COLOR = 135;
    uint256 private constant _BITMASK_COLOR = (1 << 60) - 1;
    uint256 private constant _BITPOS_LENGTH = 195;
    uint256 private constant _BITMASK_LENGTH = (1 << 4) - 1;
    uint256 private constant _BITPOS_EXTRA = 199;
    uint256 private constant _BITMASK_EXTRA = (1 << 55) - 1;
    uint256 private constant _BITPOS_OPT = 254;
    uint256 private constant _BITPOS_FROZEN = 255;

    // PNG header contains chunk info, image size, color depth, compression method.
    bytes private constant _IMG_HEAD = hex"89504e470d0a1a0a0000000d49484452000003c0000003c0020300000087b8f8080000000c504c5445";
    // PNG EOF (End of file) marker.
    bytes private constant _IMG_EOF = hex"0000000049454e44ae426082";

    // =============================================================
    //                            STORAGE
    // =============================================================

    uint256 public maxSupply;
    uint256 public onChainTokens;
    bool public contractLocked;
    uint256 private _royaltyBasis;
    address private _royaltyReceiver;
    address private _manager;
    string private _currentBaseURI;
    string private _nameOverride;
    string private _symbolOverride;
    
    CollectionMetadata private collectionMetadata;

    // Mapping from token ID to packed metadata.
    //
    // Bits Layout:
    // - [0..14]      `tokenId`         (15 bits, Supports up to number 32767)
    // - [15..74]     `word`            (60 bits, 5 bits per letter, max 12 letters)
    // - [75..134]    `language`        (60 bits, 5 bits per letter, max 12 letters)
    // - [135..194]   `color`           (60 bits, 5 bits per letter, max 12 letters)
    // - [195..198]   `length`          (4 bits, Supports up to number 15)
    // - [199..253]   `extra`           (55 bits, 5 bits per letter, max 11 letters)
    // - [254]        `optimization`    (1 bit, bool, false:40x40, true:48x48)
    // - [255]        `frozen`          (1 bit, bool, false:is not, true:is frozen)
    mapping(uint256 => MappedMetadata) private _mappedMetadatas;

    // Mapping from token ID to freezing request state.
    mapping (uint256 => bool) private _frozenRequest;

    // =============================================================
    //                          CONSTRUCTOR
    // =============================================================

    constructor(
        address initialOwner_,
        uint256 maxSupply_,
        uint256 initialSupply_,
        string memory baseURI_,
        string memory name_,
        string memory description_,
        bytes memory image_,
        string memory externalLink_,
        uint256 royaltyBasis_
    ) Ownable(initialOwner_) ERC721A("NFTWord", "NFTW") {
        _mintERC2309(initialOwner_, initialSupply_);
        maxSupply = maxSupply_;
        _currentBaseURI = baseURI_;
        _manager = initialOwner_;
        _royaltyReceiver = initialOwner_;
        _royaltyBasis = royaltyBasis_;
        collectionMetadata = CollectionMetadata({
            name: name_,
            description: description_,
            image: image_,
            externalLink: externalLink_
        });
    }

    // =============================================================
    //                       CORE OPERATIONS
    // =============================================================   

    function mint(uint256 quantity) external onlyOwner {
        if (totalSupply() + quantity > maxSupply) revert MintingExceedsMaxSupply();
        _mint(msg.sender, quantity);
    }

    /**
     * @notice this function is costly and primarily intended for packing documentation or emergency use cases.
     * @dev Use setMetadata 2-param function directly (gas efficiency).
     * @param word_, lang_, color_ MUST be "english uppercase" and up to "12 characters".
     * @param length_ enter the word length in the original language, not converted to English.
     * @param optimization_ false: Optimized for 40x40 PFPs , true: Optimized for 48x48 PFPs depended to NFT image.
     * @param extra_ Only EN uppercase, up to 11 Chs accepted. if the interface doesn't accept blank, Insert "0" to leave it blank.
     * @param imageBody_ convert image file to hex and remove header and EOF.
     */
    function setMetadata(
        uint256 tokenId_,
        string memory word_,
        string memory lang_,
        string memory color_,
        uint256 length_,
        string memory extra_,
        bool optimization_,
        bytes memory imageBody_
    ) external {
        // After submitting a request, Cannot submit a new request until it's rejected.
        if (frozenRequest(tokenId_)) revert FreezingIsRequested();

        Metadata memory metadata;
            metadata.tokenId = tokenId_;
            metadata.word = _toUint(word_);
            metadata.lang = _toUint(lang_);
            metadata.color = _toUint(color_);
            metadata.length = length_;
            metadata.extra = equal(extra_, "0") ? _toUint("") : _toUint(extra_); 
            metadata.opt =  optimization_ ? 1 : 0;
            metadata.image = imageBody_;

        // Pack metadata into a single uint256
        uint256 _packedMetadata = 0;
        _packedMetadata |= 
        (metadata.tokenId & _BITMASK_TOKEN_ID) |
        (metadata.word & _BITMASK_WORD) << _BITPOS_WORD |
        (metadata.lang & _BITMASK_LANGUAGE) << _BITPOS_LANGUAGE |
        (metadata.color & _BITMASK_COLOR) << _BITPOS_COLOR |
        (metadata.length & _BITMASK_LENGTH) << _BITPOS_LENGTH |
        (metadata.extra & _BITMASK_EXTRA) << _BITPOS_EXTRA |
        (metadata.opt & 1) << _BITPOS_OPT;

        // Mapping on-chain metadata.
        _mappedMetadatas[metadata.tokenId] = MappedMetadata(_packedMetadata, metadata.image);

        // Ensuring that metadata will not change during reviewing.
        _frozenRequest[metadata.tokenId] = true;

        // Signal to dApp.
        emit FrozenRequest(metadata.tokenId);
    }

    /**
     * In order to utilize this function, you must insert packedMetadata and image body raw bytes.
     */
    function setMetadata(uint256 packedMetadata, bytes memory imgBody) external {
        uint256 tokenId = packedMetadata & _BITMASK_TOKEN_ID;
        if (frozenRequest(tokenId)) revert FreezingIsRequested();
        packedMetadata = packedMetadata & ~(1 << _BITPOS_FROZEN); // Ensuring freezing is not initialized.
        _mappedMetadatas[tokenId] = MappedMetadata(packedMetadata, imgBody);
        _frozenRequest[tokenId] = true;
        emit FrozenRequest(tokenId);
    }

    // This function exposes the packed metadata to a structured raw version.
    function unpackMetadata(uint256 _PACK_DATA, bytes memory _IMG_BODY) internal pure returns (Metadata memory) {
        Metadata memory metadata;
            metadata.tokenId = _PACK_DATA & _BITMASK_TOKEN_ID;
            metadata.word = (_PACK_DATA >> _BITPOS_WORD) & _BITMASK_WORD;
            metadata.lang = (_PACK_DATA >> _BITPOS_LANGUAGE) & _BITMASK_LANGUAGE;
            metadata.color = (_PACK_DATA >> _BITPOS_COLOR) & _BITMASK_COLOR;
            metadata.length = (_PACK_DATA >> _BITPOS_LENGTH) & _BITMASK_LENGTH;
            metadata.extra = (_PACK_DATA >> _BITPOS_EXTRA) & _BITMASK_EXTRA;
            metadata.opt = (_PACK_DATA >> _BITPOS_OPT) & 1;
            metadata.frozen = ((_PACK_DATA >> _BITPOS_FROZEN) & 1) == 1;
            metadata.image = concat(_IMG_HEAD, _IMG_BODY, _IMG_EOF);

        return metadata;
    }

    // Approve on-chaining request. This function will freeze on-chain metadata and will make it public.
    function onChain(uint256 tokenId) external onlyManager(tokenId) {
        if (isMetadataFrozen(tokenId)) revert MetadataIsFrozen();
        require(frozenRequest(tokenId));
        _mappedMetadatas[tokenId].packedMetadata = _mappedMetadatas[tokenId].packedMetadata | (1 << _BITPOS_FROZEN);
        onChainTokens++;
        emit MetadataUpdate(tokenId);
    }

    /**
     * This function will reject the freezing request to let submitting metadata again.
     * The manager cannot reject the frozenRequest after freezing metadata because,
     * it works like isMetadataFrozen() in setMetadata functions.
     */
    function rejectOnChain(uint256 tokenId) external onlyManager(tokenId) {
        if (isMetadataFrozen(tokenId)) revert MetadataIsFrozen();
        _frozenRequest[tokenId] = false;
        emit FreezingRejected(tokenId);
    }

    // Owners of tokens have the capability to airdrop a token they own. It Ensure recipient does not hold tokens
    // exceeding defined limit, And an airdrop event also indexed to make it searchable.
    function airdrop(address to, uint256 tokenId, uint256 maxBalance) external {
        if(balanceOf(to) > maxBalance) revert RecipientNotEligibleForAirdrop();
        safeTransferFrom(_msgSender(), to, tokenId, "");
        emit Airdrop(_msgSender(), to, tokenId);
    }

    function setCollectionMetadata(
        string memory _collectionName,
        string memory _description,
        bytes memory _image,
        string memory _external_link,
        string memory _overrideName,
        string memory _overrideSymbol,
        uint256 _maxSupply,
        bool _lockContract
    ) external onlyOwner {
        require(!contractLocked);
        
        collectionMetadata.name = _collectionName;
        collectionMetadata.description = _description;
        collectionMetadata.image = _image;
        collectionMetadata.externalLink = _external_link;
        _nameOverride = _overrideName;
        _symbolOverride = _overrideSymbol;

        // Max supply cannot be greater than the current max, but can be reduced up to the total supply.
        if (_maxSupply > maxSupply || _maxSupply < totalSupply()) revert();
        maxSupply = _maxSupply;
        contractLocked = _lockContract;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        require(!contractLocked);
        _currentBaseURI = baseURI;
    }

    function refreshCollection() external onlyOwner {
        emit BatchMetadataUpdate(1, type(uint256).max);
    }

    function setDefaultRoyalty(address royaltyReceiver, uint256 royaltyBasis) external onlyOwner {
        _royaltyReceiver = royaltyReceiver;
        _royaltyBasis = royaltyBasis;
    }

    function withdrawETH() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Unable to transfer.");
    }

    function withdrawERC20(address tokenAddress, uint256 amount) external onlyOwner nonReentrant {
        IERC20 token = IERC20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        require(balance >= amount);
        token.transfer(owner(), amount);
    }

    /**
     * @dev Throws if the sender is not the manager.
     * @notice If the owner leaves the contract without a manager(address(0)),
     * the token's owner becomes the manager of its token (to freeze metadata).
     */
    modifier onlyManager(uint256 tokenId) {
        if (_manager != address(0)) {
            require(_manager == msg.sender);
        } else {
            require(ownerOf(tokenId) == msg.sender);
        }
        _;
    }

    function setManager(address newManager) external onlyOwner {
        _manager = newManager;
    }

    // =============================================================
    //                              VIEWS
    // ============================================================= 

    // Returns conditional URI depending on whether the token is off-chain or 
    // frozen on-chain (unfrozen on-chain tokens are considered off-chain URI).
    function tokenURI(uint256 tokenId) public view override(ERC721A, IERC721A) returns (string memory) {
        if (isMetadataFrozen(tokenId)) {
            Metadata memory metadata = _getMetadata(tokenId);
            return onChainURI(metadata);
        }
        return super.tokenURI(tokenId);
    }

    // Returns conditional URI depending on whether the token is off-chain or on-chain.
    // This function can return preview of a unfrozen on-chain token.
    function previewURI(uint256 tokenId) public view returns (string memory) {
        if (isMetadataOnChain(tokenId)) {
            Metadata memory metadata = _getMetadata(tokenId);
            return onChainURI(metadata);
        }
        return super.tokenURI(tokenId);
    }

    // Generate URI for contract level metadata.
    function contractURI() external view returns (string memory) {
        string memory json = string(
            abi.encodePacked(
                '{"name": "', collectionMetadata.name,
                '", "description": "', collectionMetadata.description,
                '", "image": "data:image/png;base64,', Base64.encode(collectionMetadata.image),
                '", "external_link": "', collectionMetadata.externalLink, '"}'
            )
        );
        return string(abi.encodePacked("data:application/json;utf8,", json));
    }
    
    // Get structured metadata of an existing token.
    function _getMetadata(uint256 tokenId) internal view returns (Metadata memory) {
        uint256 _packedMetadata = _mappedMetadatas[tokenId].packedMetadata;
        bytes memory _imgBody = _mappedMetadatas[tokenId].imgBody;
        Metadata memory metadata = unpackMetadata(_packedMetadata, _imgBody);
        return (metadata);
    }

    // Generate URI for On-Chain tokens.
    function onChainURI(Metadata memory metadata) internal pure returns (string memory) {
        return string(
            abi.encodePacked(
                '{"image": "data:image/png;base64,', Base64.encode(metadata.image),
                '", "attributes": [',
                '{"trait_type": "Color", "value": "', _toWord(metadata.color), '"}, ',
                '{"trait_type": "Language", "value": "', _toWord(metadata.lang), '"}, ',
                '{"trait_type": "Length", "value": ', _toString(metadata.length), '}, ',
                '{"trait_type": "Optimization", "value": "', metadata.opt == 0 ? "40X40 PFP" : "48X48 PFP", '"}, ',
                '{"trait_type": "Word", "value": "', _toWord(metadata.word), '"}, ',
                '{"trait_type": "Metadata", "value": "', metadata.frozen ? "FROZEN " : "", 'ON-CHAIN"}',
                metadata.extra != 0 ? string(abi.encodePacked(', {"value": "', _toWord(metadata.extra), '"}')) : "",
                ']}'
            )
        );
    }

    // Check if a given tokenId has on-chain metadata.
    function isMetadataOnChain(uint256 tokenId) public view returns (bool) {
        return _mappedMetadatas[tokenId].packedMetadata != 0;
    }

    // Check if the on-chain metadata for a given tokenId is frozen.
    function isMetadataFrozen(uint256 tokenId) public view returns (bool) {
        return (_mappedMetadatas[tokenId].packedMetadata >> _BITPOS_FROZEN) & 1 == 1;
    }

    function frozenRequest(uint256 tokenId) public view returns (bool){
        return _frozenRequest[tokenId];
    }

    function balanceOfERC20(address tokenAddress) external view returns (uint256) {
        IERC20 token = IERC20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        return balance;
    }
    
    function getRawMetadata(uint256 tokenId) external view returns (uint256, bytes memory) {
        MappedMetadata memory mappedMetadata = _mappedMetadatas[tokenId];
        return (mappedMetadata.packedMetadata, mappedMetadata.imgBody);
    }

    /**
     * @dev Returns an array of token IDs owned by `owner`.
     *
     * This function scans the ownership mapping and is O(`totalSupply`) in complexity.
     * It is meant to be called off-chain.
     */
    function tokensOfOwner(address owner) public view returns (uint256[] memory) {
        unchecked {
            uint256 tokenIdsIdx;
            address currOwnershipAddr;
            uint256 tokenIdsLength = balanceOf(owner);
            uint256[] memory tokenIds = new uint256[](tokenIdsLength);
            TokenOwnership memory ownership;
            for (uint256 i = _startTokenId(); tokenIdsIdx != tokenIdsLength; ++i) {
                ownership = _ownershipAt(i);
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            return tokenIds;
        }
    }

    /**
     * @dev It returns up to 100 items per page of the metadata status for each token owned by the address.
     *
     * Return possibilities:
     * [tokenId,false,false,false]      Token metadata is off-chain.
     * [tokenId,true,false,true]        On-chain metadata has been submitted but not approved yet.
     * [tokenId,true,false,false]       Submitted on-chain metadata rejected.
     * [tokenId,true,true,true]         The token is fully on-chain, and metadata is frozen.
     */
    function tokensOfOwnerStatus(address owner, uint256 page) external view returns (TokensOfOwnerStatus[] memory) {
        uint256[] memory tokens = tokensOfOwner(owner);
        uint256 perPage = 100;
        uint256 startIdx = page * perPage;
        uint256 endIdx = startIdx + perPage > tokens.length ? tokens.length : startIdx + perPage;

        TokensOfOwnerStatus[] memory result = new TokensOfOwnerStatus[](endIdx - startIdx);

        for (uint i = startIdx; i < endIdx; i++) {
            result[i - startIdx] = TokensOfOwnerStatus({
                tokenId: tokens[i],
                isOnChain: isMetadataOnChain(tokens[i]),
                isFrozen: isMetadataFrozen(tokens[i]),
                frozenRequest: frozenRequest(tokens[i])
            });
        }

        return result;
    }

    //ERC-4906 Interface adds a MetadataUpdate event to EIP-721 tokens.
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC4907A, ERC721A) returns (bool) {
        return interfaceId == 0x49064906 || super.supportsInterface(interfaceId);
    }

    // ERC-2981 NFT Royalty Standard.
    function royaltyInfo(uint256 /* _tokenId */, uint256 _salePrice) public view returns (address receiver, uint256 royaltyAmount) {
        royaltyAmount = (_salePrice * _royaltyBasis) / 10000;
        return (_royaltyReceiver, royaltyAmount);
    }

    function manager() public view returns (address) {
        return _manager;
    }

    function name() public view override(ERC721A, IERC721A) returns (string memory) {
        if (bytes(_nameOverride).length == 0) {
            return ERC721A.name();
        }
        return _nameOverride;
    }

    function symbol() public view override(ERC721A, IERC721A) returns (string memory) {
        if (bytes(_symbolOverride).length == 0) {
            return ERC721A.symbol();
        }
        return _symbolOverride;
    }

    // =============================================================
    //                       OTHER OPERATIONS
    // =============================================================    

    /**
     * The function treats each character in the string as a base-32 (5-bit)
     * integer and packs them together into a uint256. Only works for english uppercase letters.
     *
     * Example:
     * - If the string is "HI", the function will treat 'H' and 'I' as
     *   base-32 integers and pack them into a uint256.
     */
    function _toUint(string memory str) internal pure returns (uint256) {
        bytes memory strBytes = bytes(str);
        uint256 result = 0;
        for (uint256 i = 0; i < strBytes.length; i++) {
            result = (result << 5) | (uint8(strBytes[i]) - 64);
        }
        return result;
    }

    /**
     * The function unpacks the 5-bit chunks of the uint256 and converts them
     * to their ASCII character representation.
     */
    function _toWord(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        bytes memory buffer = new bytes(64);
        uint256 index;
        while (value > 0) {
            uint8 charValue = uint8((value & 31) + 64);
            buffer[63 - index] = bytes1(charValue);
            value >>= 5;
            index++;
        }
        
        bytes memory resultBytes = new bytes(index);
        for (uint256 i = 0; i < index; i++) {
            resultBytes[i] = buffer[63 - index + i + 1];
        }
        return string(resultBytes);
    }

    function equal(string memory a, string memory b) internal pure returns (bool) {
        return bytes(a).length == bytes(b).length && keccak256(bytes(a)) == keccak256(bytes(b));
    }

    function concat(bytes memory a, bytes memory b, bytes memory c) internal pure returns (bytes memory d) {
        d = new bytes(a.length + b.length + c.length);
        uint k = 0;
        for (uint i = 0; i<a.length; i++) d[k++] = a[i];
        for (uint i = 0; i<b.length; i++) d[k++] = b[i];
        for (uint i = 0; i<c.length; i++) d[k++] = c[i];
        return d;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view override returns (string memory) {
        return _currentBaseURI;
    }

}