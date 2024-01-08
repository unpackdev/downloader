// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./IERC721.sol";
import "./IERC1155Receiver.sol";

interface IERC998ERC1155TopDown is IERC721, IERC1155Receiver {
    event ReceivedChild1155(address indexed from, uint256 indexed toTokenId, address indexed childContract, uint256 childTokenId, uint256 amount);
    event TransferSingleChild1155(uint256 indexed fromTokenId, address indexed to, address indexed childContract, uint256 childTokenId, uint256 amount);
    event TransferBatchChild1155(uint256 indexed fromTokenId, address indexed to, address indexed childContract, uint256[] childTokenIds, uint256[] amounts);

    function child1155ContractsFor(uint256 tokenId) external view returns (address[] memory childContracts);
    function child1155IdsForOn(uint256 tokenId, address childContract) external view returns (uint256[] memory childIds);
    function child1155Balance(uint256 tokenId, address childContract, uint256 childTokenId) external view returns(uint256);

    function safeTransferChild1155From(uint256 fromTokenId, address to, address childContract, uint256 childTokenId, uint256 amount, bytes calldata data) external;
    function safeBatchTransferChild1155From(uint256 fromTokenId, address to, address childContract, uint256[] calldata childTokenIds, uint256[] calldata amounts, bytes calldata data) external;
}
