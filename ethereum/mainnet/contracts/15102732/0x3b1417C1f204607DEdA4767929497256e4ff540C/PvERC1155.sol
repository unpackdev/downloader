// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./Ownable.sol";
import "./ERC1155Burnable.sol";
import "./ERC1155Supply.sol";

contract PvERC1155 is ERC1155Supply, ERC1155Burnable, Ownable {
    
    string public name_;
    string public symbol_;   
 
    constructor(string memory _name, string memory _symbol, string memory _uri) ERC1155(_uri) {
        name_ = _name;
        symbol_ = _symbol;
    }

    function name() public view returns (string memory) {
        return name_;
    }

    function symbol() public view returns (string memory) {
        return symbol_;
    }          

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    } 
}