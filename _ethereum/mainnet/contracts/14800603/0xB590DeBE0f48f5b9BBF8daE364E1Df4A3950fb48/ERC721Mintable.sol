// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ERC721A.sol";

abstract contract ERC721Mintable is ERC721A, Ownable {
    address public minter;

    constructor(address minter_) {
        minter = minter_;
    }

    function mint(address to, uint256 quantity) external onlyMinter {
        _mint(to, quantity);
    }

    function multiMint(address[] memory to) external onlyMinter {
        _multiMint(to);
    }

    function setMinter(address minter_) external onlyOwner {
        minter = minter_;
    }

    modifier onlyMinter() {
        require(msg.sender == minter, "Caller is not minter");
        _;
    }
}
