// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface IERC721 {
    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function burn(uint256 _tokenId) external;
}
