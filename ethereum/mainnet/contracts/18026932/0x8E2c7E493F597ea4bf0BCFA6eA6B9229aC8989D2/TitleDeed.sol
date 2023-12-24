// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./IERC721A.sol";
import "./ERC721A.sol";
import "./Address.sol";

contract TitleDeed is ERC721A {
    using Address for address;
    mapping(address => bool) private _minters;

    constructor(
        string memory name,
        string memory symbol
    ) ERC721A(name, symbol) {
        _minters[msg.sender] = true;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 0;
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://tokens.upstreet.ai/";
    }

    function setMintAllowed(address to, bool allowed) public {
        require(_minters[msg.sender]);

        _minters[to] = allowed;
    }

    function mint(address to, uint256 quantity) public {
        require(_minters[msg.sender], "Message sender is not allowed to mint");
        _mint(to, quantity);
    }
}
