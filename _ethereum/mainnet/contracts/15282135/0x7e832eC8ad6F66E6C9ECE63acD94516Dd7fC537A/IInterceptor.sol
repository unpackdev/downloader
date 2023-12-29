// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./IERC1155.sol";
import "./IERC721.sol";
import "./OrderTypes.sol";

interface IInterceptor {
    function beforeCollectionTransfer(
        address token,
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory extra
    ) external returns (bool);
}
