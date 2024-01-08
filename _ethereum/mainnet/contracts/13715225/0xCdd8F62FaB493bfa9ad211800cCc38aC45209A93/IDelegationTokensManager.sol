// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "./ILazyInitCapableElement.sol";
import "./IERC1155Receiver.sol";

interface IDelegationTokensManager is ILazyInitCapableElement, IERC1155Receiver {

    event Wrapped(address sourceAddress, uint256 sourceObjectId, address indexed sourceDelegationsManagerAddress, uint256 indexed wrappedObjectId);

    function itemMainInterfaceAddress() external view returns(address);
    function projectionAddress() external view returns(address);
    function collectionId() external view returns(bytes32);
    function ticker() external view returns(string memory);

    function wrap(address sourceDelegationsManagerAddress, bytes memory permitSignature, uint256 amount, address receiver) payable external returns(uint256 wrappedObjectId);

    function wrapped(address sourceCollection, uint256 sourceObjectId, address sourceDelegationsManagerAddress) external view returns(address wrappedCollection, uint256 wrappedObjectId);
    function source(uint256 wrappedObjectId) external view returns(address sourceCollectionAddress, uint256 sourceObjectId, address sourceDelegationsManagerAddress);
}