// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./EnumerableSet.sol";

contract YakuzaCatsSociety is ERC721Enumerable, ReentrancyGuard, Ownable {
    using Strings for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;
    uint256 public constant MAX_YAKUZA = 8930;
    string private _metadata;
    bool private _startPreSale = false;
    bool private _startSale = false;

    address public constant YaMEOWguchi = 0xA79C5f7c1E9dB5C4fbAfa8b25CE88515c9e7Fc92;
    address public constant SuMEOWshi = 0xEb21673dD5d3851F26d15b090a798Cc4F7A384E7;

    EnumerableSet.AddressSet private _allowList;
    mapping(address => uint256) private _preSaleCounts;

    constructor() ERC721("Yakuza Cats Society", "YCS") {
        for (uint256 i; i < 30; i++) {
            if (i % 2 == 0) {
                _safeMint(YaMEOWguchi, i);
            } else {
                _safeMint(SuMEOWshi, i);
            }
        }
    }

    function price() public pure returns (uint256) {
        return 0.0893 ether;
    }

    function allowList() public view returns (address[] memory) {
        return _allowList.values();
    }

    function addAllowList(address[] memory lists, uint256 limit)
        public
        onlyOwner
    {
        for (uint256 i; i < lists.length; i++) {
            if (!_allowList.contains(lists[i])) {
                _allowList.add(lists[i]);
                _preSaleCounts[lists[i]] = limit;
            }
        }
    }

    function getPreSaleCount(address owner) public view returns (uint256) {
        return _preSaleCounts[owner];
    }

    function preSale(uint256 count) public payable nonReentrant {
        uint256 minted = totalSupply();
        require(_startPreSale, "pre sale is currently closed");
        require(count <= 2, "can mint up to 2");
        require(_allowList.contains(msg.sender), "you are not on the whitelist");
        require(_preSaleCounts[msg.sender] - count >= 0, "exceeded allowed amount");
        require(msg.value >= price() * count, "insufficient ether");
        require(minted + count < MAX_YAKUZA, "total supply is 8930");

        _preSaleCounts[msg.sender] -= count;
        for (uint256 i; i < count; i++) {
            _safeMint(msg.sender, minted + i);
        }

        _distribute();
    }

    function sale(uint256 count) public payable nonReentrant {
        uint256 minted = totalSupply();
        require(_startSale, "sale is currently closed");
        require(count <= 20, "can mint up to 20");
        require(msg.value >= price() * count, "insufficient ether");
        require(minted + count < MAX_YAKUZA, "total supply is 8930");

        for (uint256 i; i < count; i++) {
            _safeMint(msg.sender, minted + i);
        }

        _distribute();
    }

    function tokensOfOwner(address owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 count = balanceOf(owner);
        uint256[] memory ids = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            ids[i] = tokenOfOwnerByIndex(owner, i);
        }
        return ids;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return
            bytes(_metadata).length > 0
                ? string(abi.encodePacked(_metadata, tokenId.toString()))
                : "ipfs://QmdfVPU3VuPDywcAmUuhwghSS3BrvuL8tqKtc1rTS1c3kg";
    }

    function updateMetadata(string memory metadata) public onlyOwner {
        _metadata = metadata;
    }

    function _distribute() internal {
        uint256 value = address(this).balance / 2;
        payable(address(YaMEOWguchi)).transfer(value);
        payable(address(SuMEOWshi)).transfer(value);
    }

    function setStartPreSale(bool startPreSale_) public onlyOwner {
        _startPreSale = startPreSale_;
    }

    function setStartSale(bool startSale_) public onlyOwner {
        _startSale = startSale_;
    }

    function startPreSale() public view returns(bool){
        return _startPreSale;
    }

    function startSale() public view returns(bool){
        return _startSale;
    }
}
