// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./CartaeMock.sol";

abstract contract ERC1155TokenReceiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155BatchReceived.selector;
    }
}

contract CartaeSnagger is ERC1155TokenReceiver {
    CartaeMock private cartaeMock;
    address private toTransfer;

    constructor(address _cartaeMock, address _toTransfer) {
        cartaeMock = CartaeMock(_cartaeMock);
        toTransfer = _toTransfer;
    }

    function mintCartae() public payable {
        cartaeMock.mint{value: msg.value}();
        if (
            cartaeMock.balanceOf(address(this), 30) != 2 ||
            cartaeMock.balanceOf(address(this), 24) < 1
        ) {
            revert();
        }
    }

    function withdrawCartae(
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) public {
        cartaeMock.safeBatchTransferFrom(
            address(this),
            toTransfer,
            ids,
            amounts,
            ""
        );
    }
}
