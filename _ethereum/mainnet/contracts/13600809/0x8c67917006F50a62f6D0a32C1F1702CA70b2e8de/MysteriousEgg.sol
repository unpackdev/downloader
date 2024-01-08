//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC1155.sol";
import "./ERC1155Burnable.sol";
import "./Ownable.sol";

contract MysteriousEgg is ERC1155, ERC1155Burnable, Ownable {

    uint16 public constant MAX_EGGS = 21;

    constructor() ERC1155("ipfs://bafkreiemd2mevngbbc7jli7ioubqa547r7dr2dgago2sjaqsjqbjpuvffa") {
        _mint(msg.sender, 0, MAX_EGGS, "");
    }

    function setURI(string memory newuri) external onlyOwner {
        _setURI(newuri);
    }

    function name() public pure returns (string memory) {
        return "Mysterious Egg";
    }

    function symbol() public pure returns (string memory) {
        return "MYSTERIOUSEGG";
    }

}