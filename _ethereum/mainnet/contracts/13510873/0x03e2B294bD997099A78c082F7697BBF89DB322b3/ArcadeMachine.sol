//SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./DisplayURISwitchable.sol";
import "./ERC2981.sol";
import "./Arcade.sol";

contract ArcadeMachine is DisplayURISwitchable, ERC721Enumerable, ReentrancyGuard, ERC2981, Ownable {
    struct TokenInfo {
        string imageMetadataURI;
        uint256 arcadeTokenId;
        bool freezeImageMetadata;
    }

    /**
     * @dev Emitted when image metadata of `tokenId` is changed by `from` user.
     */
    event ImageMetadataChanged(address indexed from, uint256 indexed tokenId);

    Arcade public arcade;
    uint256 public totalExtension = 0;
    uint256 public totalOriginal = 0;
    uint8 public ROYALTY_PCT = 0;
    bool public freezeRoyaltyPct = false;
    uint256 private MAX_ARCADE_SUPPLY = 0;

    mapping(uint256 => TokenInfo) private _tokenInfos;

    constructor(address arcadeOfficialAddress) ERC721("ArcadeMachine", "ARCADE-MACHINE") {
        arcade = Arcade(arcadeOfficialAddress);
        MAX_ARCADE_SUPPLY = arcade.MAX_PUBLIC() + arcade.MAX_RESERVED();
    }

    modifier onlyTokenOwner(uint256 tokenId) {
        require(_isTokenOwner(tokenId), "You must be the token owner.");
        _;
    }

    modifier onlyOperator() {
        require(_isOperator(), "You must be the Arcade operator.");
        _;
    }

    modifier onlyArcadeOwner(uint256 tokenId) {
        require(
            arcade.ownerOf(tokenId) == msg.sender,
            "You must own the corresponding Arcade to mint this."
        );
        _;
    }

    modifier lessThanArcadeSupply(uint256 tokenId) {
        require(isOriginal(tokenId), "Invalid Arcade ID.");
        _;
    }

    function mintOriginal(
        uint256 arcadeTokenId,
        string memory imageMetadataURI,
        bool mode
    )
        public
        lessThanArcadeSupply(arcadeTokenId)
        onlyArcadeOwner(arcadeTokenId)
        nonReentrant
        returns (uint256 tokenId)
    {
        require(_hasLength(imageMetadataURI), "Need an image metadata URI.");

        _tokenInfos[arcadeTokenId] = TokenInfo(
            imageMetadataURI,
            arcadeTokenId,
            false
        );

        _safeMint(msg.sender, arcadeTokenId);
        tokenId = arcadeTokenId;
        _setDisplayMode(tokenId, mode);
        totalOriginal += 1;
    }

    function mintExtension(
        uint256 arcadeTokenId,
        string memory imageMetadataURI,
        bool mode
    )
        public
        lessThanArcadeSupply(arcadeTokenId)
        nonReentrant
        returns (uint256 tokenId)
    {
        require(_hasLength(imageMetadataURI), "Need an image metadata URI.");

        tokenId = MAX_ARCADE_SUPPLY + totalExtension + 1;
        _tokenInfos[tokenId] = TokenInfo(
            imageMetadataURI,
            arcadeTokenId,
            false
        );

        _safeMint(msg.sender, tokenId);
        _setDisplayMode(tokenId, mode);
        _setReceiver(tokenId, arcade.ownerOf(arcadeTokenId));
        _setRoyaltyPercentage(tokenId, ROYALTY_PCT);
        totalExtension += 1;
    }

    function devMintOriginal(
        address[] calldata targets,
        uint256[][] calldata arcadeTokenIds,
        string[][] calldata metadataURIs,
        bool[][] calldata modes
    )
        external
        onlyOperator
    {
        require(
            targets.length == arcadeTokenIds.length
            && targets.length == metadataURIs.length
            && targets.length == modes.length
            && targets.length > 0,
            "Input arrays must have the same length."
        );

        for(uint256 i = 0; i < targets.length; i++) {
            _devMintOriginal(targets[i], arcadeTokenIds[i], metadataURIs[i], modes[i]);
        }
    }

    function devMintExtension(
        address[] calldata targets,
        uint256[][] calldata arcadeTokenIds,
        string[][] calldata metadataURIs,
        bool[][] calldata modes
    )
        external
        onlyOperator
    {
        require(
            targets.length == arcadeTokenIds.length
            && targets.length == metadataURIs.length
            && targets.length == modes.length
            && targets.length > 0,
            "Input arrays must have the same length."
        );

        for(uint256 i = 0; i < targets.length; i++) {
            _devMintExtension(targets[i], arcadeTokenIds[i], metadataURIs[i], modes[i]);
        }
    }

    function setGlobalRoyaltyPercent(uint8 percent) public onlyOwner {
        require(!freezeRoyaltyPct, "It is frozen.");
        require(percent >= 0 && percent <= 100, "Percent must be between 0 - 100.");
        ROYALTY_PCT = percent;
    }

    function freezeRoyaltyPercent() public onlyOwner {
        freezeRoyaltyPct = true;
    }

    function setImageMetadataURI(
        uint256 tokenId,
        string memory metadataURI
    )
        public
    {
        require(_hasLength(metadataURI), "Need an image metadata URI.");
        require(
            _isTokenOwner(tokenId) || _isOperator(),
            "You must be the token owner or the Arcade operator."
        );

        TokenInfo storage info = _getTokenInfo(tokenId);
        require(!info.freezeImageMetadata, "It is frozen.");

        info.imageMetadataURI = metadataURI;

        emit ImageMetadataChanged(msg.sender, tokenId);
    }

    function freezeImageMetadata(uint256 tokenId)
        public
        onlyTokenOwner(tokenId)
    {
        TokenInfo storage info = _getTokenInfo(tokenId);
        info.freezeImageMetadata = true;
    }

    function setDisplayMode(uint256 tokenId, bool mode)
        public
        override
        onlyTokenOwner(tokenId)
    {
        _setDisplayMode(tokenId, mode);
    }

    function isFrozenImageMetadata(uint256 tokenId) public view returns (bool) {
        TokenInfo storage info = _getTokenInfo(tokenId);
        return info.freezeImageMetadata;
    }

    function getArcadeTokenId(uint256 tokenId) public view returns (uint256) {
        TokenInfo storage info = _getTokenInfo(tokenId);
        return info.arcadeTokenId;
    }

    function isOriginal(uint256 tokenId) public view returns (bool) {
        return tokenId <= MAX_ARCADE_SUPPLY && tokenId > 0;
    }

    function setDisplayBaseURI(string memory baseURI)
        public
        onlyOperator
    {
        _setDisplayBaseURI(baseURI);
    }

    function originalTokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        TokenInfo storage info = _getTokenInfo(tokenId);
        return info.imageMetadataURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(DisplayURISwitchable, ERC721)
        returns (string memory)
    {
        require(tokenId > 0, "Token ID cannot be 0.");
        require(tokenId <= MAX_ARCADE_SUPPLY + totalExtension);

        return DisplayURISwitchable.tokenURI(tokenId);
    }

    function _devMintOriginal(
        address targetAddress,
        uint256[] calldata arcadeTokenIds,
        string[] calldata imageMetadataURIs,
        bool[] calldata modes
    )
        private
    {
        require(targetAddress != address(0), "Can't mint to the null address.");
        require(
            arcadeTokenIds.length == modes.length
            && arcadeTokenIds.length == imageMetadataURIs.length
            && arcadeTokenIds.length > 0,
            "Input arrays must have the same length."
        );

        for(uint256 i = 0; i < arcadeTokenIds.length; i++) {
            uint256 tokenId = arcadeTokenIds[i];
            require(
                tokenId >= arcade.STARTING_RESERVED_ID() && tokenId < arcade.STARTING_RESERVED_ID() + arcade.MAX_RESERVED(),
                "Arcade ID must be in the reserve range."
            );
            require(
                arcade.ownerOf(tokenId) == targetAddress,
                "Target address must be the Arcade ID owner."
            );

            _devMint(targetAddress, tokenId, tokenId, imageMetadataURIs[i], modes[i]);
        }

        totalOriginal += arcadeTokenIds.length;
    }

    function _devMintExtension(
        address targetAddress,
        uint256[] calldata arcadeTokenIds,
        string[] calldata imageMetadataURIs,
        bool[] calldata modes
    )
        private
    {
        require(targetAddress != address(0), "Can't mint to the null address.");
        require(
            arcadeTokenIds.length == modes.length
            && arcadeTokenIds.length == imageMetadataURIs.length
            && arcadeTokenIds.length > 0,
            "Input arrays must have the same length."
        );

        for(uint256 i = 0; i < arcadeTokenIds.length; i++) {
            uint256 tokenId = MAX_ARCADE_SUPPLY + totalExtension + i + 1;
            uint256 arcadeTokenId = arcadeTokenIds[i];
            _devMint(targetAddress, tokenId, arcadeTokenId, imageMetadataURIs[i], modes[i]);
            _setReceiver(tokenId, arcade.ownerOf(arcadeTokenId));
            _setRoyaltyPercentage(tokenId, ROYALTY_PCT);
        }

        totalExtension += arcadeTokenIds.length;
    }

    function _devMint(
        address targetAddress,
        uint256 tokenId,
        uint256 arcadeTokenId,
        string memory imageMetadataURI,
        bool mode
    )
        private
    {
        require(_hasLength(imageMetadataURI), "All images metadata URIs are required.");

        _tokenInfos[tokenId] = TokenInfo(
            imageMetadataURI,
            arcadeTokenId,
            false
        );

        _setDisplayMode(tokenId, mode);
        _safeMint(targetAddress, tokenId);
    }

    function _isOperator() private view returns (bool) {
        return arcade.hasRole(arcade.OPERATOR_ROLE(), msg.sender);
    }

    function _isTokenOwner(uint256 tokenId) private view returns (bool) {
        require(tokenId > 0);

        return ownerOf(tokenId) == msg.sender;
    }

    function _getTokenInfo(uint256 tokenId) private view returns (TokenInfo storage) {
        TokenInfo storage info = _tokenInfos[tokenId];
        require(info.arcadeTokenId > 0);

        return info;
    }
}
