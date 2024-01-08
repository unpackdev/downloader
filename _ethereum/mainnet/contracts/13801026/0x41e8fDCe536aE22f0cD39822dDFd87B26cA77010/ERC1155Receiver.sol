// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC1155Receiver.sol";
import "./ERC165.sol";

/**
 * @title ERC1155 Receiver contract
 * @dev Contract implementing the IERC1155Receiver interface
 * 
 * This contract is meant to be used as a base contract for 
 * other contracts, to enable them to receive ERC1155 transfers.
 * Attempting transfer of ERC1155 tokens to contracts that don't
 * implement this interface will lead to transaction revertion.
 */
contract ERC1155Receiver is IERC1155Receiver, ERC165  {
    
    event ERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes data
    );

    event ERC1155BatchReceived(
        address operator,
        address from,
        uint256[] ids,
        uint256[] values,
        bytes data
    );

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external override returns (bytes4){
        emit ERC1155Received(operator, from, id, value, data);
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external override returns (bytes4){
        emit ERC1155BatchReceived(operator, from, ids, values, data);
        return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
    }


}
