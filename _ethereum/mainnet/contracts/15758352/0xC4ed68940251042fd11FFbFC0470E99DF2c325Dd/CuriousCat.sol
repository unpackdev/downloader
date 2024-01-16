// File: contracts/CuriousCat.sol
// SPDX-License-Identifier: MIT

import "./ERC721A.sol";
import "./IERC721A.sol";

import "./Ownable.sol";
import "./Strings.sol";
import "./Address.sol";
import "./Context.sol";
import "./ReentrancyGuard.sol";

pragma solidity ^0.8.9;

contract CuriousCat is ERC721A, Ownable, ReentrancyGuard {
    using Address for address;
    using Strings for uint;
    string public baseTokenURI =
        "https://curiouscats.club/assets/collection/metadata";

    uint256 public maxSupply = 2000;
    uint256 public MAX_MINTS_PER_TX = 3;
    uint256 public PUBLIC_SALE_PRICE = .01 ether;
    uint256 public WHITELIST_SALE_PRICE = .0065 ether;

    bool public IsOglistSaleActive = false;
    bool public IsWhitelistSaleActive = false;
    bool public isPublicSaleActive = false;
    bool public saleLive = false;

    mapping(address => uint256) public whitelist;
    mapping(address => uint256) public oglist;

    constructor() ERC721A("Curious Cats", "COCO") {}

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function mint(uint256 numberOfTokens) external payable callerIsUser {
        require(saleLive, "Sale Paused");
        require(isPublicSaleActive, "Public sale is not open");
        require(
            totalSupply() + numberOfTokens <= maxSupply,
            "Maximum supply exceeded"
        );
        require(
            (PUBLIC_SALE_PRICE * numberOfTokens) <= msg.value,
            "Incorrect ETH value sent"
        );
        _safeMint(msg.sender, numberOfTokens);
    }

    function whiteListMint(uint256 numberOfTokens)
        external
        payable
        callerIsUser
    {
        require(saleLive, "Sale Paused");
        require(IsWhitelistSaleActive, "Whitelistsale not live");
        require(whitelist[msg.sender] > 0, "Not eligible for Whitelist mint");
        require(
            totalSupply() + numberOfTokens <= maxSupply,
            "Maximum supply exceeded"
        );
        require(
            whitelist[msg.sender] >= numberOfTokens,
            "Less Slots available"
        );
        require(
            (WHITELIST_SALE_PRICE * numberOfTokens) <= msg.value,
            "Incorrect ETH value sent"
        );
        whitelist[msg.sender] -= numberOfTokens;
        _safeMint(msg.sender, numberOfTokens);
    }

    function ogListMint(uint256 numberOfTokens) external payable callerIsUser {
        require(saleLive, "Sale Paused");
        require(IsOglistSaleActive, "OG List sale is not live");
        require(oglist[msg.sender] > 0, "Not eligible for OG list mint");
        require(
            totalSupply() + numberOfTokens <= maxSupply,
            "Maximum supply exceeded"
        );
        require(
            oglist[msg.sender] >= numberOfTokens,
            "Less Slots available"
        );
        oglist[msg.sender] -= numberOfTokens;
        _safeMint(msg.sender, numberOfTokens);
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function setWhitelist(address[] memory addresses, uint256[] memory numSlots)
        external
        onlyOwner
    {
        require(
            addresses.length == numSlots.length,
            "addresses does not match numSlots length"
        );
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelist[addresses[i]] = numSlots[i];
        }
    }

    function setOglist(address[] memory addresses, uint256[] memory numSlots)
        external
        onlyOwner
    {
        require(
            addresses.length == numSlots.length,
            "addresses does not match numSlots length"
        );
        for (uint256 i = 0; i < addresses.length; i++) {
            oglist[addresses[i]] = numSlots[i];
        }
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function treasuryMint(uint numberOfTokens, address user) public onlyOwner {
        require(saleLive, "Sale Paused");
        require(numberOfTokens > 0, "Invalid mint amount");
        require(
            totalSupply() + numberOfTokens <= maxSupply,
            "Maximum supply exceeded"
        );
        _safeMint(user, numberOfTokens);
    }

    function tokenURI(uint _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return
            string(
                abi.encodePacked(
                    baseTokenURI,
                    "/",
                    _tokenId.toString(),
                    ".json"
                )
            );
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setSaleLive(bool _saleLive) external onlyOwner {
        saleLive = _saleLive;
    }

    function setIsPublicSaleActive(bool _isPublicSaleActive)
        external
        onlyOwner
    {
        isPublicSaleActive = _isPublicSaleActive;
    }

    function setIsWhitelistsaleActive(bool _IsWhitelistSaleActive)
        external
        onlyOwner
    {
        IsWhitelistSaleActive = _IsWhitelistSaleActive;
    }

    function setIsOglistsaleActive(bool _IsOglistSaleActive)
        external
        onlyOwner
    {
        IsOglistSaleActive = _IsOglistSaleActive;
    }

    function setPublicSalePrice(uint256 _price) external onlyOwner {
        PUBLIC_SALE_PRICE = _price;
    }

    function setWhitelistSalePrice(uint256 _price) external onlyOwner {
        WHITELIST_SALE_PRICE = _price;
    }

    function setMaxLimitPerTransaction(uint256 _limit) external onlyOwner {
        MAX_MINTS_PER_TX = _limit;
    }

    function withdraw() public onlyOwner nonReentrant {
        Address.sendValue(payable(msg.sender), address(this).balance);
    }
}
