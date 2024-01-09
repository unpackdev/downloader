// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Strings.sol";
import "./ERC721.sol";

contract IndiscreetUnits is ERC721, Ownable {
    uint16 private _tokenTokenIdMax = 266;
    string private _baseURIValue = "ipfs://QmW4NoKzKDJPN4apEhEAFGgyyGJdit9UwDrutNbf6PPxav/";
    uint256 private _price = 0.1 ether;
    uint16 private _maxTokensPerWallet = 3;
    bool private _paused = true;

    constructor() ERC721("Indiscreet Units", "IU") {}

    function setTokenIdMax(uint16 newTokenIdMax) external onlyOwner {
        _tokenTokenIdMax = newTokenIdMax;
    }

    function setMaxTokensPerWallet(uint16 newMaxTokensPerWallet) external onlyOwner {
        _maxTokensPerWallet = newMaxTokensPerWallet;
    }

    function setPaused(bool newPaused) external onlyOwner {
        _paused = newPaused;
    }
    function mint(address recipient, uint16 tokenId)
        external
        payable
    {
        require(!_paused, "Contract not activated yet");
        require(balanceOf(recipient) < _maxTokensPerWallet , "Max. tokens per wallet exceeded");
        require(msg.value >= _price, "You did not send enough ether");
        require(tokenId <= _tokenTokenIdMax, "TokenId exceeds maximum");
        _safeMint(recipient, tokenId);
    }

    function adminMint(address recipient, uint16 tokenId) external onlyOwner {
        _safeMint(recipient, tokenId);
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        _price = newPrice;    
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseURIValue;
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        _baseURIValue = newBaseURI;
    }
}
