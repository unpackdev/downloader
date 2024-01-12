// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./ERC721A.sol";
import "./Counters.sol";

// Open sea royalties requirements
import "./Ownable.sol";

// Rarible royalties requirements
import "./RoyaltiesV2Impl.sol";
import "./LibPart.sol";
import "./LibRoyaltiesV2.sol";

error DawnSamurais__TransferFailed();
error DawnSamurais__InvalidValue();
error DawnSamurais__SoldOut();
error DawnSamurais__Paused();
error DawnSamurais__MintLimitExceeded();
error DawnSamurais__InvalidTokenId(uint256 tokenId);

contract DawnSamurais is ERC721A, Ownable, RoyaltiesV2Impl {
    using Counters for Counters.Counter;

    Counters.Counter private supply;

    // Staff addresses
    address private immutable i_developer;
    address private immutable i_artists;
    address private immutable i_marketing;
    address private immutable i_manager;

    // NFT Values
    uint256 private immutable i_totalSupply;
    uint256 private s_mintPerAddress;
    string private s_baseURI;
    string private s_notRevealedURI;
    bool private s_revealed;
    bool private s_paused;
    mapping(address => uint256) private s_addressToTokenCount;
    mapping(address => bool) private s_whitelist;
    uint256 public s_mintCost;

    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a; // Mintable and LooksRare secondary sales royalties requirement

    constructor(
        uint256 totalSupply,
        uint256 mintCost,
        uint256 mintPerAddress,
        address developerAddress,
        address artistAddress,
        address marketingAddress,
        address managerAddress
    ) ERC721A("Dawn Samurais", "DWNSamurais") {
        i_developer = developerAddress;
        i_artists = artistAddress;
        i_marketing = marketingAddress;
        i_manager = managerAddress;

        i_totalSupply = totalSupply;
        s_mintCost = mintCost;
        s_mintPerAddress = mintPerAddress;
        s_baseURI = "";
        s_notRevealedURI = "";
        s_revealed = false;
        s_paused = false;
    }

    function mint() public payable returns (uint256 tokenId) {
        if (s_paused && msg.sender != owner()) {
            revert DawnSamurais__Paused();
        }

        if (supply.current() + 1 > i_totalSupply) {
            revert DawnSamurais__SoldOut();
        }

        if (
            msg.sender != owner() &&
            s_addressToTokenCount[msg.sender] >= s_mintPerAddress
        ) {
            revert DawnSamurais__MintLimitExceeded();
        }

        uint256 totalCost = s_mintCost;
        if (
            s_addressToTokenCount[msg.sender] == 0 ||
            isWhitelisted(msg.sender) ||
            msg.sender == owner()
        ) {
            totalCost = 0;
        }

        if (msg.value != totalCost) {
            revert DawnSamurais__InvalidValue();
        }

        s_addressToTokenCount[msg.sender]++;
        _mint(msg.sender, 1);
        tokenId = supply.current();
        _saveRoyalties(tokenId, LibPart.Part(payable(address(this)), 750)); // 7.5% royalty
        supply.increment();
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) {
            revert DawnSamurais__InvalidTokenId(tokenId);
        }

        if (!isRevealed()) {
            return s_notRevealedURI;
        }

        string memory currentBaseURI = getBaseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, tokenId, ".json"))
                : "";
    }

    function getTotalSupply() public view returns (uint256) {
        return i_totalSupply;
    }

    function getMintPerAddress() public view returns (uint256) {
        return s_mintPerAddress;
    }

    function getMintCost() public view returns (uint256) {
        return s_mintCost;
    }

    function getTokenCounter() public view returns (uint256) {
        return supply.current();
    }

    function getCountForAddress(address addr) public view returns (uint256) {
        return s_addressToTokenCount[addr];
    }

    function getBaseURI() public view returns (string memory) {
        return s_baseURI;
    }

    function getNotRevealedURI() public view returns (string memory) {
        return s_notRevealedURI;
    }

    function isRevealed() public view returns (bool) {
        return s_revealed;
    }

    function isWhitelisted(address addr) public view returns (bool) {
        return s_whitelist[addr];
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        LibPart.Part[] memory _royalties = royalties[_tokenId];
        if (_royalties.length > 0) {
            return (
                _royalties[0].account,
                (_salePrice * _royalties[0].value) / 10000
            );
        }
        return (address(0), 0);
    }

    // OWNER FUNCTIONS
    function addToWhitelist(address addr) public onlyOwner {
        require(!isWhitelisted(addr));
        s_whitelist[addr] = true;
    }

    function removeFromWhitelist(address addr) public onlyOwner {
        require(isWhitelisted(addr));
        s_whitelist[addr] = false;
    }

    function reveal() public onlyOwner {
        s_revealed = true;
    }

    function setPause(bool _paused) public onlyOwner {
        s_paused = _paused;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        s_baseURI = baseURI;
    }

    function setNotRevealedURI(string memory notRevealedURI) public onlyOwner {
        s_notRevealedURI = notRevealedURI;
    }

    function withdraw() public onlyOwner {
        uint256 total = address(this).balance;
        uint256 devAmount = (total * 10) / 100; // 10%
        uint256 artAmount = (total * 5) / 100; // 5%
        uint256 markAmount = (total * 20) / 100; // 20%
        uint256 manAmount = (total * 33) / 100; // 33%
        uint256 studioAmount = (total * 32) / 100; // 32%

        (bool success, ) = payable(i_developer).call{value: devAmount}("");
        if (!success) {
            revert DawnSamurais__TransferFailed();
        }

        (success, ) = payable(i_artists).call{value: artAmount}("");
        if (!success) {
            revert DawnSamurais__TransferFailed();
        }

        (success, ) = payable(i_manager).call{value: manAmount}("");
        if (!success) {
            revert DawnSamurais__TransferFailed();
        }

        (success, ) = payable(i_marketing).call{value: markAmount}("");
        if (!success) {
            revert DawnSamurais__TransferFailed();
        }

        (success, ) = payable(owner()).call{value: studioAmount}("");
        if (!success) {
            revert DawnSamurais__TransferFailed();
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A)
        returns (bool)
    {
        if (interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES) {
            return true;
        }
        if (interfaceId == _INTERFACE_ID_ERC2981) {
            return true;
        }
        return super.supportsInterface(interfaceId);
    }
}
