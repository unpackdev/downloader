// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ERC1155.sol";

abstract contract ERC1155Mintable is ERC1155, Ownable {
    address public minter;

    constructor(address minter_) {
        minter = minter_;
    }

    function mint(
        address to,
        uint256 id,
        uint256 amount
    ) external onlyMinter {
        _mint(to, id, amount, "");
    }

    function setMinter(address minter_) external onlyOwner {
        minter = minter_;
    }

    modifier onlyMinter() {
        require(msg.sender == minter, "Caller is not minter");
        _;
    }
}
