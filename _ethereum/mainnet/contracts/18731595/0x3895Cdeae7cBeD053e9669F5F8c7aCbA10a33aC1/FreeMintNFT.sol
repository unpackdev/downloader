// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/*
   88b          d88   888888888888      d888888b             d8b          88b          d88          d8b          88b        888
   888b       d8888   888             d88P    Y88b          d888b         888b       d8888         d888b         8888b      888
   8888b     d88888   888            d88P      Y88         d8P Y8b        8888b     d88888        d8P Y8b        888Y8b     888
   888 Y8b d8P  888   88888888888    888                  d8P   Y8b       888 Y8b d8P  888       d8P   Y8b       888  Y8b   888
   888   Y8P    888   888            Y88b    888888      d888888888b      888   Y8P    888      d888888888b      888    Y8b 888
   888          888   888             Y88b    d8888     d8P       Y8b     888          888     d8P       Y8b     888      Y8888
   888          888   888888888888      Y88888P  88   88888       88888   888          888   88888       88888   888        Y88
  

                     8888888   8888888           8888888888b      8888888   8888888     8888888   888888888888
                        Y8b     d8P              888     Y88b       888        Y8b       d8P      888
                          Y8b d8P                888      Y88b      888         Y8b     d8P       888
                            888                  888       8888     888          Y8b   d8P        88888888888
                          d8P Y8b                888      d88P      888           Y8b d8P         888
                        d8P     Y8b              888     d88P       888            Y888P          888
                     8888888   8888888           8888888888P      8888888           Y8P           888888888888
  
  
                                          88b        888   8888888888888   888888888888888
                                          8888b      888   888                   888
                                          888Y8b     888   888                   888
                                          888  Y8b   888   888888888             888
                                          888    Y8b 888   888                   888
                                          888      Y8888   888                   888
                                          888        Y88   888                   888
*/

import "./ERC721.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

error InvalidTokenId();
error NotOnSale();

contract FreeMintNFT is Ownable, ERC721, ReentrancyGuard {
    string private baseURI_;
    bool private _isOnSale;
    uint256 private _nextID;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory baseURI
    ) ERC721(_name, _symbol) {
        baseURI_ = baseURI;
        _nextID = 1;
    }

    function startMint() external onlyOwner {
        _isOnSale = true;
    }

    function stopMint() external onlyOwner {
        _isOnSale = false;
    }

    function mint() external nonReentrant {
        if (!_isOnSale) revert NotOnSale();
        _safeMint(msg.sender, _nextID);
        _nextID++;
    }

    function editBaseURI(string calldata uri) external onlyOwner {
        baseURI_ = uri;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI_;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        if (_ownerOf(tokenId) == address(0)) revert InvalidTokenId();
        return _baseURI();
    }
}
