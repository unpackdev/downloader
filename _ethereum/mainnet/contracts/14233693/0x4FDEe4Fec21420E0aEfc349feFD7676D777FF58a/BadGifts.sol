// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}


contract BadGifts is ERC721, Ownable {
    using Counters for Counters.Counter;

    struct GiftMessage{
        string message;
        bool changeable;
    }

    mapping(uint256 => GiftMessage) private _giftMessages;

    uint256 public mintPrice = 20000000000000000;
    uint256 public maxSupply = 6969;
    uint256 public maxMint = 10;
    Counters.Counter private _tokenIdCounter;
    string private _uri = "https://api.badgifts.wtf/";
    address private proxyRegistryAddress;

    constructor(
         address _proxyRegistryAddress
    ) ERC721("Bad Gifts", "BG") {
        _tokenIdCounter.increment();
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    function _baseURI() internal view override returns (string memory) {
        return _uri;
    }

    function _setBaseURI(string memory newUri) public onlyOwner {
        require(bytes(newUri).length > 0, "New URI can't be empty");
        _uri = newUri;
    }

    function mintWithMessage(
        address to,
        uint256 amount,
        string memory message
    ) public payable {
        require(msg.value == mintPrice * amount, "Invalid price");
        require(amount <= maxMint && amount > 0, "Invalid amount");
        require(validMessage(message), "Invalid message. MAX 25 chars");
        mint(to, amount, message);
    }

    function mintOwner(
        address to,
        uint256 amount,
        string memory message
    ) public onlyOwner {
        require(validMessage(message), "Invalid message. MAX 25 chars");
        mint(to, amount, message);
    }

    function validMessage(string memory message) private pure returns (bool) {
        uint256 length = bytes(message).length;
        return length < 25 && length > 0;
    }

    function mint(
        address to,
        uint256 amount,
        string memory message
    ) private {
        uint256 supply = totalSupply();
        uint256 afterSupply = supply + amount;
        require(afterSupply <= maxSupply, "Max supply would be reached");

        for (uint256 i; i < amount; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(to, tokenId);
            _giftMessages[tokenId].message = message;
            _giftMessages[tokenId].changeable = true;
        }
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function getGiftMessage(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        return _giftMessages[tokenId].message;
    }

    function setGiftMessage(uint256 tokenId, string memory newMessage) public {
        require(ownerOf(tokenId) == msg.sender, "Not the owner");
        require(
            _giftMessages[tokenId].changeable == true,
            "Can't change message"
        );
        _giftMessages[tokenId].changeable = false;
        _giftMessages[tokenId].message = newMessage;
    }
    
    function canChangeMessage(uint256 tokenId) public view returns (bool) {
        return _giftMessages[tokenId].changeable;
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        _giftMessages[tokenId].changeable = true;
        super.safeTransferFrom(from, to, tokenId);
    }
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        _giftMessages[tokenId].changeable = true;
        super.transferFrom(from, to, tokenId);
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        override
        public
        view
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    function setProxyAddress(address _proxyRegistryAddress) public onlyOwner{
        proxyRegistryAddress = _proxyRegistryAddress;
    }


    function totalSupply() public view returns (uint256) {
        return _tokenIdCounter.current() - 1;
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
