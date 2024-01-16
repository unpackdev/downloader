// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ERC721A.sol";

contract QuraniVerse is ERC721A, Ownable {

    uint256 public maxSupply = 2172;

    string private _baseTokenURI;

    event minted(address indexed _to);

    constructor(string memory baseURI_) ERC721A("QuraniVerse", "QVT") {
        _baseTokenURI = baseURI_;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseTokenURI = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function mintToAddress(address _address, uint256 n) external onlyOwner {
        _safeMint(_address, n);
    }

    function updateMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
    function burn(uint256 tokenId) public virtual onlyOwner {
        _burn(tokenId);
    }
}
