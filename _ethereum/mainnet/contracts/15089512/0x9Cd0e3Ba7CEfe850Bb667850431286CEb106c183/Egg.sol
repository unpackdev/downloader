//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.15;

import "./ERC1155.sol";

contract Egg is ERC1155 {
    uint256 public constant DECRYPTER = 0;
    uint256 public constant BASIC  = 1;
    uint256 public constant MYSTERIOUS  = 2;
    uint256 public constant EPIC = 3;

    string private _name = "Braination Starter Pack";
    string private _symbol = "BSP";

    constructor() ERC1155("https://gateway.pinata.cloud/ipfs/QmcGFDnGYqj7GxUfuJdwkHv8L2rJpZEjYXG7LMLnRnCvWf/{id}.json") {
        _mint(msg.sender, DECRYPTER, 3000, "");
        _mint(msg.sender, BASIC, 1000, "");
        _mint(msg.sender, MYSTERIOUS, 1000, "");
        _mint(msg.sender, EPIC, 1000, "");
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }
}