// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IERC1155TokenReceiver.sol";
import "./Context.sol";

contract ERC1155TokenReceiver is IERC1155TokenReceiver, Context {
    event ReceivedERC1155Tokens(address operator, address from, uint256 id, uint256 amount, address ERC1155Address, bytes extraData);
    event ReceivedERC1155TokensBatch(address operator, address from, uint256[] ids, uint256[] amounts, address ERC1155Address, bytes extraData);

    function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _amount, bytes calldata _data) public override returns(bytes4) {
        emit ReceivedERC1155Tokens(_operator, _from, _id, _amount, _msgSender(), _data);
        return 0xf23a6e61;
    }

    function onERC1155BatchReceived(address _operator, address _from, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data) public override returns(bytes4) {
        emit ReceivedERC1155TokensBatch(_operator, _from, _ids, _amounts, _msgSender(), _data);
        return 0xbc197c81;
    }
}
