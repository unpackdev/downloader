// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ECDSA.sol";
import "./MerkleProof.sol";
import "./console.sol";

error SaleNotStarted();
error SaleInProgress();
error InsufficientPayment();
error IncorrectPayment();
error AccountNotWhitelisted();
error AmountExceedsSupply();
error WhitelistAlreadyClaimed();
error AmountExceedsTransactionLimit();
error OnlyExternallyOwnedAccountsAllowed();
error InvalidToken();
error NotTokenIDOwner();
error SaleNotConcluded();

contract MeridiumZone is ERC721A, Ownable, ReentrancyGuard {
    using ECDSA for bytes32;

    bytes32 public merkleRoot = 0xb6ae0b6dc75ff00f31caebd35e17dab1abb282866f0510f204b8c5e6db5173b0;

    uint256 public constant MAX_SUPPLY = 10000;
    uint256 private constant FAR_FUTURE = 0xFFFFFFFFF;
    uint256 private constant MAX_MINTS_PER_TX = 10;
    uint256 private constant MAX_MINTS_PER_WL_TX = 5;

    uint256 private _presaleStart = FAR_FUTURE;
    uint256 private _publicSaleStart = FAR_FUTURE;
    uint256 private _marketingSupply = 150;
    uint256 private _salePrice = 0.08 ether;
    bool private _whitelistMintAgain = false;
    bool private _saleConcluded = false;
    bool public isRevealed = false;

    string private _baseTokenURI;
    string private _preRevealURI = "https://meridiumzone.com/placeholder/reveal.json";
    mapping(address => bool) private _mintedWhitelist;
    mapping(address => bool) private _mintedWhitelistSecondRound;

    event PresaleStart(uint256 price, uint256 supplyRemaining);
    event PublicSaleStart(uint256 price, uint256 supplyRemaining);
    event SalePaused();

    constructor() ERC721A("MeridiumZone", "MZ") { }

    // WHITELIST PRESALE
    function isPresaleActive() public view returns (bool) {
        return block.timestamp > _presaleStart;
    }

    function presaleMint(uint256 quantity, bytes32[] calldata _merkleProof) external payable nonReentrant onlyEOA {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

        if (!isPresaleActive())                     revert SaleNotStarted();
        if (!MerkleProof.verify(_merkleProof, merkleRoot, leaf)) revert AccountNotWhitelisted();
        if (hasMintedPresale(msg.sender))           revert WhitelistAlreadyClaimed();
        if (quantity > MAX_MINTS_PER_WL_TX)         revert AmountExceedsTransactionLimit();
        if (totalSupply() + quantity > MAX_SUPPLY)  revert AmountExceedsSupply();
        if (msg.value < getSalePrice() * quantity)  revert IncorrectPayment();

        if (_whitelistMintAgain) {
            _mintedWhitelistSecondRound[msg.sender] = true;
        } else {
            _mintedWhitelist[msg.sender] = true;
        }
        _safeMint(msg.sender, quantity);
    }

    function hasMintedPresale(address account) public view returns (bool) {
        return _whitelistMintAgain ? _mintedWhitelistSecondRound[account] : _mintedWhitelist[account];
    }

    function allowWhitelistAgain(bool allow) external onlyOwner {
        _whitelistMintAgain = allow;
    }

    // PUBLIC SALE
    function isPublicSaleActive() public view returns (bool) {
        return block.timestamp > _publicSaleStart;
    }

    function publicMint(uint256 quantity) external payable nonReentrant onlyEOA {
        if (!isPublicSaleActive())                  revert SaleNotStarted();
        if (totalSupply() + quantity > MAX_SUPPLY)  revert AmountExceedsSupply();
        if (msg.value < getSalePrice() * quantity)  revert IncorrectPayment();
        if (quantity > MAX_MINTS_PER_TX)            revert AmountExceedsTransactionLimit();

        _safeMint(msg.sender, quantity);
    }

    // METADATA
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setPreRevealURI(string calldata preRevealURI) external onlyOwner {
        _preRevealURI = preRevealURI;
    }

    function setMerkleRoot(bytes32 root) external onlyOwner {
        merkleRoot = root;
    }

    function startPresale() external onlyOwner {
        if (isPublicSaleActive()) revert SaleInProgress();

        _presaleStart = block.timestamp;

        emit PresaleStart(getSalePrice(), MAX_SUPPLY - totalSupply());
    }

    function startPublicSale() external onlyOwner {
        if (isPresaleActive()) revert SaleInProgress();

        _publicSaleStart = block.timestamp;

        emit PublicSaleStart(getSalePrice(), MAX_SUPPLY - totalSupply());
    }

    function pauseSale() external onlyOwner {
        _presaleStart = FAR_FUTURE;
        _publicSaleStart = FAR_FUTURE;

        emit SalePaused();
    }

    modifier onlyEOA() {
        if (tx.origin != msg.sender) revert OnlyExternallyOwnedAccountsAllowed();
        _;
    }

    function getSalePrice() public view returns (uint256) {
        return _salePrice;
    }

    function setSalePrice(uint256 price) external onlyOwner {
        _salePrice = price;
    }

    function setReveal(bool reveal) external onlyOwner {
        isRevealed = reveal;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return isRevealed
            ? string(abi.encodePacked(_baseTokenURI, Strings.toString(tokenId), '.json'))
            : string(abi.encodePacked(_preRevealURI));
    }

    // BURNING
    function burnToken(uint256 tokenId) external {
        if (isPresaleActive() || isPublicSaleActive()) revert SaleInProgress();
        if (msg.sender != ownerOf(tokenId)) revert NotTokenIDOwner();
        if (!_saleConcluded) revert SaleNotConcluded();

        _burn(tokenId);
    }

    function concludeSale(bool conclude) external onlyOwner {
        if (isPresaleActive() || isPublicSaleActive()) revert SaleInProgress();

        _saleConcluded = conclude;
    }


    // TEAM
    function marketingMint(uint256 quantity) external onlyOwner {
        if (quantity > _marketingSupply)           revert AmountExceedsSupply();
        if (totalSupply() + quantity > MAX_SUPPLY) revert AmountExceedsSupply();

        _marketingSupply -= quantity;
        _safeMint(owner(), quantity);
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}