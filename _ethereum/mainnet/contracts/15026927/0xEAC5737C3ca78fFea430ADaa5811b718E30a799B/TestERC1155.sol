// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "./ERC1155.sol";

contract TestERC1155 is ERC1155("Test ERC1155") {
    
    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public {
        _mint(
            account,
            id,
            amount,
            data
        );
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public {
        _mintBatch(
            to,
            ids,
            amounts,
            data
        );
    }
}