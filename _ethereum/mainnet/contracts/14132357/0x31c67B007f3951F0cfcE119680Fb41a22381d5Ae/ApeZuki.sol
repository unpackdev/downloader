//SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC721SlimApe.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./draft-EIP712.sol";
import "./ECDSA.sol";

contract ApeZuki is ERC721SlimApe, EIP712, Ownable {
    using Strings for uint256;
    using ECDSA for bytes32;

    event FreeMinted(address luckyAdopter, uint8 amount);

    bytes32 public constant LOTTERY_SALT = 0x495f947276749ce646f68ac8c248420045cb7b5e45cb7b5e45cb7b5eea213782;
    uint256 public constant PRICE = 0.06 ether;

    struct Config {
        uint16 maxSupply;
        uint16 reservedMintSupply;
        uint16 fixedFreeMintSupply;
        uint16 randomFreeMintSupply;
        uint16 randomFreeMinted;
        bool saleStarted;
    }

    struct Adopter {
        bool reservedMinted;
        bool freeMinted;
    }

    mapping(address => Adopter) public _adopters;
    Config public _config;
    string public _baseURI;

    constructor(Config memory config, string memory baseURI) ERC721SlimApe("ApeZuki", "APEZ") EIP712("ApeZuki", "1") {
        _config = config;
        _baseURI = baseURI;
    }

    function adoptApes(uint256 amount) external payable {
        Config memory config = _config;
        require(tx.origin == msg.sender, "ApeZuki: ape hates bots");
        require(config.saleStarted, "ApeZuki: sale is not started");

        uint256 totalMinted = _totalMinted();
        uint256 publicSupply = config.maxSupply - config.reservedMintSupply;
        require(totalMinted + amount <= publicSupply, "ApeZuki: exceed public supply");

        if (totalMinted < config.fixedFreeMintSupply) {
            require(!_adopters[msg.sender].freeMinted && amount == 1, "ApeZuki: you can only mint 1 for free");

            _adopters[msg.sender].freeMinted = true;
            _mint(msg.sender);
            return;
        }

        require(msg.value >= PRICE * amount, "ApeZuki: insufficient fund");

        uint256 refundAmount = 0;
        uint256 remainFreeMintQuota = config.randomFreeMintSupply - config.randomFreeMinted;
        uint256 randomSeed = uint256(keccak256(abi.encodePacked(
            msg.sender,
            totalMinted,
            block.difficulty,
            LOTTERY_SALT)));

        for (uint256 i = 0; i < amount && remainFreeMintQuota > 0; i++) {
            if (uint16((randomSeed & 0xFFFF) % publicSupply) < remainFreeMintQuota) {
                refundAmount += 1;
                remainFreeMintQuota -= 1;
            }

            randomSeed = randomSeed >> 16;
        }

        config.randomFreeMinted += uint16(refundAmount);

        if (refundAmount > 0) {
            _config = config;
            Address.sendValue(payable(msg.sender), refundAmount * PRICE);
            emit FreeMinted(msg.sender, uint8(refundAmount));
        }

        _safeBatchMint(msg.sender, amount);
    }

    function verifyAndExtractAmount(
        uint16 amountV,
        bytes32 r,
        bytes32 s
    ) internal view returns (uint256) {
        uint256 amount = uint8(amountV);
        uint8 v = uint8(amountV >> 8);

        bytes32 funcCallDigest = keccak256(abi.encode(
            keccak256("adopt(address parent,uint256 amount)"),
            msg.sender,
            amount));

        bytes32 digest = keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            _domainSeparatorV4().toTypedDataHash(funcCallDigest)));

        require(ecrecover(digest, v, r, s) == address(owner()), "ApeZuki: invalid signer");
        return amount;
    }

    function adoptReservedApes(
        uint16 amountV,
        bytes32 r,
        bytes32 s
    ) external {
        Config memory config = _config;
        uint256 totalMinted = _totalMinted();
        require(totalMinted <= config.maxSupply, "ApeZuki: exceed max supply");
        require(!_adopters[msg.sender].reservedMinted, "ApeZuki: already adopted");

        uint256 amount = verifyAndExtractAmount(amountV, r, s);
        _adopters[msg.sender].reservedMinted = true;

        _safeBatchMint(msg.sender, amount);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ApeZuki: URI query for nonexistent token");
        return string(abi.encodePacked(_baseURI, tokenId.toString(), ".json"));
    }

    // ------- Admin Operations -------

    function setConfig(Config calldata config) external onlyOwner {
        Config memory config_ = _config;

        config_.maxSupply = config.maxSupply;
        config_.reservedMintSupply = config.reservedMintSupply;
        config_.fixedFreeMintSupply = config.fixedFreeMintSupply;
        config_.randomFreeMintSupply = config.randomFreeMintSupply;

        _config = config_;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseURI = baseURI;
    }

    function flipSaleState() external onlyOwner {
        _config.saleStarted = !_config.saleStarted;
    }

    function withdarw() external onlyOwner {
        Address.sendValue(payable(msg.sender), address(this).balance);
    }
}
