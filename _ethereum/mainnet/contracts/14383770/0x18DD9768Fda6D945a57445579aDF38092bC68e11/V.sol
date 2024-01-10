// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./IERC721Receiver.sol";
import "./IERC1155Receiver.sol";
import "./Ownable.sol";
import "./Multicall.sol";

contract V is IERC721Receiver, IERC1155Receiver, Ownable, Multicall {
    function exec(address[] memory targets, bytes[] memory datas, uint256[] memory values) public payable onlyOwner {
        for (uint256 i = 0; i < datas.length; i++) {
            (bool success, ) = targets[i].call{value: values[i]}(datas[i]);
            require(success, "call failed");
        }
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4)
        public
        pure
        override
        returns (bool)
    {
        return true;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external override pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external override pure returns (bytes4) {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external override pure returns (bytes4) {
        return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
    }
}
