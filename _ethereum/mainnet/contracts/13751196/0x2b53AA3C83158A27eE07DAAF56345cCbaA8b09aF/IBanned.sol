// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721Enumerable.sol";
interface IBanned is IERC721Enumerable {
    function mint(uint8 windowIndex, uint8 amount, bytes32[] calldata merkleProof) payable external;
    function unpause() external;
    function pause() external;
    function setBaseURI(string memory _baseTokenURI) external;
    function editRedemptionWindow(uint8 _windowID, bytes32 _merkleRoot, bool _open, uint8 _maxPerWallet,uint256 _pricePerToken) external;
}