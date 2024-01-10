// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";

contract VenShiba is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    uint8 MAX_SUPPLY = 20;
    uint8 MAX_PER_WALLET = 1;
    uint256 PRICE = 0.01 ether;
    mapping(address => uint8) private mintBalance;

    constructor() ERC721("VenShiba", "VNS") {}

    function _baseURI() internal pure override returns (string memory) {
        return "https://nft.ven.earth/api/venShiba/metadata/";
    }

    /**
     * @dev Returns an URI for a given token ID
     */
    function tokenURI(uint256 _tokenId)
        public
        pure
        override
        returns (string memory)
    {
        return string(abi.encodePacked(_baseURI(), Strings.toString(_tokenId)));
    }

    function withdraw(address _address) public payable onlyOwner {
        payable(_address).transfer(address(this).balance);
    }

    function mint() public payable {
        require(mintBalance[msg.sender] < 1, "Only 1 per account");
        require(msg.sender == tx.origin, "no.");
        require(balanceOf(msg.sender) != MAX_PER_WALLET, "Max amount minted");
        require(msg.value == PRICE, "Price incorrect");

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        mintBalance[msg.sender] = mintBalance[msg.sender] + 1;
        _mint(address(msg.sender), tokenId);
    }

    function safeMint(address to) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}
