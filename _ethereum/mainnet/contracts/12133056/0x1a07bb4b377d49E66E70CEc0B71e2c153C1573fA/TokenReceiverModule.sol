// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721Receiver.sol";
import "./IERC777Recipient.sol";
import "./IERC1155Receiver.sol";
import "./ERC165.sol";
import "./ModuleBase.sol";

contract TokenReceiverModule is IModule, ModuleBase, ERC165, IERC721Receiver, IERC777Recipient, IERC1155Receiver
{
    string public constant override name = type(TokenReceiverModule).name;

    constructor(address walletTemplate) ModuleBase(walletTemplate) {}

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC721Receiver).interfaceId
            || interfaceId == type(IERC777Recipient).interfaceId
            || interfaceId == type(IERC1155Receiver).interfaceId
            || super.supportsInterface(interfaceId);
    }

    function onERC721Received(address, address, uint256, bytes calldata)
    external override pure returns (bytes4)
    {
        return this.onERC721Received.selector;
    }

    function tokensReceived(address, address, address, uint256, bytes calldata, bytes calldata)
    external override pure
    {
    }

    function onERC1155Received(address, address, uint256, uint256, bytes calldata)
    external override pure returns(bytes4)
    {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata)
    external override pure returns(bytes4)
    {
        return this.onERC1155BatchReceived.selector;
    }
}
