// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IPASSTOKENS is IERC165 {
    function mint(
        uint256 _membershipId,
        string memory _metadata,
        uint256 _supply,
        uint256 _price,
        uint256 _deadline
    ) external payable returns (uint256 tokenId);

    function buy(string memory _metadata, address _receiver) external payable;
}
