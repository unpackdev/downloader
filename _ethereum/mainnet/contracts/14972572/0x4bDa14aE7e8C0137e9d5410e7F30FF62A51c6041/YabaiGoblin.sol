// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ERC721A.sol";

contract YabaiGoblin is Ownable, ERC721A {

    event SetBaseURI(string uri);
    event SetMinter(address minter);

    string internal __baseURI;
    address public minter;

    constructor() ERC721A("YABAI GOBLIN", "YAGO") {
        __baseURI = "https://storage.googleapis.com/klubs/contents/yabai-goblin/json/";
    }

    function _baseURI() internal view override returns (string memory) {
        return __baseURI;
    }

    function setBaseURI(string calldata uri) external onlyOwner {
        __baseURI = uri;
        emit SetBaseURI(uri);
    }

    function setMinter(address _minter) external onlyOwner {
        minter = _minter;
        emit SetMinter(_minter);
    }

    function mint(address to, uint256 quantity) external {
        require(msg.sender == minter);
        _safeMint(to, quantity);
    }
}
