// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

import "./Ownable.sol";
import "./ERC1155Burnable.sol";
import "./ERC1155Supply.sol";

abstract contract AbstractERC1155 is
    ERC1155Supply,
    ERC1155Burnable,
    Ownable
{
    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    constructor(string memory name_, string memory symbol_) ERC1155("") {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Name of the token
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Symbol of the token
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
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
