// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";

contract Valis is ERC721, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;

    uint256 _mintPrice;
    uint256 _maxSupply;
    string _baseuri;
    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("Valis", "VLS") {
        _mintPrice = 0.025 ether;
        _maxSupply = 10000;
        _baseuri = "https://valis.world/api/nft/";
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _tokenIdCounter.current();
    }

    function maxSupply() public view returns (uint256) {
        return _maxSupply;
    }

    function mintPrice() public view returns (uint256) {
        return _mintPrice;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseuri;
    }

    function safeMint(address to) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function Mint(uint count) public payable {
        require(count > 0, "Count is Zero!");
        require(totalSupply() + count < _maxSupply, "Count is Overflow!");

        uint256 mintvalue = count * _mintPrice;
        require(msg.value >= mintvalue, "Value is Low!");

        for (uint i = 0; i < count; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _mint(msg.sender, tokenId);
        }
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _burn(uint256 tokenId) internal override(ERC721) {
        super._burn(tokenId);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        require(_exists(tokenId), "MyERC721: URI query for nonexistent token");
        return string(abi.encodePacked(_baseURI(), Strings.toString(tokenId)));
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setMintPrice(uint256 price) public onlyOwner {
        _mintPrice = price;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        _baseuri = uri;
    }

    function withdraw(
        uint256 amount,
        address to,
        address tokencontract
    ) public onlyOwner {
        require(to != address(0));
        if (tokencontract == address(0)) {
            payable(to).transfer(amount);
        } else {
            IERC20(tokencontract).transfer(to, amount);
        }
    }
}
