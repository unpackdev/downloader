// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./ERC721Upgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./ERC721URIStorageUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./CountersUpgradeable.sol";
import "./AddressUpgradeable.sol";

contract BadgeToken is
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    ERC721URIStorageUpgradeable,
    PausableUpgradeable,
    OwnableUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private _tokenIdCounter;

    string private _baseURIextended;

    /**
     * badge unit price, 0.0003 BNB
     */
    uint256 public badgePrice;

    event SetBadgePrice(uint256 badgePrice);
    event WithDraw(address recipient, uint256 amount);

    // constructor() ERC721Upgradeable("BadgeToken", "KBT") {}

    function initialize() public initializer {
        __Ownable_init();
        __Ownable_init();
        __ERC721_init("BadgeToken", "KBT");
        badgePrice = 5 * 1e16;
        safeMint();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function safeMint() public payable whenNotPaused {
        // uint256 payAmount = msg.value;
        // require(payAmount == badgePrice, "payAmount error");

        _realMint();
    }

    function _realMint() internal {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(_msgSender(), tokenId);
    }

    function safeMultiMint(uint8 _number) public payable whenNotPaused {
        uint256 payAmount = msg.value;
        require(payAmount == badgePrice * _number, "payAmount error");

        require(_number <= 50, "number too large");
        for(uint8 i = 0;i < _number; i++) {
            _realMint();
        }
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    {
        super._burn(tokenId);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseURIextended;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setBadgePrice(uint256 _badgePrice) public onlyOwner {
        badgePrice = _badgePrice;
        emit SetBadgePrice(_badgePrice);
    }

    function withdraw(uint256 amount) public onlyOwner {
        AddressUpgradeable.sendValue(payable(_msgSender()), amount);

        emit WithDraw(_msgSender(), amount);
    }

    function balance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev The contract should be able to receive Eth.
     */
    receive() external payable virtual {}
}
