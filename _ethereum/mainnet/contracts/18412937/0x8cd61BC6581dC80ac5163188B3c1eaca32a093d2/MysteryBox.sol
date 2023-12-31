// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// import "./IERC20.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";

error InsufficientBalance();
error InvalidAddress();
error InvalidPaymentTokenAddress();
error InvalidSaleStartTime();
error InvalidSaleEndTime();
error InvalidRevealStartTime();
error QuantityExceedsMaxSupply();
error TransferFailed();

contract MysteryBox is Ownable, ReentrancyGuard, ERC721A {
    uint256 public constant MAX_SUPPLY = 7777;
    using SafeERC20 for IERC20;

    struct AirdropRecipient {
        address to;
        uint256 quantity;
    }

    string public baseTokenURI;
    uint256 public totalMinted;

    address private _treasury;

    uint256 public saleStartTime;
    uint256 public saleEndTime;

    uint256 public revealStartTime;

    mapping(address => uint256) public mintPrices;

    event Burn(address indexed account, uint256 indexed tokenId);

    constructor(
        address _usdcTokenAddress,
        uint256 _usdcMintPrice,
        address _zeniTokenAddress,
        uint256 _zeniMintPrice,
        address _treasuryAddress
    ) ERC721A("EDOCOLLECTIONNFT", "EDOCOLLECTION") {
        mintPrices[_usdcTokenAddress] = _usdcMintPrice;
        mintPrices[_zeniTokenAddress] = _zeniMintPrice;
        _treasury = _treasuryAddress;
        totalMinted = 0;
    }

    function setBaseURI(string memory newBaseTokenURI) external onlyOwner {
        baseTokenURI = newBaseTokenURI;
    }

    function airdrop(AirdropRecipient calldata recipients) external onlyOwner {
        if (recipients.quantity + totalMinted > MAX_SUPPLY) revert QuantityExceedsMaxSupply();
         _safeMint(recipients.to, recipients.quantity);
    }

    function setSaleTime(uint256 _saleStartTime, uint256 _saleEndTime) external onlyOwner {
        saleStartTime = _saleStartTime;
        saleEndTime = _saleEndTime;
    }

    function setRevealTime(uint256 _revealStartTime) external onlyOwner {
        revealStartTime = _revealStartTime;
    }

    function setMintPrice(address paymentTokenAddress, uint256 newMintPrice) external onlyOwner {
        mintPrices[paymentTokenAddress] = newMintPrice;
    }

    function mint(address paymentTokenAddress, uint256 quantity) external nonReentrant {
        if (block.timestamp < saleStartTime) revert InvalidSaleStartTime();
        if (block.timestamp > saleEndTime) revert InvalidSaleEndTime();
        if (mintPrices[paymentTokenAddress] == 0) revert InvalidPaymentTokenAddress();
        if (quantity + totalMinted > MAX_SUPPLY) revert QuantityExceedsMaxSupply();

        IERC20 paymentToken = IERC20(paymentTokenAddress);
        uint256 balance = paymentToken.balanceOf(msg.sender);

        if (balance < mintPrices[paymentTokenAddress] * quantity) revert InsufficientBalance();

        paymentToken.safeTransferFrom(msg.sender, _treasury, mintPrices[paymentTokenAddress] * quantity);

       _safeMint(msg.sender, quantity);
    }

    function burn(uint256 tokenId) external {
        if (msg.sender != ownerOf(tokenId)) revert InvalidAddress();
        if (block.timestamp < revealStartTime) revert InvalidRevealStartTime();
        _burn(tokenId);

        emit Burn(msg.sender, tokenId);
    }

    function _safeMint(address to, uint256 quantity) internal virtual override {
        super._safeMint(to, quantity);

        unchecked {
            totalMinted += quantity;
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}
