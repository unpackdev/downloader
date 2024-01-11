// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./SafeMath.sol";

contract MocMasterCard is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter public _nextTokenId;
    string public baseTokenURI;

    uint256 public maxSupply = 1000;

    constructor() ERC721("MOC Master Card", "MOC") {
        _nextTokenId.increment();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseTokenURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function getMaxSupply() public view virtual returns (uint256) {
        return maxSupply;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }

    function adminMintTo(address _to) public onlyOwner {
        uint256 currentTokenId = _nextTokenId.current();
        _nextTokenId.increment();
        require(currentTokenId <= maxSupply, "Max supply reached");
        _safeMint(_to, currentTokenId);
    }

    function tokenListOfOwner(address _owner)
        public
        view
        virtual
        onlyOwner
        returns (uint256[] memory)
    {
        uint256 balance = ERC721.balanceOf(_owner);
        uint256[] memory list = new uint256[](balance);
        for (uint256 i; i < balance; i++) {
            list[i] = ERC721Enumerable.tokenOfOwnerByIndex(_owner, i);
        }
        return list;
    }

    function tokenList()
        public
        view
        virtual
        onlyOwner
        returns (uint256[] memory, address[] memory)
    {
        uint256 total = ERC721Enumerable.totalSupply();
        address[] memory _addressList = new address[](total);
        uint256[] memory _tokenList = new uint256[](total);
        for (uint256 i; i < total; i++) {
            uint256 token = ERC721Enumerable.tokenByIndex(i);
            _tokenList[i] = token;
            _addressList[i] = ERC721.ownerOf(token);
        }
        return (_tokenList, _addressList);
    }
}
