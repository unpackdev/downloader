//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./Initializable.sol";
import "./StringsUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./ProxyableUpgradeable.sol";
import "./WithdrawableUpgradeable.sol";
import "./ERC721BaseUpgradeable.sol";

// Nfts are purchaseable with Native

contract OxBulls is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    ProxyableUpgradeable,
    WithdrawableUpgradeable,
    ERC721BaseUpgradeable
{
    using StringsUpgradeable for uint256;

    address public artist; // artist address
    address public treasury; // address to receive payments

    bool public saleActive; // is sale active

    uint256 public maxPerWallet; // max nfts per wallet
    uint256 public maxSupply; // max nfts to be minted
    uint256 public paymentAmount; // price per nft

    event Buy(address indexed sender, uint256 indexed amount);
    event WithdrawRevenue(address indexed sender, uint256 indexed amount);

    error ExceedsMaxPerWallet();
    error ExceedsMaxSupply();
    error InsufficientPayment(uint256 sent, uint256 required);
    error SaleIsClosed();
    error TransferFailed();
    error ZeroAddress();

    modifier saleIsActive() {
        if (!saleActive) revert SaleIsClosed();
        _;
    }

    function initialize(
        string memory name,
        string memory symbol,
        address _treasury,
        uint256 _paymentAmount,
        uint256 _maxPerWallet,
        address _artist,
        string calldata tokenBaseURI
    ) public initializer notZeroAddress(_treasury) {
        treasury = _treasury;
        paymentAmount = _paymentAmount;
        _tokenBaseURI = tokenBaseURI;
        artist = _artist;
        OwnableUpgradeable.__Ownable_init();
        ERC721BaseUpgradeable.__ERC721BaseUpgradeable_init(name, symbol);
        maxSupply = 530;
        maxPerWallet = _maxPerWallet;
    }

    receive() external payable onlyOwner {}

    function buy(uint256 amount) external payable saleIsActive nonReentrant {
        if (totalSupply + amount > maxSupply) revert ExceedsMaxSupply();
        if (balanceOf(_msgSender()) + amount > maxPerWallet)
            revert ExceedsMaxPerWallet();
        uint256 requiredAmount = paymentAmount * amount;
        _checkSufficientNativePayment(requiredAmount);
        _sendToArtist(requiredAmount);
        emit Buy(_msgSender(), amount);
        _batchMint(_msgSender(), amount);
    }

    function burn(uint32 tokenId) external {
        _burn(tokenId);
    }

    function buyOne() external payable saleIsActive nonReentrant {
        if (totalSupply + 1 > maxSupply) revert ExceedsMaxSupply();
        if (balanceOf(_msgSender()) == maxPerWallet)
            revert ExceedsMaxPerWallet();
        _checkSufficientNativePayment(paymentAmount);
        _sendToArtist(paymentAmount);
        emit Buy(_msgSender(), 1);
        _mint(_msgSender());
    }

    function mint(address receiver) external onlyProxy {
        _mint(receiver);
    }

    function mint(address[] calldata receivers) external onlyProxy {
        for (uint256 i; i < receivers.length; ) {
            _mint(receivers[i]);
            unchecked {
                ++i;
            }
        }
    }

    function setArtist(
        address _artist
    ) external onlyOwner notZeroAddress(_artist) {
        artist = _artist;
    }

    function setMaxPerWallet(uint256 value) external onlyOwner {
        maxPerWallet = value;
    }

    function setMaxSupply(uint256 value) external onlyOwner {
        maxSupply = value;
    }

    function setPaymentAmount(uint256 value) external onlyOwner {
        paymentAmount = value;
    }

    function setSaleActive(bool value) external onlyOwner {
        saleActive = value;
    }

    function setTreasury(
        address _treasury
    ) external onlyOwner notZeroAddress(_treasury) {
        treasury = _treasury;
    }

    function tokenURI(
        uint256 tokenId
    ) external view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert NonexistentToken(tokenId);
        return string(abi.encodePacked(_tokenBaseURI, tokenId.toString(), ".json"));
    }

    function updateConfig(
        bool _saleActive,
        string calldata tokenBaseURI //,
    ) external onlyOwner {
        saleActive = _saleActive;
        _tokenBaseURI = tokenBaseURI;
    }

    function withdrawNativeToTreasury() external onlyOwner {
        _withdrawNativeToTreasury(treasury);
    }

    function withdrawTokensToTreasury(address tokenAddress) external onlyOwner {
        _withdrawTokensToTreasury(treasury, tokenAddress);
    }

    function batchSafeTransferFromSmallInt(
        address from,
        address to,
        uint32[] memory tokenIds,
        bytes memory data
    ) public {
        for (uint32 i; i < tokenIds.length; ) {
            safeTransferFrom(from, to, tokenIds[i], data);
            unchecked {
                ++i;
            }
        }
    }

    function batchTransferFromSmallInt(
        address from,
        address to,
        uint32[] memory tokenIds
    ) public {
        for (uint32 i; i < tokenIds.length; ) {
            transferFrom(from, to, tokenIds[i]);
            unchecked {
                ++i;
            }
        }
    }

    function isApprovedForAll(
        address _owner,
        address operator
    ) public view override returns (bool) {
        return
            proxyToApproved[operator] ||
            super.isApprovedForAll(_owner, operator);
    }

    function _checkSufficientNativePayment(uint256 amount) private view {
        if (amount != msg.value)
            revert InsufficientPayment({sent: msg.value, required: amount});
    }

    function _sendToArtist(uint256 amount) private {
        amount = amount / 5;
        (bool success, ) = artist.call{value: amount}("");
        if (!success) revert TransferFailed();
    }
}
