// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155TokenReceiver.sol)

pragma solidity 0.8.9;

interface IERC1155TokenReceiver {
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external returns (bytes4);

    function onERC1155Received(address, address, uint256, uint256, bytes calldata)
        external
        returns (bytes4);
}
