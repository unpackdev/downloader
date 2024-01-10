//"SPDX-License-Identifier: UNLICENSED"
pragma solidity 0.6.6;

import "./ERC721.sol";
import "./ERC721Holder.sol";
import "./ReentrancyGuard.sol";

import "./AccessControlMixin.sol";

import "./ERC20.sol";
import "./IERC721Receiver.sol";

interface IGoldFeverItemType {
    function getItemType(uint256 itemId) external view returns (uint256 typeId);
}

contract GoldFeverItemTypeV1 is IGoldFeverItemType {
    function getItemType(uint256 itemId)
        external
        view
        override
        returns (uint256 typeId)
    {
        if (itemId & ((1 << 4) - 1) == 1) {
            // Version 1
            typeId = (itemId >> 4) & ((1 << 20) - 1);
        }
    }
}
