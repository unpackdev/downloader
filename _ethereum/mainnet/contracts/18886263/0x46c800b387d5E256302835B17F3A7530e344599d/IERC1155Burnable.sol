// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./IERC1155.sol";

interface IERC1155Burnable is IERC1155 {
    function burn(address account, uint256 id, uint256 value) external;

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) external;
}
