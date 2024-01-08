//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract WrappedFighters is ERC721Enumerable, Ownable {
    IERC721 public fightersContract;

    string private _baseTokenURI;

    event Wrapped(uint256 indexed tokenId);
    event Unwrapped(uint256 indexed tokenId);

    constructor(IERC721 _fightersContract) ERC721("Wrapped Fighters", "wFIGHT") {
        fightersContract = _fightersContract;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseTokenURI(string memory baseTokenURI) public onlyOwner {
        _baseTokenURI = baseTokenURI;
    }

    function wrap(uint256 tokenId) public {
        fightersContract.transferFrom(_msgSender(), address(this), tokenId);
        _mint(_msgSender(), tokenId);
        emit Wrapped(tokenId);
    }

    function unwrap(uint256 tokenId) public {
        require(
            ownerOf(tokenId) == _msgSender(),
            "You do not own this Wrapped Fighter!"
        );
        fightersContract.transferFrom(address(this), _msgSender(), tokenId);
        _burn(tokenId);
        emit Unwrapped(tokenId);
    }

    function tokenIdsForOwner(address owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(owner);
        uint256[] memory result = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            result[i] = tokenOfOwnerByIndex(owner, i);
        }
        return result;
    }
}