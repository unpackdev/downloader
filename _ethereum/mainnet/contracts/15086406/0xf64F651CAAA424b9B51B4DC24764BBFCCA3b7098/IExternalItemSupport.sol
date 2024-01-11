// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./IERC1155.sol";

interface IExternalItemSupport is IERC1155 {
    function burnItemForOwnerAddress(
        uint256 _typeId,
        uint256 _quantity,
        address _materialOwnerAddress
    ) external;

    function mintItemToAddress(
        uint256 _typeId,
        uint256 _quantity,
        address _toAddress
    ) external;

    function bulkSafeTransfer(
        uint256 _typeId,
        uint256 _quantityPerRecipient,
        address[] calldata recipients
    ) external;
}
