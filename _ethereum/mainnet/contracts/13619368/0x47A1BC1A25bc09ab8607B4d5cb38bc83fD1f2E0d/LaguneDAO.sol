// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./ERC1155Burnable.sol";

contract LaguneDAO is ERC1155, Ownable, ERC1155Burnable {
    constructor()
        ERC1155("ipfs://QmZ9cr2wMjtsAUpTfLArBRWk31b1SvzPLcjyWRnXFZR4ak/{id}/metadata.json")
    {}

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function mintOwner(address account, uint256 id, uint256 amount, bytes memory data)
        public
        onlyOwner
    {
        _mint(account, id, amount, data);
    }
    
    function mintBatch(address[] memory to, uint256 id, uint8[] memory amounts, bytes memory data)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < to.length; i++) {
            mintOwner(to[i], id, amounts[i], data);
        }
    }
}