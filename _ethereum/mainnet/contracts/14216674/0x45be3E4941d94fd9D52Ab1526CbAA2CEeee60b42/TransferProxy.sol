// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;

import "./IERC721.sol";
import "./IERC1155.sol";

import "./OperatorRole.sol";

contract TransferProxy is OperatorRole {
    function erc721safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 tokenId
    ) external onlyOperator {
        IERC721(token).safeTransferFrom(from, to, tokenId);
    }

    function erc1155safeTransferFrom(
        address token,
        address _from,
        address _to,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) external onlyOperator {
        IERC1155(token).safeTransferFrom(_from, _to, _id, _value, _data);
    }
}
