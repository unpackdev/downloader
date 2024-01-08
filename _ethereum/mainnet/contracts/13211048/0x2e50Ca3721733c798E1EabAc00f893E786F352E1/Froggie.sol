// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract Froggie is ERC721, ERC721Enumerable, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    // Where funds should be sent to
    address payable public payoutAddress;

    // Maximum supply of the NFT
    uint256 public maxSupply;

    // Maximum mints per transaction
    uint256 public maxPerTx;

    // Sale price
    uint256 public pricePer;

    // Is the sale enabled
    bool public sale = false;

    // baseURI for the metadata, eg ipfs://<cid>/
    string public baseURI;

    constructor(address payable _payoutAddress, uint256 _maxSupply, uint256 _maxPerTx, uint256 _pricePer, string memory _uri) ERC721("Froggies", "FROGGIE") {
        payoutAddress = _payoutAddress;
        maxSupply = _maxSupply;
        maxPerTx = _maxPerTx;
        pricePer = _pricePer;
        baseURI = _uri;
    }

    function updatePayoutAddress(address payable newPayoutAddress) public onlyOwner {
        payoutAddress = newPayoutAddress;
    }

    function updateSale(bool newState) public onlyOwner {
        sale = newState;
    }

    function updateBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    function claimBalance() public onlyOwner {
        (bool success, ) = payoutAddress.call{value: address(this).balance}("");
        require(success, "transfer failed");
    }

    function safeMint(address to, uint256 quantity) payable public {
        // Sale must be enabled
        require(sale, "Sale disabled");
        // Cannot mint zero quantity
        require(quantity != 0, "Requested quantity cannot be zero");
        // Cannot mint more than maximum per operation
        require(quantity <= maxPerTx, "Requested quantity more than maximum");
        // Transaction must have at least quantity * price (any more is considered a tip)
        require(quantity * pricePer <= msg.value, "Not enough ether sent");
        // Cannot mint more than maximum supply
        require(_tokenIdCounter.current() + quantity <= maxSupply, "Total supply will exceed limit");

        _mintQuantity(to, quantity);
    }

    function preMint(address to, uint256 quantity) public onlyOwner {
        // Sale must NOT be enabled
        require(!sale, "Sale already in progress");
        // Cannot mint zero quantity
        require(quantity != 0, "Requested quantity cannot be zero");
        // Cannot mint more than maximum supply
        require(_tokenIdCounter.current() + quantity <= maxSupply, "Total supply will exceed limit");

        _mintQuantity(to, quantity);
    }

    function _mintQuantity(address to, uint256 quantity) private {
        for (uint256 i = 0; i < quantity; i++) {
            _safeMint(to, _tokenIdCounter.current());
            _tokenIdCounter.increment();
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

}
