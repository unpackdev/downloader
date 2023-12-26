// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract FortuneCookies is ERC721, ERC721Enumerable, Ownable {

    using SafeMath for uint256;

    bool private _saleStarted;

    uint256 public constant maxSupply = 10000;
    uint256 public constant pricePerCookie = 0.01 * 10 ** 18;
    uint256 public constant maxCookiesPerTX = 20;

    string public baseURI;

    constructor() ERC721("Fortune Cookies", "FORTUNES") {
        _saleStarted = false;
    }

    modifier whenSaleStarted() {
        require(_saleStarted);
        _;
    }

    function flipSaleStarted() external onlyOwner {
        _saleStarted = !_saleStarted;
    }

    function saleStarted() public view returns(bool) {
        return _saleStarted;
    }

    function setBaseURI(string memory _URI) external onlyOwner {
        baseURI = _URI;
    }

    function _baseURI() internal view override(ERC721) returns(string memory) {
        return baseURI;
    }

    function claimTeamCookies() external onlyOwner {
        uint256 _cookieId = totalSupply();
        for (uint8 i = 0; i < 30; i++) {
            _safeMint(msg.sender, _cookieId.add(i));
        }
    }

    function mintCookies(uint256 _nbCookies) external payable whenSaleStarted {
        require(_nbCookies > 0, "Try eating at least 1 COOKIE!");
        require(_nbCookies <= maxCookiesPerTX, "You cannot eat more than 20 COOKIES at once!");
        require(totalSupply().add(_nbCookies) <= maxSupply, "Not enough COOKIES left in the jar.");
        require(_nbCookies.mul(pricePerCookie) <= msg.value, "Inconsistent amount - Cookies are valuable!");

        for (uint i = 0; i < _nbCookies; i++) {
            uint _cookieId = totalSupply();
            if (_cookieId < maxSupply) {
                _safeMint(msg.sender, _cookieId);
            }
        }
    }

    function withdraw() public onlyOwner {
        uint _balance = address(this).balance;
        payable(msg.sender).transfer(_balance);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
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