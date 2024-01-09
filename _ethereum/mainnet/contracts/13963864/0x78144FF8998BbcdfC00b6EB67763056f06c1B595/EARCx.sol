pragma solidity ^0.8.0;

//SPDX-License-Identifier: MIT

import "./ERC721.sol";
import "./Ownable.sol";

contract EARCx is ERC721, Ownable {
    string private _baseTokenURI;
    uint256 private _t = 0;
    mapping(address => bool) private admins;

    constructor(string memory _api) ERC721("EARCx", "EARCx") {
        _baseTokenURI = _api;
        admins[_msgSender()] = true;
    }

    function _mint(uint256 toMint, address to) internal {
        uint256 t = _t;
        for (uint256 i = 0; i < toMint; i++) {
            _t += 1;
            _safeMint(to, t + i + 1);
        }
        delete t;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) external {
        require(admins[msg.sender], "Only admins can mint");
        _baseTokenURI = baseURI;
    }

    function reserve(uint256 toMint, address to) external {
        require(admins[msg.sender], "Only admins can mint");
        _mint(toMint, to);
    }

    function addAdmin(address addr) external onlyOwner {
        admins[addr] = true;
    }

    function removeAdmin(address addr) external onlyOwner {
        admins[addr] = false;
    }
}
