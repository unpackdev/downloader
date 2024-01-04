// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "./IERC721.sol";
import "./IERC1155.sol";

import "./ITransferProxy.sol";
import "./OwnerOperatorControl.sol";

contract TransferProxy is ITransferProxy, OwnerOperatorControl {
    function initialize() public initializer {
        __OwnerOperatorControl_init();
    }

    function erc721SafeTransferFrom(
        address token,
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external override onlyOperator {
        IERC721(token).safeTransferFrom(from, to, tokenId, data);
    }

    function erc1155SafeTransferFrom(
        address token,
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes calldata data
    ) external override onlyOperator {
        IERC1155(token).safeTransferFrom(from, to, tokenId, amount, data);
    }
}
