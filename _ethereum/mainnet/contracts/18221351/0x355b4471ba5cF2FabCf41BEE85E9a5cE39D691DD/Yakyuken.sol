// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Base64.sol";
import "./Strings.sol";

import "./ERC721B.sol";
import "./ZLib.sol";

contract Yakyuken is ERC721B, ERC721URIStorage, Ownable {
    using Strings for uint256;

    bytes32 private constant METADATA_POINTER = bytes32(keccak256("metadata"));

    uint16 private constant MEMORY_OFFSET = 100;

    address private immutable _zlib;

    uint128[] private _imageMetadata;
    uint128[] private _iconMetadata;
    bytes7[] private _imageTraits;
    bytes7 private _sampleImageTraits;

    bool[4] private _initialized;
    address private _saleContract;

    struct Image {
        string path;
        string viewBox;
        string fontSize;
        string iconSize;
        string name;
    }

    ///@dev must be in alphabetical order
    struct Icon {
        string color;
        string name;
        string path;
    }

    struct MetadataBytes {
        uint8 glowTimes;
        uint8 backgroundColors;
        uint8 yakHoverColors;
        uint8 finalShadowColors;
        uint8 baseFillColors;
        uint8 yakFillColors;
        uint8 yak;
        uint8 initialShadowColors;
        uint8 initialShadowBrightness;
        uint8 finalShadowBrightness;
        uint8 icon;
        uint8 texts;
    }

    ///@dev  must be in alphabetical order
    struct Metadata {
        string[] backgroundColors;
        string[] baseFillColors;
        string[] finalShadowBrightness;
        string[] finalShadowColors;
        string[] glowTimes;
        string[] initialShadowBrightness;
        string[] initialShadowColors;
        string[] texts;
        string[] yakFillColors;
        string[] yakHoverColors;
    }

    error OutOfBondsTraitValueError();
    error AlreadyInitializedError();
    error NotSaleContractError();

    modifier initialize(uint256 id_) {
        _initialize(id_);
        _;
    }

    modifier onlySale() {
        if (msg.sender != _saleContract) revert NotSaleContractError();
        _;
    }

    constructor(address zlib_) ERC721("Yakyuken", "YNFT") Ownable(msg.sender) {
        _zlib = zlib_;

        for (uint256 i = 0; i < 25; i++) {
            _mint(msg.sender, i);
        }
    }

    ///@dev  must be the first initialize to be called
    function initializeMetadata(bytes calldata metadata_, bytes7 sampleImageTraits_)
        external
        onlyOwner
        initialize(0)
    {
        _write(METADATA_POINTER, metadata_);
        _sampleImageTraits = sampleImageTraits_;
    }

    ///@dev  must be called after initializeMetadata().
    function initializeImages(bytes[] calldata images_, uint128[] calldata decompressedSizes_)
        external
        onlyOwner
        initialize(1)
    {
        uint256 imageCount_ = images_.length;
        for (uint256 i_; i_ < imageCount_; i_++) {
            _write(bytes32(keccak256(abi.encode(i_))), images_[i_]);
            _imageMetadata.push(decompressedSizes_[i_]);
        }
    }

    ///@dev  must be called after initializeImages().
    function initializeImagesHardcoded(
        bytes[] calldata images_,
        uint128[] calldata decompressedSizes_,
        uint256 totalImages_
    ) external onlyOwner initialize(2) {
        uint256 imageCount_ = totalImages_ - images_.length;
        for (uint256 i_; i_ < images_.length; i_++) {
            _write(bytes32(keccak256(abi.encode(i_ + imageCount_))), images_[i_]);
            _imageMetadata.push(decompressedSizes_[i_]);
        }
    }

    ///@dev  must be called after initializeImagesHardcoded()
    function initializeIcons(bytes[] calldata icons_, uint128[] calldata decompressedSizesIcons_)
        external
        onlyOwner
        initialize(3)
    {
        uint256 iconCount_ = icons_.length;
        for (uint256 j_; j_ < iconCount_; j_++) {
            _write(bytes32(keccak256(abi.encode(j_ + MEMORY_OFFSET))), icons_[j_]);
            _iconMetadata.push(decompressedSizesIcons_[j_]);
        }
    }

    function reveal(bytes7[] memory imageTraits_) external onlyOwner {
        _imageTraits = imageTraits_;
    }

    function tokenURI(uint256 tokenId_) public view override returns (string memory) {
        MetadataBytes memory data_;
        data_ = processMetadataAsBytes(_imageTraits.length > 0 ? _imageTraits[tokenId_] : _sampleImageTraits);

        Metadata memory metadata_ = abi.decode(_read(METADATA_POINTER), (Metadata));

        Image memory image_ = abi.decode(
            ZLib(_zlib).inflate(_read(bytes32(keccak256(abi.encode(data_.yak)))), _imageMetadata[data_.yak]), (Image)
        );

        Icon memory icon_ = abi.decode(
            ZLib(_zlib).inflate(
                _read(bytes32(keccak256(abi.encode(data_.icon + MEMORY_OFFSET)))), _iconMetadata[data_.icon]
            ),
            (Icon)
        );

        bytes memory dataURI = abi.encodePacked(
            "{",
            '"name": "Yakyuken #',
            tokenId_.toString(),
            '", "description": "',
            "Yakyuken NFT on-chain collection.",
            '", "image_data": "',
            string(
                abi.encodePacked(
                    "data:image/svg+xml;base64,", Base64.encode(_generateSVGfromBytes(data_, metadata_, image_, icon_))
                )
            ),
            '",',
            _getAttributes(data_, metadata_, [image_.name, icon_.name]),
            "}"
        );

        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(dataURI)));
    }

    function generateSVGfromBytes(uint256 tokenId_) external view returns (string memory svg_) {
        MetadataBytes memory data_;
        data_ = processMetadataAsBytes(_imageTraits.length > 0 ? _imageTraits[tokenId_] : _sampleImageTraits);
  

        Metadata memory metadata_ = abi.decode(_read(METADATA_POINTER), (Metadata));

        Image memory image_ = abi.decode(
            ZLib(_zlib).inflate(_read(bytes32(keccak256(abi.encode(data_.yak)))), _imageMetadata[data_.yak]), (Image)
        );

        Icon memory icon_ = abi.decode(
            ZLib(_zlib).inflate(
                _read(bytes32(keccak256(abi.encode(data_.icon + MEMORY_OFFSET)))), _iconMetadata[data_.icon]
            ),
            (Icon)
        );
        svg_ = string(_generateSVGfromBytes(data_, metadata_, image_, icon_));
    }

    function processMetadataAsBytes(bytes7 metadataInfo_) public view returns (MetadataBytes memory data_) {
        Metadata memory metadata_ = abi.decode(_read(METADATA_POINTER), (Metadata));
        data_.glowTimes = _getTraitFromMask(metadataInfo_, 0, 0, metadata_.glowTimes.length);
        data_.backgroundColors = _getTraitFromMask(metadataInfo_, 1, 0, metadata_.backgroundColors.length);
        data_.yakHoverColors = _getTraitFromMask(metadataInfo_, 2, 4, metadata_.yakHoverColors.length);
        data_.finalShadowColors = _getTraitFromMask(metadataInfo_, 2, 10, metadata_.finalShadowColors.length);
        data_.baseFillColors = _getTraitFromMask(metadataInfo_, 3, 4, metadata_.baseFillColors.length);
        data_.yakFillColors = _getTraitFromMask(metadataInfo_, 3, 10, metadata_.yakFillColors.length);
        data_.yak = _getTraitFromMask(metadataInfo_, 4, 4, _imageMetadata.length);
        data_.initialShadowColors = _getTraitFromMask(metadataInfo_, 4, 10, metadata_.initialShadowColors.length);
        data_.initialShadowBrightness = _getTraitFromMask(metadataInfo_, 5, 4, metadata_.initialShadowBrightness.length);
        data_.finalShadowBrightness = _getTraitFromMask(metadataInfo_, 5, 10, metadata_.finalShadowBrightness.length);
        data_.icon = _getTraitFromMask(metadataInfo_, 6, 4, _iconMetadata.length);
        data_.texts = _getTraitFromMask(metadataInfo_, 6, 10, metadata_.texts.length);
    }

    function mint(address to_, uint256 tokenId_) external onlySale {
        _mint(to_, tokenId_);
    }

    function setSaleContract(address sale_) external onlyOwner {
        _saleContract = sale_;
    }

    function _initialize(uint256 id_) internal {
        if (_initialized[id_]) revert AlreadyInitializedError();
        _initialized[id_] = true;
    }

    function _getTraitFromMask(bytes7 mask_, uint8 pos_, uint8 shift_, uint256 max_) internal pure returns(uint8 trait_) {
        if (shift_ == 0) trait_ = uint8(mask_[pos_]);
        else if (shift_ == 4) trait_ = uint8(mask_[pos_] >> 4);
        else trait_ = uint8(mask_[pos_] & 0x0F);
        if (trait_ >= max_) revert OutOfBondsTraitValueError();
    }

    function _generateSVGfromBytes(
        MetadataBytes memory data_,
        Metadata memory metadata_,
        Image memory image_,
        Icon memory icon_
    ) internal pure returns (bytes memory) {
        return abi.encodePacked(
            _getHeader(image_.viewBox, metadata_.backgroundColors[data_.backgroundColors]),
            _getStyleHeader(
                metadata_.initialShadowColors[data_.initialShadowColors],
                metadata_.finalShadowColors[data_.finalShadowColors],
                metadata_.initialShadowBrightness[data_.initialShadowBrightness],
                metadata_.finalShadowBrightness[data_.finalShadowBrightness],
                metadata_.baseFillColors[data_.baseFillColors],
                metadata_.glowTimes[data_.glowTimes],
                metadata_.yakFillColors[data_.yakFillColors],
                metadata_.yakHoverColors[data_.yakHoverColors],
                metadata_.yakFillColors[data_.yakFillColors]
            ),
            image_.path,
            _getIcon(icon_.path, image_.iconSize),
            "</svg>"
        );
    }

    function _getHeader(string memory viewBox_, string memory backgroundColor_) internal pure returns (bytes memory) {
        return abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMidYMid meet" viewBox="',
            viewBox_,
            '" style="background-color:',
            backgroundColor_,
            '">'
        );
    }

    function _getStyleHeader(
        string memory initialShadowColors_,
        string memory finalShadowColors_,
        string memory initialShadowBrightness_,
        string memory finalShadowBrightness_,
        string memory baseFillColors_,
        string memory glowTimes_,
        string memory yakFillColors_,
        string memory hoverColors_,
        string memory iconColor_
    ) internal pure returns (bytes memory) {
        return abi.encodePacked(
            "<style>",
            "@keyframes glow {0% {filter: drop-shadow(16px 16px 20px ",
            initialShadowColors_,
            ") brightness(",
            initialShadowBrightness_,
            "%);}to {filter: drop-shadow(16px 16px 20px ",
            finalShadowColors_,
            ") brightness(",
            finalShadowBrightness_,
            "%);}}path {fill: ",
            baseFillColors_,
            ";animation: glow ",
            glowTimes_,
            "s ease-in-out infinite alternate;}.yak {fill: ",
            yakFillColors_,
            ";}.yak:hover {fill: ",
            hoverColors_,
            ";}.icon {fill: ",
            iconColor_,
            ";}</style>"
        );
    }

    function _getIcon(string memory path_, string memory iconSize_) internal pure returns (bytes memory) {
        string memory iconLocation_ = " x=\"5%\" y=\"5%\" ";
        return abi.encodePacked("<svg ", iconSize_, iconLocation_, "> ", path_, "</svg>");
    }

    function _getAttributes(MetadataBytes memory data_, Metadata memory metadata_, string[2] memory names_)
        internal
        pure
        returns (string memory)
    {
        return (
            string(
                abi.encodePacked(
                    ' "attributes" : [{ "trait_type": "Character", "value":"',
                    names_[0],
                    '" },  { "trait_type": "Icon", "value": "',
                    names_[1],
                    '"},  { "trait_type": "Background Color", "value": "',
                    metadata_.backgroundColors[data_.backgroundColors],
                    '" }, { "trait_type": "Initial Shadow Color", "value":"',
                    metadata_.initialShadowColors[data_.initialShadowColors],
                    '" }, { "trait_type": "Initial Shadow Brightness", "value":"',
                    metadata_.initialShadowBrightness[data_.initialShadowBrightness],
                    '" }, { "trait_type": "Final Shadow Color ", "value":"',
                    metadata_.finalShadowColors[data_.finalShadowColors],
                    '" }, { "trait_type": "Final Shadow Brightness", "value":"',
                    metadata_.finalShadowBrightness[data_.finalShadowBrightness],
                    '" }, { "trait_type": "Base Fill Colors", "value":"',
                    metadata_.baseFillColors[data_.baseFillColors],
                    '" }, { "trait_type": "Glow Times", "value":"',
                    metadata_.glowTimes[data_.glowTimes],
                    '" }, { "trait_type": "Yak Fill Colors", "value":"',
                    metadata_.yakFillColors[data_.yakFillColors],
                    '" }, { "trait_type": "Hover Colors", "value":"',
                    metadata_.yakHoverColors[data_.yakHoverColors],
                    '" }, { "trait_type": "Rock, Paper, Scissors", "value":"',
                    metadata_.texts[data_.texts],
                    '"} ]'
                )
            )
        );
    }
}
