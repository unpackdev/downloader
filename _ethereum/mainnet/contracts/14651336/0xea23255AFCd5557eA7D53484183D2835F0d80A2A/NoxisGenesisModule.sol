// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MerkleProof.sol";

import "./IERC2981.sol";

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./SafeERC20.sol";
import "./FixedPointMathLib.sol";

import "./ERC1155.sol";
import "./ERC1155Burnable.sol";
import "./ERC1155Supply.sol";

contract NoxisGenesisModule is Ownable, ERC1155, ERC1155Burnable, ERC1155Supply, IERC2981, ReentrancyGuard {
    /* ========== DEPENDENCIES ========== */
    using SafeERC20 for IERC20;
    using FixedPointMathLib for uint256;
    using Strings for uint256;

    /* ====== CONSTANTS ====== */

    uint64 public constant MAX_SUPPLY = 225;
    uint64 public constant MAX_WL_MINT_QUANTITY = 10;
    uint64 public constant MAX_MINT_QUANTITY = 10;
    uint64 public constant PUBLIC_SALE_PRICE = 0.03 ether;

    string public constant name = "Noxis Genesis Module";
    string public constant symbol = "NOXIS";

    address payable private constant _owner1 = payable(0x091D30e4C497747C53C37f1962c7116cc60742b4);
    address payable private constant _owner2 = payable(0x056aA6367DcC826c61ce69388d2C02D9e6154418);
    address payable private constant _owner3 = payable(0x9Fdaa74AE574B2E0B88210c6608C500C12D0beD3);

    bytes32 public constant root = 0x6c8bf247d8b8c2cf9b09e9c3927c4ac6a8de62cb7d4666d6da9188b23af22729;

    /* ====== VARIABLES ====== */

    bool public isPublicSaleActive = false;

    /* ====== MODIFIERS ====== */

    modifier tokenExists(uint256 tokenId_) {
        require(exists(tokenId_), "Noxis: !exist");
        _;
    }

    modifier onWhitelist(bytes32[] calldata merkleProof_) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(merkleProof_, root, leaf), "Noxis: !on whitelist");
        _;
    }

    modifier publicSaleActive() {
        require(isPublicSaleActive, "Noxis: !active");
        _;
    }

    modifier maxWLMints(uint256 quantity_) {
        require(quantity_ <= MAX_WL_MINT_QUANTITY, "Noxis: max wl mint exceeded");
        require(balanceOf(msg.sender, 0) + quantity_ <= MAX_WL_MINT_QUANTITY, "Noxis: max wl mint exceeded");
        _;
    }

    modifier maxMintsPerTX(uint256 quantity_) {
        require(quantity_ <= MAX_MINT_QUANTITY, "Noxis: max mint exceeded");
        _;
    }

    modifier canMintNFTs(uint256 quantity_) {
        require(totalSupply(0) + quantity_ <= MAX_SUPPLY, "Noxis: quantity exceeded totalSupply()");
        _;
    }

    modifier isCorrectPayment(uint256 quantity_) {
        require((PUBLIC_SALE_PRICE * quantity_) == msg.value, "Noxis: !enough eth");
        _;
    }

    /* ====== CONSTRUCTOR ====== */

    constructor() ERC1155("ipfs://QmS71P67dPHb8WGJEPe2kJ9KJFvKDifjDY7wWUSEg1gza8") {
        // Mint 25 for promotional use
        _mint(0x6A9e6d86475A3061674aBea97B1Cbd9f67815eAD, 0, 25, "");
    }

    function mint(
        uint256 quantity_
    )
    external payable
    nonReentrant
    publicSaleActive
    maxMintsPerTX(quantity_)
    canMintNFTs(quantity_)
    isCorrectPayment(quantity_)
    {
        // Mint NOXIS NFT
        _mint(msg.sender, 0,  quantity_, "");
    }

    function wl_mint(
        uint256 quantity_,
        bytes32[] calldata merkleProof_
    )
    external payable
    nonReentrant
    onWhitelist(merkleProof_)
    maxWLMints(quantity_)
    canMintNFTs(quantity_)
    isCorrectPayment(quantity_)
    {
        // Mint NOXIS NFT
        _mint(msg.sender, 0,  quantity_, "");
    }

    /* ========== VIEW ========== */

    function uri(uint256 tokenId_) public view virtual override tokenExists(tokenId_) returns (string memory) {
        return string(abi.encodePacked(super.uri(tokenId_), "/", tokenId_.toString(), ".json"));
    }

    /* ========== FUNCTION ========== */

    function setURI(string memory URI_) external onlyOwner {
        _setURI(URI_);
    }

    function setIsPublicSaleActive(bool isPublicSaleActive_) external onlyOwner {
        isPublicSaleActive = isPublicSaleActive_;
    }

    function withdraw() public {
        uint256 balance_ = address(this).balance;

        (bool success1_, ) = _owner1.call{value: balance_.mulDivDown(65,100)}("");
        require(success1_, "Transfer failed.");

        (bool success2_, ) = _owner2.call{value: balance_.mulDivDown(25,100)}("");
        require(success2_, "Transfer failed.");

        (bool success3_, ) = _owner3.call{value: balance_.mulDivDown(10,100)}("");
        require(success3_, "Transfer failed.");
    }

    function withdrawTokens(IERC20 token) public {
        uint256 balance_ = token.balanceOf(address(this));

        token.safeTransfer(_owner1, balance_.mulDivDown(65,100));
        token.safeTransfer(_owner2, balance_.mulDivDown(25,100));
        token.safeTransfer(_owner3, balance_.mulDivDown(10,100));
    }

    // ============ FUNCTION OVERRIDES ============

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function supportsInterface(bytes4 interfaceId_) public view virtual override(ERC1155, IERC165) returns (bool) {
        return interfaceId_ == type(IERC2981).interfaceId || super.supportsInterface(interfaceId_);
    }

    /**
     * @dev See {IERC165-royaltyInfo}.
     */
    function royaltyInfo(uint256 tokenId_, uint256 salePrice_)
    external view override
    tokenExists(tokenId_)
    returns (address receiver, uint256 royaltyAmount)
    {
        return (0x6A9e6d86475A3061674aBea97B1Cbd9f67815eAD, salePrice_.mulDivDown(75, 1000));
    }
}
