// contracts/Cheers.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Counters.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";

contract Cheers is ERC721Enumerable, Ownable {

    using Counters for Counters.Counter;
    using Strings for uint256;

    uint256 public constant MINT_PRICE = 0.02 ether;
    uint16 public constant MINT_MAX = 500;

    Counters.Counter private _tokenIds;

    string private _baseURIpath = "";

    constructor() ERC721("Cheers", "CHRS") {

    }

    function purchase(uint16 _number) public payable
    {
        require(_number > 0, "Minimum purchase is 1 item");
        require(msg.value >= (MINT_PRICE * _number), "Must send at least MINT_PRICE per one item");
        require((_tokenIds.current() + _number) <= MINT_MAX, "Mint maximum is reached");

        for (uint16 i = 0; i < _number; i++) {
            _tokenIds.increment();
            _safeMint(msg.sender, _tokenIds.current());
        }

        payable(owner()).transfer(msg.value);
    }

    function _setBaseURI(string memory _newURI) public onlyOwner {
        _baseURIpath = _newURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseURIpath;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        string memory baseURI = _baseURI();

        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
            : "ipfs://QmfVs7mEWnW3ZiAsidranhNHwpG1983tA8Ju1hwaMykGad";
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable) returns (bool)
    {
        return
            ERC721Enumerable.supportsInterface(interfaceId) ||
            ERC721.supportsInterface(interfaceId);
    }
}
