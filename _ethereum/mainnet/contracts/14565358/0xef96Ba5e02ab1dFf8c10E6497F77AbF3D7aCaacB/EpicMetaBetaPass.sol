//SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "./Counters.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";

contract EpicMetaBetaPass is ERC721Enumerable, ERC721Burnable, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;

    uint public constant MAX_SUPPLY = 1000;
    string public baseTokenURI;

    constructor(string memory baseURI) ERC721("EpicMetaBetaPass", "EMBP") {
        setBaseURI(baseURI);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function _mintSingleNFT() public {
        uint newTokenID = _tokenIds.current();
        require(newTokenID.add(1) <= MAX_SUPPLY, "Not enough NFTs left!");
        _safeMint(msg.sender, newTokenID + 1);
        _tokenIds.increment();
    }

    function burnToken(uint256 tokenId) external {
        require(_exists(tokenId), "token not found");
        require(
            msg.sender == ERC721.ownerOf(tokenId),
            "must be owner of token"
        );
        _burn(tokenId);
    }

    // The following functions are overrides required by Solidity.
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