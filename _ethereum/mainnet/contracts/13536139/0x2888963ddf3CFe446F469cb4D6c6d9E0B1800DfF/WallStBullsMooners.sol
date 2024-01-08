//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract WallStBullsMooners is ERC721Enumerable, Ownable {
    string public baseURI;
    bool public baseURIFinal;

    event BaseURIChanged(string baseURI);

    constructor(string memory _initialBaseURI) ERC721("Wall Street Bulls Mooners", "WSBM")  {
        baseURI = _initialBaseURI;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        require(!baseURIFinal, "Base URL is unchangeable");
        baseURI = _newBaseURI;
        emit BaseURIChanged(baseURI);
    }

    function finalizeBaseURI() external onlyOwner {
        baseURIFinal = true;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function mint(uint256 tokenId) public onlyOwner(){
        _safeMint(msg.sender, tokenId);
    }

}
