// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC2981.sol";
import "./Counters.sol";
import "./Address.sol";
import "./Pausable.sol";
import "./ERC721A.sol";
import "./ERC721ABurnable.sol";

contract NoMaGuild is ERC721A, ERC721ABurnable, IERC2981, ReentrancyGuard, Ownable, Pausable {
    using Strings for uint256;
    using Counters for Counters.Counter;

    // Contract immutables
    uint256 public immutable maxMummies;
    uint256 public immutable mintLimitPerWallet;

    // Constants
    uint256 public constant ROYALTY_RATE = 3; // 3%
    uint256 public constant PUBLIC_PRICE = 0.04096 ether;

    // Constructur set constants
    string public baseTokenURI;
    string public hiddenTokenURI;

    // Switches
    bool public isPublicSaleOpen = false;

    // Set refunding start datetime to creation time
    uint256 public refundStartTime = block.timestamp;

    // Events
    event PublicSaleEvent(bool pause);

    // Errors
    error Soldout();
    error PublicSaleClosed();
    error ExceededLimitPerWallet();
    error InsufficientPaymentPerItem();
    error NonZeroWitdraw();
    error RefundGuaranteeExpired();
    error RefundGuaranteeStillActive();
    error MustOwnToken();
    error IdenticalState();

    constructor(
        string memory __symbol,
        string memory __name,
        uint256 _maxMummies,
        uint256 _mintLimitPerWallet,
        string memory baseURI,
        string memory _hiddenTokenURI
    ) ERC721A(__symbol, __name) {
        maxMummies = _maxMummies;
        mintLimitPerWallet = _mintLimitPerWallet;
        hiddenTokenURI = _hiddenTokenURI;
        setBaseURI(baseURI);
    }

    modifier notSoldOut() {
        if (totalSupply() >= maxMummies) revert Soldout();
        _;
    }

    modifier publicSaleIsOpen() {
        if (!isPublicSaleOpen) revert PublicSaleClosed();
        if (totalSupply() >= maxMummies) revert Soldout();
        _;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function _hiddenURI() internal view virtual returns (string memory) {
        return hiddenTokenURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        string memory baseURI = _baseURI();
        string memory hiddenURI = _hiddenURI();
        return
            bytes(baseURI).length != 0 && bytes(hiddenURI).length == 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), '.json'))
                : string(abi.encodePacked(hiddenURI));
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1; // Start the collection at 1 not 0
    }

    function refundGuaranteeActive() public view returns (bool) {
        // + 60 days in milliseconds
        return (block.timestamp < (refundStartTime + 60 days));
    }

    function refund(uint256 _tokenId) external nonReentrant {
        if (!refundGuaranteeActive()) revert RefundGuaranteeExpired();
        if (ownerOf(_tokenId) != msg.sender) revert MustOwnToken();

        // Transfer token to owner
        safeTransferFrom(msg.sender, owner(), _tokenId);

        // Refund the token owner 100% of the mint price.
        payable(msg.sender).transfer(PUBLIC_PRICE);
    }

    function publicMint(uint256 _quantity) external payable nonReentrant publicSaleIsOpen whenNotPaused {
        address _to = msg.sender;

        if (balanceOf(_to) + _quantity > mintLimitPerWallet) revert ExceededLimitPerWallet();
        if (msg.value < PUBLIC_PRICE * _quantity) revert InsufficientPaymentPerItem();

        // Mint
        _mintMummy(_to, _quantity);
    }

    // Only OWNER

    function giveawayMint(address _to, uint256 _quantity) external onlyOwner notSoldOut {
        _mintMummy(_to, _quantity);
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function setHiddenURI(string memory hiddenURI) public onlyOwner {
        hiddenTokenURI = hiddenURI;
    }

    function setPublicSale(bool _b) external onlyOwner {
        if (isPublicSaleOpen == _b) revert IdenticalState();
        isPublicSaleOpen = _b;
        emit PublicSaleEvent(_b);
    }

    function widthdraw() external onlyOwner {
        uint256 balance = address(this).balance;

        if (balance <= 0) revert NonZeroWitdraw();
        if (refundGuaranteeActive()) revert RefundGuaranteeStillActive();

        Address.sendValue(payable(owner()), balance);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    // ROYALTIES

    function royaltyInfo(uint256, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        return (address(this), (salePrice * ROYALTY_RATE) / 100);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, IERC165) returns (bool) {
        return (interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId));
    }

    // PRIVATE

    function _mintMummy(address _to, uint256 _quantity) private {
        _safeMint(_to, _quantity);
    }
}
