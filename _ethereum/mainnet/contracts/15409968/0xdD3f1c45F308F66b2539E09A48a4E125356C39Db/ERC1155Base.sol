// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./ERC1155Supply.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Base64.sol";

abstract contract ERC1155Base is
    Ownable,
    ERC1155,
    ERC1155Supply,
    ReentrancyGuard
{
    string name_;
    string symbol_;


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