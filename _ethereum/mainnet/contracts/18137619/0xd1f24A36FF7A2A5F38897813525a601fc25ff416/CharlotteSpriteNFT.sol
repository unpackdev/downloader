
/*
Twitter: https://twitter.com/mwarerc56197
Telegram: https://t.me/mwarerc
Website: https://charlottesprite.love/
*/

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";

contract FangSpriteNFT is ERC721A, Ownable {
    string private baseTokenURIFirst;
    string private baseTokenURISecond;
    bool public flipped = false;
    uint256 public maxSupply = 10_000;
    address public token;

    error FangSpriteNFT__OnlyToken();

    modifier onlyToken() {
        if (msg.sender != token) {
            revert FangSpriteNFT__OnlyToken();
        }
        _;
    }

    constructor() ERC721A("FangSpriteNFT", "MWAR") {}

    function setBaseURIs(string calldata _baseTokenURIFirst, string calldata _baseTokenURISecond) external onlyOwner {
        baseTokenURIFirst = _baseTokenURIFirst;
        baseTokenURISecond = _baseTokenURISecond;
    }

    function setToken(address _token) external onlyOwner {
        token = _token;
    }

    function setLeader(bool _flipped) external onlyToken {
        flipped = _flipped;
    }

    function mintNFT(address to, uint256 amount) external onlyToken {
        require(totalSupply() <= maxSupply, "Limit reached");
        _mint(to, amount);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = baseTokenURIFirst;
        if (flipped) {
            baseURI = baseTokenURISecond;
        }
        return string(abi.encodePacked(baseURI, _toString(tokenId)));
    }
}
