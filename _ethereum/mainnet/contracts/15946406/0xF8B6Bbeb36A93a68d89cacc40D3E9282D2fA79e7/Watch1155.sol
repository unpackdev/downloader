// SPDX-License-Identifier: MIT
/*
https://watchchain.com/
*/

pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./Ownable.sol";

contract Watch1155 is Ownable, ERC1155("") {
    string public name = "WatchChain";
    string public symbol = "WCN";
    uint8 public decimals = 6;

    function mint(
        address to,
        uint256 id,
        uint256 amount
    ) external onlyOwner {
        _mint(to, id, amount, "");
    }

    function setURI(string memory newuri) external onlyOwner {
        _setURI(newuri);
    }

    function burnFrom(
        address from,
        uint256 id,
        uint256 amount
    ) external onlyOwner {
        _burn(from, id, amount);
    }
}
