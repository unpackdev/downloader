// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./ERC1155Burnable.sol";

contract AuditNFTs is ERC1155, Ownable, ERC1155Burnable {

    // Contract name
    string public name;
    // Contract symbol
    string public symbol;

    constructor(string memory _name, string memory _symbol, string memory _uri) ERC1155(_uri) {
        name = _name;
        symbol = _symbol;
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data)
        public
        onlyOwner
    {
        _mint(account, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        onlyOwner
    {
        _mintBatch(to, ids, amounts, data);
    }
}
