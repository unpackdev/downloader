// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./Address.sol";
import "./ColorPalette.sol";
import "./Color.sol";
import "./IColorProvider.sol";
import "./IMetadataRenderer.sol";
import "./ERC721Slim.sol";
import "./Base64.sol";
import "./Random.sol";

contract Synesthesia is ERC721Slim, ColorPalette, Ownable {
    uint256 public constant MAX_MINT_PER_TX = 20;
    uint256 public constant UNIT_PRICE = 0.055 ether;

    uint8 private constant SALE_STATE_NOT_STARTED = 0;
    uint8 private constant SALE_STATE_STARTED = 1;
    uint8 private constant SALE_STATE_CLOSED = 2;

    address public constant OPENDAO_TREASURY = 0xd08d0e994EeEf4001C63C72991Cf05918aDF191b;

    struct Config {
        uint8 saleState;
        uint16 maxSupply;
        uint128 randomSeed;
        uint104 minterSeed;
    }

    bytes32 public immutable _saltHash;
    Config public _config;
    IMetadataRenderer _renderer;

    constructor(uint16 maxSupply, bytes32 saltHash, address renderer, IColorProvider[] memory colorProviders)
        ERC721Slim("Synesthesia", "SYNES")
    {
        require(renderer != address(0), "Synesthesia: renderer shouldn't be zero address");
        require(maxSupply > 0, "Synesthesia: max supply should be larger than zero");
        require(saltHash != 0, "Synesthesia: salt hash cannot be zero");

        _setColorProviders(colorProviders);

        _config = Config({
            saleState: SALE_STATE_NOT_STARTED,
            maxSupply: maxSupply,
            randomSeed: 0,
            minterSeed: 0
        });

        _renderer = IMetadataRenderer(renderer);
        _saltHash = saltHash;
    }

    function sqeezePigmentTube(uint256 amount) external payable {
        Config memory config = _config;

        require(tx.origin == msg.sender, "Synesthesia: are you botting?");
        require(config.saleState == SALE_STATE_STARTED, "Synesthesia: sale is not yet started");
        require(amount <= MAX_MINT_PER_TX, "Synesthesia: exceeds maximum amount per transaction");
        require(amount * UNIT_PRICE <= msg.value, "Synesthesia: insufficient fund");
        require(amount + totalMinted() <= config.maxSupply, "Synesthesia: exceeds total supply");

        _safeBatchMint(msg.sender, amount);

        config.minterSeed = uint104(uint256(keccak256(abi.encodePacked(config.minterSeed, msg.sender))));
        _config = config;
    }

    function setRenderer(address renderer) external onlyOwner {
        _renderer = IMetadataRenderer(renderer);
    }

    function setColorProvier(IColorProvider[] memory colorProviders) external onlyOwner {
        _setColorProviders(colorProviders);
    }

    function setSaleState(uint8 targetSaleState) external onlyOwner {
        _config.saleState = targetSaleState;
    }

    function revealColors(string memory salt) external onlyOwner {
        require(keccak256(bytes(salt)) == _saltHash, "Synesthesia: invalid salt");
        require(_config.randomSeed == 0, "Synesthesia: already revealed");

        uint256 lastBlock = block.number - 1;
        _config.randomSeed = uint128(uint256(keccak256(abi.encodePacked(
            salt,
            _config.minterSeed,
            uint256(blockhash(lastBlock)),
            uint256(block.timestamp)))));
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        uint256 feedbackToOpenDAO = balance * 10 / 100;

        Address.sendValue(payable(OPENDAO_TREASURY), feedbackToOpenDAO);
        Address.sendValue(payable(msg.sender), balance - feedbackToOpenDAO);
    }

    function functionCall(address target, bytes calldata data) external payable onlyOwner {
        Address.functionCallWithValue(target, data, msg.value);
    }

    // ========================================
    //    IERC721Metadata implementations
    // ========================================

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Synesthesia: URI query for nonexistent token");
        Config memory config = _config;

        if (_config.randomSeed == 0) {
            return _renderer.renderUnreveal(uint16(tokenId));
        } else {
            uint16 randomizedId = Random.getRandomizedId(
                uint16(tokenId),
                uint16(config.maxSupply),
                config.randomSeed);
            Color memory color = getColor(randomizedId);

            return _renderer.render(uint16(tokenId), color);
        }
    }
}
