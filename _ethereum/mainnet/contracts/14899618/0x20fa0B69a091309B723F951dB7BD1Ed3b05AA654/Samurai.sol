// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./ERC721AUpgradeable.sol";

contract Samurai is
    OwnableUpgradeable,
    ERC721AUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address public constant WRLD = 0xD5d86FC8d5C0Ea1aC1Ac5Dfab6E529c9967a45E9;
    uint256 public itemPrice;
    uint256 public itemPriceWRLD;
    uint256 public publicSaleStartTime;
    uint256 public walletLimit;
    string private _baseTokenURI;
    bool public isSaleActive;

    mapping(address => uint256) public walletMinted;

    modifier whenPublicMintActive() {
        require(
            isSaleActive && block.timestamp >= publicSaleStartTime,
            "Public mint hasn't started yet"
        );
        _;
    }

    function initialize() external initializer {
        __ERC721A_init();
        __Ownable_init();
        __ReentrancyGuard_init();
        walletLimit = 5;
        itemPrice = 0.069 ether;
        itemPriceWRLD = 2500 ether;
        publicSaleStartTime = 1654365600;
        isSaleActive = true;
    }

    function _beforeMint(uint256 _howMany) private view {
        require(_howMany > 0, "Must mint at least one");
        uint256 supply = totalSupply();
        require(
            supply + _howMany <= collectionSize,
            "Minting would exceed max supply"
        );
    }

    function mintTo(address to, uint256 _howMany)
        external
        payable
        whenPublicMintActive
    {
        // Optional Restriction
        require(
            _msgSender() == 0xdAb1a1854214684acE522439684a145E62505233,
            "This function is for Crossmint only."
        );
        require(
            itemPrice * _howMany <= msg.value,
            "Ether value sent is not correct"
        );
        _mintToken(to, _howMany);
    }

    function publicMint(uint256 _howMany)
        external
        payable
        whenPublicMintActive
    {
        require(
            itemPrice * _howMany <= msg.value,
            "Ether value sent is not correct"
        );
        require(
            walletMinted[_msgSender()] + _howMany <= walletLimit,
            "Wallet limit exceeds"
        );
        walletMinted[_msgSender()] += _howMany;
        _mintToken(_msgSender(), _howMany);
    }

    function mintByWRLD(uint256 _howMany, uint256 _amount)
        external
        whenPublicMintActive
    {
        require(
            itemPriceWRLD * _howMany <= _amount,
            "WRLD value sent is not correct"
        );
        require(
            walletMinted[_msgSender()] + _howMany <= walletLimit,
            "Wallet limit exceeds"
        );
        walletMinted[_msgSender()] += _howMany;
        IERC20Upgradeable(WRLD).safeTransferFrom(
            _msgSender(),
            address(this),
            _amount
        );
        _mintToken(_msgSender(), _howMany);
    }

    function _mintToken(address _to, uint256 _howMany) internal nonReentrant {
        _beforeMint(_howMany);
        _safeMint(_to, _howMany);
    }

    function startSale() external onlyOwner {
        isSaleActive = true;
    }

    function stopSale() external onlyOwner {
        isSaleActive = false;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function withdrawToken() external onlyOwner nonReentrant {
        IERC20Upgradeable(WRLD).safeTransfer(
            _msgSender(),
            IERC20Upgradeable(WRLD).balanceOf(address(this))
        );
    }

    function setOwnersExplicit(uint256 quantity)
        external
        onlyOwner
        nonReentrant
    {
        _setOwnersExplicit(quantity);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function exists(uint256 _tokenId) external view returns (bool) {
        return _exists(_tokenId);
    }

    function getOwnershipData(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return ownershipOf(tokenId);
    }

    uint256[44] private __gap;
}
