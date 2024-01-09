// contracts/F3K721.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface F3K1155 {
    function mint(address to, uint256 amountToMint) external;

    function nextTokenId() external view returns (uint256);
    
    function balanceOf(address account, uint256 id) external view returns (uint256);

    function burnToken(address account, uint256 id, uint256 value) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;
}