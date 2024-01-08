// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./IERC721.sol";
import "./IERC721Receiver.sol";

interface IERC998ERC721TopDown is IERC721, IERC721Receiver {
    event ReceivedChild721(address indexed from, uint256 indexed toTokenId, address indexed childContract, uint256 childTokenId);
    event TransferChild721(uint256 indexed fromTokenId, address indexed to, address indexed childContract, uint256 childTokenId);

    function child721ContractsFor(uint256 tokenId) external view returns (address[] memory childContracts);
    function child721IdsForOn(uint256 tokenId, address childContract) external view returns (uint256[] memory childIds);
    function child721Balance(uint256 tokenId, address childContract, uint256 childTokenId) external view returns(uint256);

    function safeTransferChild721From(uint256 fromTokenId, address to, address childContract, uint256 childTokenId, bytes calldata data) external;
}
