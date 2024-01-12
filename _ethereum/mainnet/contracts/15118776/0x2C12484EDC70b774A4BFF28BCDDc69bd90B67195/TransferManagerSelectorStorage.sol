// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TransferManagerSelectorStorage {
    bytes4 internal _interfaceIdErc721;
    bytes4 internal _interfaceIdErc1155;
    mapping(address => address) public transferManagerByCollection;
    address public transferManagerErc721;
    address public transferManagerErc1155;
}
