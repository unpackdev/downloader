// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./IERC2981.sol";
import "./draft-EIP712.sol";
import "./ECDSA.sol";
import "./ERC721A.sol";

error ErrorTeamSupplyTooMuch();
error ErrorInvalidRoyaltyFeeRate();
error ErrorInvalidSignature();
error ErrorForbidden();
error ErrorExceedMaxSupply();
error ErrorInsufficientFunds();
error ErrorPresaleNotStarted();
error ErrorExceedPresaleMintLimit();
error ErrorPublicSaleNotStarted();
error ErrorExceedPublicSaleTransactionLimit();
error ErrorExceedPublicSaleWalletLimit();
error ErrorExceedTeamSupply();

contract TheSoundOfAnimals is ERC721A, EIP712, IERC2981, Ownable {
    using Strings for uint256;
    using ECDSA for bytes32;

    uint256 public constant PRICE_MULTIPLIER = 0.0001 ether;
    uint256 private constant FEE_DENOMINATOR = 10000;
    bytes32 private constant PRESALE_HASH = keccak256("presaleMint(address receiver)");

    uint8 public constant PRESALE_MAX_MINT = 1;
    uint8 public constant PUBLIC_SALE_MAX_MINT_PER_TX = 5;
    uint8 public constant PUBLIC_SALE_MAX_MINT_PER_WALLET = 20;

    struct Config {
        // Immutable config
        uint16 maxSupply;
        uint16 teamReservedSupply;
        // Mutable config
        uint16 publicSalePrice;
        uint16 royaltyRate;
        // Mutable state
        uint16 teamMinted;
        bool isPresaleActive;
        bool isPublicSaleActive;
    }

    Config public _config;
    string public _uriPrefix;

    constructor(Config memory config, string memory uriPrefix)
        ERC721A("TheSoundOfAnimals", "TSOA")
        EIP712("TheSoundOfAnimals", "1")
    {
        if (config.maxSupply < config.teamReservedSupply) revert ErrorTeamSupplyTooMuch();
        if (config.royaltyRate > FEE_DENOMINATOR) revert ErrorInvalidRoyaltyFeeRate();
        config.teamMinted = 0;

        _config = config;
        _uriPrefix = uriPrefix;
    }

    modifier verifySig(
        bytes32 mintMethodHash,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) {
        bytes32 funcCallDigest = keccak256(abi.encode(mintMethodHash, msg.sender));
        bytes32 typedDataDigest = _domainSeparatorV4().toTypedDataHash(funcCallDigest);
        bytes32 digest = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", typedDataDigest));

        if (ecrecover(digest, v, r, s) != address(owner())) revert ErrorInvalidSignature();
        _;
    }

    modifier botDefender() {
        if (tx.origin != msg.sender) revert ErrorForbidden();
        _;
    }

    function ensureSupply(Config memory config, uint8 mintAmount) internal view {
        uint256 publicSupply = uint256(config.maxSupply - config.teamReservedSupply);
        if (_currentIndex + mintAmount > publicSupply) revert ErrorExceedMaxSupply();
    }

    function ensureSufficientValue(uint16 unitPrice, uint8 mintAmount) internal view {
        if (uint256(unitPrice) * PRICE_MULTIPLIER * mintAmount != msg.value) revert ErrorInsufficientFunds();
    }

    function presaleMintAnimals(
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external botDefender verifySig(PRESALE_HASH, r, s, v) {
        Config memory config = _config;
        if (!config.isPresaleActive) revert ErrorPresaleNotStarted();

        ensureSupply(config, 1);
        if (incrementPresaleMinted(1) > PRESALE_MAX_MINT) revert ErrorExceedPresaleMintLimit();

        _safeMint(msg.sender, 1);
    }

    function publicSaleMintAnimals(uint8 amount) external payable botDefender {
        Config memory config = _config;
        if (!config.isPublicSaleActive) revert ErrorPublicSaleNotStarted();

        if (amount > PUBLIC_SALE_MAX_MINT_PER_TX) revert ErrorExceedPublicSaleTransactionLimit();
        ensureSupply(config, amount);
        ensureSufficientValue(config.publicSalePrice, amount);
        if (incrementPublicMinted(amount) > PUBLIC_SALE_MAX_MINT_PER_WALLET) revert ErrorExceedPublicSaleWalletLimit();

        _safeMint(msg.sender, amount);
    }

    // ::
    // :: Aux operation
    // ::
    // :: Memory layout (64-bits space):
    // ::     | High bits...| PresaleMinted(8bit) | PublicMinted(8bit) |
    // ::

    function _aux(address minter) public view returns (uint64) {
        return _getAux(minter);
    }

    function incrementMintedNumberInAux(
        uint64 mask,
        uint8 offset,
        uint8 amount
    ) internal returns (uint8) {
        uint64 aux = _getAux(msg.sender);
        uint8 newMintedAmount = uint8((aux >> offset) & 0xFF) + amount;
        _setAux(msg.sender, (aux & mask) | (uint64(newMintedAmount) << offset));
        return newMintedAmount;
    }

    function _presaleMinted(address minter) public view returns (uint8) {
        return uint8((_getAux(minter) >> 8) & 0xFF);
    }

    function incrementPresaleMinted(uint8 amount) internal returns (uint8) {
        return incrementMintedNumberInAux(0xFF00FF, 8, amount);
    }

    function _publicSaleMinted(address minter) public view returns (uint8) {
        return uint8(_getAux(minter) & 0xFF);
    }

    function incrementPublicMinted(uint8 amount) internal returns (uint8) {
        return incrementMintedNumberInAux(0xFFFF00, 0, amount);
    }

    // ::
    // :: Admin operation
    // ::

    function teamMintAnimals(address to, uint16 amount) external onlyOwner {
        Config memory config = _config;

        if (amount + config.teamMinted > config.teamReservedSupply) revert ErrorExceedTeamSupply();
        _config.teamMinted += amount;

        _safeMint(to, amount);
    }

    function setURIPrefix(string calldata uriPrefix) external onlyOwner {
        _uriPrefix = uriPrefix;
    }

    function setPrices(uint16 publicSalePrice) external onlyOwner {
        Config memory config = _config;
        config.publicSalePrice = publicSalePrice;
        _config = config;
    }

    function setRoyaltyRate(uint16 royaltyRate) external onlyOwner {
        if (royaltyRate > FEE_DENOMINATOR) revert ErrorInvalidRoyaltyFeeRate();
        _config.royaltyRate = royaltyRate;
    }

    function flipPresaleState() external onlyOwner {
        _config.isPresaleActive = !_config.isPresaleActive;
    }

    function flipPublicSaleState() external onlyOwner {
        _config.isPublicSaleActive = !_config.isPublicSaleActive;
    }

    function withdraw() external onlyOwner {
        Address.sendValue(payable(msg.sender), address(this).balance);
    }

    // ::
    // :: EIP Implementations
    // ::

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        return string(abi.encodePacked(_uriPrefix, tokenId.toString(), ".json"));
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721A, IERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || ERC721A.supportsInterface(interfaceId);
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        return (owner(), (salePrice * _config.royaltyRate) / FEE_DENOMINATOR);
    }
}
