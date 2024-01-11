//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract HydrowAlexEchoCollab is ERC721Enumerable, Ownable {

    uint256 public maxSupply;
    string private _tokenBaseURI;

    event SetTokenBaseURI(string indexed baseTokenURI);

    constructor(string memory name, string memory symbol, uint256 _maxSupply) ERC721(name, symbol) {
        maxSupply = _maxSupply;
    }

    function setTokenBaseURI(string memory baseURI) external onlyOwner {
        _tokenBaseURI = baseURI;
        emit SetTokenBaseURI(_tokenBaseURI);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _tokenBaseURI;
    }

    function _mintToken(address addr, uint256 amount) internal returns (bool) {
        for (uint256 i; i < amount; i++) {
            uint256 tokenIndex = totalSupply();
            if (tokenIndex < maxSupply) _safeMint(addr, tokenIndex);
        }
        return true;
    }

    function airdrop(address[] memory addresses, uint256 amount)
        external
        onlyOwner
    {
        require(
            totalSupply() + amount <= maxSupply,
            "Exceeds max supply limit."
        );

        for (uint256 i; i < addresses.length; i++) {
            _mintToken(addresses[i], amount);
        }
    }
}