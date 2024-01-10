// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./ERC1155.sol";
import "./EnumerableUintSet.sol";

interface IERC1155Enumerable {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a list of token IDs held by `account`.
     */
    function tokensByAccount(address account) external view returns (uint256[] memory);
}

abstract contract ERC1155Enumerable is ERC1155, IERC1155Enumerable {
    using EnumerableSet for EnumerableSet.UintSet;

    uint256 public totalSupply;
    mapping(address => EnumerableSet.UintSet) _tokensByAccount;

    function tokensByAccount(address account) external view returns (uint256[] memory) {
        return _tokensByAccount[account]._values;
    }

    // Logic adapted from https://github.com/solidstate-network/solidstate-solidity/blob/master/contracts/token/ERC1155/enumerable/ERC1155EnumerableInternal.sol
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
        if (from == to) {
            return;
        }

        EnumerableSet.UintSet storage fromTokens = _tokensByAccount[from];
        EnumerableSet.UintSet storage toTokens = _tokensByAccount[to];

        for (uint256 i; i < ids.length; ++i) {
            uint256 amount = amounts[i];
            if (amount == 0) {
                continue;
            }

            uint256 id = ids[i];
            if (from == address(0)) {
                totalSupply += amount;
            } else if (balanceOf(from, id) == amount) {
                fromTokens.remove(id);
            }

            if (to == address(0)) {
                totalSupply -= amount;
            } else if (balanceOf(to, id) == 0) {
                toTokens.add(id);
            }
        }
    }
}
