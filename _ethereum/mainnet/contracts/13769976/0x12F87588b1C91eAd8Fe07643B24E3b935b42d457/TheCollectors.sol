// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./Ownable.sol";
import "./ERC721.sol";
import "./IERC1155.sol";
import "./ReentrancyGuard.sol";

interface IPunk {
    function punkIndexToAddress(uint256 index) external view returns (address);
}

contract TheCollectors is ERC721, Ownable, ReentrancyGuard {

    struct EmbedInfo {
        address collection;
        uint256 tokenId;
    }

    uint256 public constant MAX_SUPPLY = 10000;
    IPunk public constant PUNK = IPunk(0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB);

    mapping(address => IERC721) public erc721WhitelistedCollections;
    mapping(address => IERC1155) public erc1155WhitelistedCollections;
    mapping(uint256 => EmbedInfo) public embeddedTokensInfo;
    mapping(address => mapping(uint256 => bool)) public embeddedTokens;
    uint256 public endWhitelistMintingPeriodDateAndTime;
    address public signerPublicAddress;
    uint256 public totalSupply;
    bool public forceEndMinting;
    uint256 public maxMintsPerWhitelistedAddress;
    uint256 public maxMintsPerAddress;
    uint256 public mintFee;

    string private _baseTokenURI;
    mapping(uint256 => string) private _tokenURIs;

    event EmbedTokens(uint256 indexed theCollectorTokenId, address indexed embeddedCollection, uint256 indexed embeddedTokenId);

    // -------------------- Modifiers --------------------

    modifier onlyInMintingPeriod {
        require(!mintingOver(), "Minting over");
        _;
    }

    modifier includesMintFee(uint256 amountToMint) {
        require(msg.value >= mintFee * amountToMint, "<mint cost");
        _;
    }

    // -------------------- Constructor --------------------

    constructor(
        address _signerPublicAddress,
        uint256 _endWhitelistMintingPeriodDateAndTime,
        string memory __baseTokenURI
    ) ERC721("The Collectors", "TheCollectors") {
        signerPublicAddress = _signerPublicAddress;
        endWhitelistMintingPeriodDateAndTime = _endWhitelistMintingPeriodDateAndTime;
        _baseTokenURI = __baseTokenURI;
        maxMintsPerWhitelistedAddress = 10;
        maxMintsPerAddress = 10;
        mintFee = 0.08 ether;
    }

    // -------------------- Management --------------------

    function addERC721WhitelistedCollections(address[] memory whitelistedCollectionsArray) external onlyOwner {
        for (uint256 i; i < whitelistedCollectionsArray.length; i++) {
            erc721WhitelistedCollections[whitelistedCollectionsArray[i]] = IERC721(whitelistedCollectionsArray[i]);
        }
    }

    function addERC1155WhitelistedCollections(address[] memory whitelistedCollectionsArray) external onlyOwner {
        for (uint256 i; i < whitelistedCollectionsArray.length; i++) {
            erc1155WhitelistedCollections[whitelistedCollectionsArray[i]] = IERC1155(whitelistedCollectionsArray[i]);
        }
    }

    function removeERC721WhitelistedCollection(address whitelistedCollection) external onlyOwner {
        delete erc721WhitelistedCollections[whitelistedCollection];
    }

    function removeERC1155WhitelistedCollection(address whitelistedCollection) external onlyOwner {
        delete erc1155WhitelistedCollections[whitelistedCollection];
    }

    function setMaxMintsPerWhitelistedAddress(uint256 _maxMintsPerWhitelistedAddress) external onlyOwner {
        maxMintsPerWhitelistedAddress = _maxMintsPerWhitelistedAddress;
    }

    function setMaxMintsPerAddress(uint256 _maxMintsPerAddress) external onlyOwner {
        maxMintsPerAddress = _maxMintsPerAddress;
    }

    function setForceEndMinting(bool _forceEndMinting) external onlyOwner {
        forceEndMinting = _forceEndMinting;
    }

    function setSignerPublicAddress(address _signerPublicAddress) external onlyOwner {
        signerPublicAddress = _signerPublicAddress;
    }

    function setEndWhitelistMintingPeriodDateAndTime(uint256 _endWhitelistMintingPeriodDateAndTime) external onlyOwner {
        endWhitelistMintingPeriodDateAndTime = _endWhitelistMintingPeriodDateAndTime;
    }

    function setBaseTokenURI(string memory __baseTokenURI) external onlyOwner {
        _baseTokenURI = __baseTokenURI;
    }

    function setMintFee(uint256 _mintFee) external onlyOwner {
        mintFee = _mintFee;
    }

    // -------------------- Mints --------------------

    function mintTokenForWhitelistedAddresses(address whitelistAddress, uint8 v, bytes32 r, bytes32 s, uint256 amountToMint)
    external
    payable
    nonReentrant
    onlyInMintingPeriod
    includesMintFee(amountToMint)
    {
        require(endWhitelistMintingPeriodDateAndTime > block.timestamp, "Can't mint");
        require(_validateSignature(keccak256(abi.encodePacked(whitelistAddress)), v, r, s) && whitelistAddress == msg.sender, "Nice try");
        require(maxMintsPerWhitelistedAddress >= amountToMint, ">max");
        uint256 i;
        // Since i can be lower than amountToMint after loop ends
        for (
        ;
            i < amountToMint
            && MAX_SUPPLY > totalSupply;
            i++
        ) {
            _mintNextToken(msg.sender);
        }
        uint256 mintingFee = i * mintFee;
        Address.sendValue(payable(owner()), mintingFee);
        if (msg.value - mintingFee > 0) {
            Address.sendValue(payable(msg.sender), msg.value - mintingFee);
        }
    }

    function mintToken(uint256 amountToMint)
    external
    payable
    nonReentrant
    onlyInMintingPeriod
    includesMintFee(amountToMint)
    {
        require(block.timestamp > endWhitelistMintingPeriodDateAndTime, "Only whitelist");
        require(maxMintsPerAddress >= amountToMint, ">max");
        uint256 i;
        // Since i can be lower than amountToMint after loop ends
        for (
        ;
            i < amountToMint
            && MAX_SUPPLY > totalSupply;
            i++
        ) {
            _mintNextToken(msg.sender);
        }
        uint256 mintingFee = i * mintFee;
        Address.sendValue(payable(owner()), mintingFee);
        if (msg.value - mintingFee > 0) {
            Address.sendValue(payable(msg.sender), msg.value - mintingFee);
        }
    }

    function embedToken(
        uint256 theCollectorsTokenId,
        address whitelistCollection,
        uint256 whitelistCollectionTokenId,
        string memory uri,
        string memory typeOfSignature,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
    external
    {
        require(_validateSignature(keccak256(abi.encodePacked(uri, typeOfSignature)), v, r, s), "Really?");
        require(bytes(_tokenURIs[theCollectorsTokenId]).length == 0, "Already embedded");
        require(ownerOf(theCollectorsTokenId) == msg.sender, "Not token owner");
        require(
            address(erc721WhitelistedCollections[whitelistCollection]) != address(0) ||
            address(erc1155WhitelistedCollections[whitelistCollection]) != address(0) ||
            whitelistCollection == address(PUNK),
            "Bad collection"
        );
        require(
            (whitelistCollection == address(PUNK) && PUNK.punkIndexToAddress(whitelistCollectionTokenId) == msg.sender) ||
            (address(erc1155WhitelistedCollections[whitelistCollection]) != address(0) && erc1155WhitelistedCollections[whitelistCollection].balanceOf(msg.sender, whitelistCollectionTokenId) > 0) ||
            erc721WhitelistedCollections[whitelistCollection].ownerOf(whitelistCollectionTokenId) == msg.sender,
            "Bad token owner"
        );
        require(!wasTokenUsed(whitelistCollection, whitelistCollectionTokenId), "Already used");
        embeddedTokensInfo[theCollectorsTokenId] = EmbedInfo(whitelistCollection, whitelistCollectionTokenId);
        embeddedTokens[whitelistCollection][whitelistCollectionTokenId] = true;
        _tokenURIs[theCollectorsTokenId] = uri;
        emit EmbedTokens(theCollectorsTokenId, whitelistCollection, whitelistCollectionTokenId);
    }

    // -------------------- Views --------------------

    function wasTokenUsed(address collection, uint256 token) public view returns (bool) {
        return embeddedTokens[collection][token];
    }

    function mintingOver() public view returns (bool) {
        return totalSupply == MAX_SUPPLY || forceEndMinting;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            return _tokenURIs[tokenId];
        } else {
            string memory uri = super.tokenURI(tokenId);
            return string(abi.encodePacked(uri, ".json"));
        }

    }

    // -------------------- Internal --------------------

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function _mintNextToken(address to) internal {
        _safeMint(to, totalSupply);
        totalSupply++;
    }

    function _validateSignature(bytes32 hashOfText, uint8 v, bytes32 r, bytes32 s) internal view returns (bool) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 hashOfSignature = keccak256(abi.encodePacked(prefix, hashOfText));
        return ecrecover(hashOfSignature, v, r, s) == signerPublicAddress;
    }
}
