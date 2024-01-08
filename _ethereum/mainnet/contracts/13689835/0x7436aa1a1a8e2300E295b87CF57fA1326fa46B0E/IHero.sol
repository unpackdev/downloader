// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "IERC721.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IHero is IERC721 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function multiMint() external;
    function setPartner(address _partner, uint256 _limit) external;
    function transferOwnership(address newOwner) external; 
    function partnersLimit(address _partner) external view returns(uint256, uint256);
    function totalSupply() external view returns(uint256);
    function reservedForPartners() external view returns(uint256);
}
