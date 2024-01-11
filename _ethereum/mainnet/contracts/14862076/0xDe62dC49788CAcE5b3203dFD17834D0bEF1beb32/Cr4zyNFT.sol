// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC721A.sol";
import "./ERC721ABurnable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC2981.sol";
import "./Address.sol";
import "./Strings.sol";

import "./ContextMixin.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract Cr4zyNFT is
    ERC721A,
    ERC721ABurnable,
    IERC2981,
    ContextMixin,
    ReentrancyGuard,
    Ownable
{


    constructor(string memory customBaseURI_, address proxyRegistryAddress_)
        ERC721A("Cr4zyNFT", "CRZY")
    {
        customBaseURI = customBaseURI_;

        proxyRegistryAddress = proxyRegistryAddress_;
    }

    /** MINTING **/

    uint256 public constant PRICE = 150000000000000000;


    function mint(uint256 quantity) public payable nonReentrant {
        require(saleIsActive, "Sale not active");

        require(msg.value >= PRICE, "Insufficient payment, 0.15 ETH per item");

        _mint(msg.sender, quantity);
    }

    function crzy_mint(uint256 quantity) public nonReentrant onlyOwner {
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        assert(
            address(proxyRegistry.proxies(owner())) == _msgSender() ||
                owner() == _msgSender()
        );

        _mint(msg.sender, quantity);
    }

    /** ACTIVATION **/

    bool public saleIsActive = false;

    function setSaleIsActive(bool saleIsActive_) external onlyOwner {
        saleIsActive = saleIsActive_;
    }

    /** URI HANDLING **/

    string private customBaseURI;

    mapping(uint256 => string) private tokenURIMap;

    function setTokenURI(uint256 tokenId, string memory tokenURI_)
        external
        onlyOwner
    {
        tokenURIMap[tokenId] = tokenURI_;
    }

    function setBaseURI(string memory customBaseURI_) external onlyOwner {
        customBaseURI = customBaseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return customBaseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        string memory tokenURI_ = tokenURIMap[tokenId];

        if (bytes(tokenURI_).length > 0) {
            return tokenURI_;
        }

        return string(abi.encodePacked(super.tokenURI(tokenId), ".json"));
    }

    function setURICat(
        uint256 tokenStart,
        uint256 tokenEnd,
        string memory catURI_
    ) external onlyOwner {
        for (uint256 i = tokenStart; i <= tokenEnd; i++) {
            string memory __index = Strings.toString(i);
            tokenURIMap[i] = string(
                abi.encodePacked(catURI_, __index, ".json")
            );
        }
    }

    /** PAYOUT **/

    function withdraw() public nonReentrant onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(owner()), balance);
    }

    /** ROYALTIES **/

    function royaltyInfo(uint256, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        return (address(this), (salePrice * 500) / 10000);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, IERC165)
        returns (bool)
    {
        return (interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId));
    }

    /** PROXY REGISTRY **/

    address private immutable proxyRegistryAddress;

    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);

        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    function _msgSender() internal view override returns (address sender) {
        return ContextMixin.msgSender();
    }
}
