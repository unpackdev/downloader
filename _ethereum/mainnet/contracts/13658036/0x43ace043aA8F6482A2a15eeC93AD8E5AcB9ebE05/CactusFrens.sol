// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract CactusFrens is ERC721, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;
    uint256 public constant MAX_SUPPLY = 1500;
    uint256 public constant MINTING_COST = 0.05 ether;
    uint256 public constant MINTING_LIMIT = 18;
    address private c;
    address payable public b =
        payable(0x7bAEBf759Ac7998Eb7dB59822968B497C4A4d5e2);
    address payable public a;
    Counters.Counter private _tokenIdCounter;
    string public baseURI;

    bool public saleOn = false;
    bool internal locked;

    modifier noReentrancy() {
        require(!locked, "No reentrancy");
        locked = true;
        _;
        locked = false;
    }

    constructor() ERC721("CactusFrens", "FREN") {
        a = payable(msg.sender);
    }

    function safeMint(address to) internal {
        _safeMint(to, _tokenIdCounter.current());
        _tokenIdCounter.increment();
    }

    function mintGiveaway(address[] memory to, uint256[] memory qty) public {
        require(
            msg.sender == owner() || msg.sender == c,
            "you need permission"
        );
        require(to.length == qty.length);
        for (uint256 i = 0; i < to.length; i++) {
            require(qty[i] <= 10, "too much");
            safeMint(to[i]);
        }
    }

    function mint() public payable noReentrancy {
        require(saleOn, "Sale not started");
        require(msg.value >= MINTING_COST, "More ETH");
        require(_tokenIdCounter.current() < (MAX_SUPPLY));
        safeMint(msg.sender);
    }

    function mint(uint256 qty) public payable noReentrancy {
        require(saleOn, "Sale not started");
        _mintBatch(msg.sender, qty);
    }

    function _mintBatch(address to, uint256 qty) internal {
        require(msg.value >= MINTING_COST * qty, "More ETH");
        require(qty <= MINTING_LIMIT, "too much");
        for (uint256 i = 0; i < qty; i++) {
            if (_tokenIdCounter.current() < (MAX_SUPPLY)) {
                safeMint(to);
            }
        }
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : tokenId.toString();
    }

    function withdraw() public onlyOwner noReentrancy {
        _withdraw();
    }

    function setb(address payable _b) public onlyOwner noReentrancy {
        b = _b;
    }

    function setc(address _c) public onlyOwner noReentrancy {
        c = _c;
    }

    function startSale(bool _turnOn) public onlyOwner {
        saleOn = _turnOn;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function _withdraw() internal {
        uint256 balance = address(this).balance;
        require(balance > 0);
        uint256 _a = balance / 2;
        uint256 _b = balance - _a;

        require(b.send(_b));
        require(a.send(_a));
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
